#include "ExecutionReport.h"

#include <utility>

ExecutionReport::ExecutionReport(
    std::string id, TradeExecutionStatus status, const PreciseNumber& usedQty,
    const PreciseNumber& recvQty,
    const std::unordered_map<std::string, PreciseNumber> &feeDelta)
    : _id(std::move(id)), _status(status), _usedQty(usedQty), _recvQty(recvQty),
      _feeDelta(feeDelta) {};

auto ExecutionReport::getId() const -> std::string { return _id; }

auto ExecutionReport::getStatus() const -> TradeExecutionStatus { return _status; }

std::unordered_map<std::string, PreciseNumber>
ExecutionReport::getFeeDelta() const {
  return _feeDelta;
}

auto ExecutionReport::usedQty() -> PreciseNumber { return _usedQty; }

auto ExecutionReport::recvQty() -> PreciseNumber { return _recvQty; }

auto operator<<(std::ostream &os, const ExecutionReport &report) -> std::ostream & {
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