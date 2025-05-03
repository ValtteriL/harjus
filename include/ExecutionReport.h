#pragma once

#include "TradeExecutionStatus.h"
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <string>
#include <unordered_map>

/**
 * @brief Class for execution reports from the exchange
 */
class ExecutionReport {
private:
  std::string _id;
  TradeExecutionStatus _status;
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
      _assetDelta;

public:
  /**
   * @brief Constructor for ExecutionReport class
   * @param id The ID of the execution report
   * @param status The status of the execution report
   * @param assetDelta The asset delta of the execution report
   */
  ExecutionReport(
      const std::string &id, TradeExecutionStatus status,
      const std::unordered_map<
          std::string, boost::multiprecision::cpp_dec_float_50> &assetDelta);

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
   * @brief Get the asset delta of the execution report
   * @return The asset delta of the execution report
   */
  std::unordered_map<std::string, boost::multiprecision::cpp_dec_float_50>
  getAssetDelta() const;
};