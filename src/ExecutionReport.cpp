#include "ExecutionReport.h"

ExecutionReport::ExecutionReport(
    const std::string &id, TradeExecutionStatus status,
    boost::multiprecision::cpp_dec_float_50 usedQty,
    boost::multiprecision::cpp_dec_float_50 recvQty,
    const std::unordered_map<std::string,
                             boost::multiprecision::cpp_dec_float_50> &feeDelta)
    : _id(id), _status(status), _usedQty(usedQty), _recvQty(recvQty),
      _feeDelta(feeDelta) {};

std::string ExecutionReport::getId() const { return _id; }

TradeExecutionStatus ExecutionReport::getStatus() const { return _status; }

std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
ExecutionReport::getFeeDelta() const {
  return _feeDelta;
}

boost::multiprecision::cpp_dec_float_50 ExecutionReport::getUsedQty() {
  return _usedQty;
}

boost::multiprecision::cpp_dec_float_50 ExecutionReport::getRecvQty() {
  return _recvQty;
}

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

  os << ", usedQty=" << report._usedQty << ", recvQty=" << report._recvQty;

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