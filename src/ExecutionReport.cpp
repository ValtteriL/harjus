#include "ExecutionReport.h"

ExecutionReport::ExecutionReport(
    const std::string &id, TradeExecutionStatus status,
    const std::unordered_map<std::string,
                             boost::multiprecision::cpp_dec_float_50> &feeDelta)
    : _id(id), _status(status), _feeDelta(feeDelta) {};

std::string ExecutionReport::getId() const { return _id; }

TradeExecutionStatus ExecutionReport::getStatus() const { return _status; }

std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
ExecutionReport::getFeeDelta() const {
  return _feeDelta;
}

/**
 * @brief Stream operator overload for ExecutionReport
 * @param os Output stream
 * @param report ExecutionReport object to print
 * @return Reference to the output stream
 */
std::ostream &operator<<(std::ostream &os, const ExecutionReport &report) {
  os << "ExecutionReport{"
     << "id='" << report.getId() << "', "
     << "status=";

  // Convert status enum to readable string
  switch (report.getStatus()) {
  case TradeExecutionStatus::FILLED:
    os << "FILLED";
    break;
  case TradeExecutionStatus::EXPIRED:
    os << "EXPIRED";
    break;
  default:
    os << "UNKNOWN";
    break;
  }

  os << ", fees=[";

  // Add all fee deltas
  bool first = true;
  for (const auto &[asset, amount] : report.getFeeDelta()) {
    if (!first) {
      os << ", ";
    }
    os << "'" << asset << "':" << amount;
    first = false;
  }

  os << "]}";
  return os;
}