#pragma once

#include "PreciseNumber.h"
#include "TradeExecutionStatus.h"
#include <string>
#include <unordered_map>

/**
 * @brief Class for execution reports from the exchange
 */
class ExecutionReport {
private:
  std::string _id;
  TradeExecutionStatus _status;
  PreciseNumber _usedQty;
  PreciseNumber _recvQty;
  std::unordered_map<std::string, PreciseNumber> _feeDelta;

public:
  /**
   * @brief Constructor for ExecutionReport class
   * @param id The ID of the execution report
   * @param status The status of the execution report
   * @param feeDelta The fee delta of the execution report
   */
  ExecutionReport(
      std::string id, TradeExecutionStatus status, const PreciseNumber &usedQty,
      const PreciseNumber &recvQty,
      const std::unordered_map<std::string, PreciseNumber> &feeDelta);

  /**
   * @brief Default constructor for ExecutionReport class
   */
  ExecutionReport() = default;

  /**
   * @brief Destructor for ExecutionReport class
   */
  virtual ~ExecutionReport() = default;

  /**
   * @brief Get the ID of the execution report
   * @return The ID of the execution report
   */
  std::string getId() const;

  /**
   * @brief Get the status of the execution report
   * @return The status of the execution report
   */
  TradeExecutionStatus getStatus() const;

  /**
   * @brief Get the fee delta of the execution report
   * @return The fee delta of the execution report caused by exchange fees.
   * This does not include the changes to base and quote assets. Those need to
   * be fetched from the Execution object.
   */
  std::unordered_map<std::string, PreciseNumber> getFeeDelta() const;

  /**
   * @brief Get the used quantity of the execution report
   * @return The used quantity of the execution report
   */
  PreciseNumber usedQty();

  /**
   * @brief Get the received quantity of the execution report
   * @return The received quantity of the execution report
   */
  PreciseNumber recvQty();

  /**
   * @brief Stream operator overload for ExecutionReport
   * @param os Output stream
   * @param report ExecutionReport object to print
   * @return Reference to the output stream
   */
  friend std::ostream &operator<<(std::ostream &os,
                                  const ExecutionReport &report);
};