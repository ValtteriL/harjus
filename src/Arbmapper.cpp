#include "Arbmapper.h"
#include "Trade.h"
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/tiernan_all_cycles.hpp>

struct VertexProperties {
  std::string asset;
};

struct EdgeProperties {
  Trade trade; // Trade object representing the edge
};

// Define the graph structure
using Graph = boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS,
                                    VertexProperties, EdgeProperties>;

namespace boost {
void renumber_vertex_indices(Graph const &) {}
} // namespace boost

// Function to build the graph
void buildGraph(Graph &graph,
                const std::unordered_map<std::string, Symbol> &symbolMap) {

  // Create a map to store vertexes by asset
  std::unordered_map<std::string, std::size_t> vertexMap{};

  // get unique asset names
  std::unordered_set<std::string> uniqueAssets{};
  for (const auto &pair : symbolMap) {
    const auto &symbol = pair.second;
    uniqueAssets.insert(symbol.baseAsset);
    uniqueAssets.insert(symbol.quoteAsset);
  }

  // Add vertices to the graph
  for (const auto &asset : uniqueAssets) {
    auto vertex = boost::add_vertex(VertexProperties{asset}, graph);

    // insert the vertex into the map
    vertexMap[asset] = vertex;
  }

  // Add edges to the graph
  for (auto &pair : symbolMap) {
    auto &symbol = pair.second;

    auto base = vertexMap[symbol.baseAsset];
    auto quote = vertexMap[symbol.quoteAsset];

    // long
    boost::add_edge(quote, base, EdgeProperties{Trade{&symbol, Position::LONG}},
                    graph);

    // short
    boost::add_edge(base, quote,
                    EdgeProperties{Trade{&symbol, Position::SHORT}}, graph);
  }
}

template <typename ForwardIt>
auto rotate_copy_with_copy_constructor(ForwardIt first, ForwardIt middle,
                                       ForwardIt last)
    -> std::vector<typename std::iterator_traits<ForwardIt>::value_type> {
  using ValueType = typename std::iterator_traits<ForwardIt>::value_type;
  std::vector<ValueType> result{};

  // Copy the second part (from middle to last)
  for (auto it = middle; it != last; ++it) {
    result.push_back(Trade{it->symbol(), it->position()});
  }

  // Copy the first part (from first to middle)
  for (auto it = first; it != middle; ++it) {
    result.push_back(Trade{it->symbol(), it->position()});
  }

  return result;
}

struct CycleVisitor {
  // This struct is used to visit each cycle found by tiernan_all_cycles

  std::vector<std::vector<Trade>> *cycles;

  CycleVisitor(std::vector<std::vector<Trade>> &cycles) : cycles(&cycles) {}

  // This function is called for each cycle found
  void cycle(auto const &path, Graph const &g) {
    std::vector<Trade> tradePath{};

    // get th edges (trades) in the tradePath
    for (size_t i = 0; i < path.size(); ++i) {
      auto u = path[i];
      auto v = path[(i + 1) % path.size()];

      auto edge = boost::edge(u, v, g);
      if (edge.second) {
        tradePath.push_back(g[edge.first].trade);
      }
    }

    // construct cycles with different starting trades from the cycle
    // Add them to the cycles vector
    for (size_t i = 0; i < tradePath.size(); ++i) {
      auto copy = rotate_copy_with_copy_constructor(
          tradePath.begin(), tradePath.begin() + i, tradePath.end());
      cycles->emplace_back(copy);
    }
  }
};

/**
 * Given a directed graph, finds all cycles of length gte 3 and lte maxDepth.
 * The cycles are returned as a vector of vectors, where each inner vector
 * represents a cycle. The cycles are represented as a vector of Trade objects.
 * Each Trade is a copy of the original Trade object in the graph, so the
 * original graph is not modified.
 */
auto findCycles(const Graph &graph,
                const int maxDepth) -> std::vector<std::vector<Trade>> {
  // Create a visitor to process the cycles
  // the cycles need to be stored here, as the visitor is destroyed after the
  // function returns and visitor must be passed by value
  std::vector<std::vector<Trade>> cycles{};
  CycleVisitor visitor{cycles};

  boost::tiernan_all_cycles(graph, visitor, 3, maxDepth);

  return cycles;
}

auto getTradingPaths(const std::unordered_map<std::string, Symbol> &symbolMap,
                     const IConfiguration &configuration)
    -> std::vector<std::vector<Trade>> {
  // Create a graph
  Graph graph = 0;

  // Build the graph with the given symbols
  buildGraph(graph, symbolMap);

  // find & return cycles in the graph
  int maxDepth = configuration.getMaxTradingPathLength();
  auto cycles = findCycles(graph, maxDepth);

  // reject cycles with symbols that are not in the assets list
  auto assets = configuration.getAssets();
  std::erase_if(cycles, [&assets](const auto &cycle) {
    for (const auto &trade : cycle) {
      if (std::find(assets.begin(), assets.end(), trade.usedCurrency()) ==
              assets.end() ||
          std::find(assets.begin(), assets.end(), trade.recvCurrency()) ==
              assets.end()) {
        return true;
      }
    }
    return false;
  });

  return cycles;
}