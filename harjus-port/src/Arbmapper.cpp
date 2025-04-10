#include "Arbmapper.h"
#include "Trade.h"
#include <boost/graph/adjacency_list.hpp>

struct VertexProperties
{
  std::string asset;
};
struct EdgeProperties
{
  Trade trade;
};

// Define the graph structure
typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::directedS, VertexProperties, EdgeProperties> Graph;

// Function to build the graph
void buildGraph(Graph &graph, const std::unordered_map<std::string, Symbol> *symbolMap)
{

  // Create a map to store vertexes by asset
  std::unordered_map<std::string, std::size_t> vertexMap;

  // get unique asset names
  std::unordered_set<std::string> uniqueAssets;
  for (const auto &pair : *symbolMap)
  {
    const auto &symbol = pair.second;
    uniqueAssets.insert(symbol.baseAsset);
    uniqueAssets.insert(symbol.quoteAsset);
  }

  // Add vertices to the graph
  for (const auto &asset : uniqueAssets)
  {
    auto vertex = boost::add_vertex(VertexProperties{asset}, graph);

    // insert the vertex into the map
    vertexMap[asset] = vertex;
  }

  // Add edges to the graph
  for (const auto &pair : *symbolMap)
  {
    const auto &symbol = pair.second;

    auto vertex1 = vertexMap[symbol.baseAsset];
    auto vertex2 = vertexMap[symbol.quoteAsset];

    // long
    Trade longTrade{symbol, Position::LONG};
    boost::add_edge(vertex1, vertex2, EdgeProperties{longTrade}, graph);

    // short
    Trade shortTrade{symbol, Position::SHORT};
    boost::add_edge(vertex2, vertex1, EdgeProperties{shortTrade}, graph);
  }
}

/**
 * Given a directed graph, finds all cycles of length gte 2 and lte maxDepth.
 * The cycles are returned as a vector of vectors, where each inner vector represents a cycle.
 * The cycles are represented as a vector of Trade objects.
 * Each Trade is a copy of the original Trade object in the graph, so the original graph is not modified.
 */
std::vector<std::vector<Trade>> findCycles(const Graph &graph, const int maxDepth)
{
  // TODO: implement
}

std::vector<std::vector<Trade>> getTradingPaths(std::unordered_map<std::string, Symbol> *symbolMap, int maxDepth, std::vector<std::string> &skipSymbols)
{
  // Create a graph
  Graph graph;

  // Build the graph with the given symbols
  buildGraph(graph, symbolMap);

  // find & return cycles in the graph
  auto cycles = findCycles(graph, maxDepth);

  // reject cycles where the first usedCurrency is in skipSymbols
  std::erase_if(cycles, [&skipSymbols](const auto &cycle)
                {
    auto firstTrade = cycle.front();
    return std::find(skipSymbols.begin(), skipSymbols.end(), firstTrade.getUsedCurrency()) != skipSymbols.end(); });

  return cycles;
}