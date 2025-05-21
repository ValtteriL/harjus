#include "ExecutionReport.h"

ExecutionReport::ExecutionReport(
    const std::string &id, TradeExecutionStatus status, PreciseNumber usedQty,
    PreciseNumber recvQty,
    const std::unordered_map<std::string, PreciseNumber> &feeDelta)
    : _id(id), _status(status), _usedQty(usedQty), _recvQty(recvQty),
      _feeDelta(feeDelta) {};

std::string ExecutionReport::getId() const { return _id; }

TradeExecutionStatus ExecutionReport::getStatus() const { return _status; }

std::unordered_map<std::string, PreciseNumber>
ExecutionReport::getFeeDelta() const {
  return _feeDelta;
}

PreciseNumber ExecutionReport::usedQty() { return _usedQty; }

PreciseNumber ExecutionReport::recvQty() { return _recvQty; }

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