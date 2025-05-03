#include "ExecutionReport.h"

ExecutionReport::ExecutionReport(
    const std::string &id, TradeExecutionStatus status,
    const std::unordered_map<
        std::string, boost::multiprecision::cpp_dec_float_50> &assetDelta)
    : _id(id), _status(status), _assetDelta(assetDelta) {};

std::string ExecutionReport::getId() const { return _id; }

TradeExecutionStatus ExecutionReport::getStatus() const { return _status; }

std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
ExecutionReport::getAssetDelta() const {
  return _assetDelta;
}