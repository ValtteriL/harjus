#include "Arbmapper.h"
#include <boost/graph/adjacency_list.hpp>

struct VertexProperties
{
  std::string asset;
};
struct EdgeProperties
{
  ITrade trade;
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
    // TODO: construct the trade object
    boost::add_edge(vertex1, vertex2, EdgeProperties{}, graph);

    // short
    // TODO: construct the trade object
    boost::add_edge(vertex2, vertex1, EdgeProperties{}, graph);
  }
}

std::vector<std::vector<ITrade>> getTradingPaths(std::unordered_map<std::string, Symbol> *symbolMap, int maxDepth, std::vector<std::string> &skipSymbols)
{
  // Create a graph
  Graph graph;

  // Build the graph with the given symbols
  buildGraph(graph, symbolMap);

  // TODO: find & return cycles in the graph
}