#pragma once

#include <string>
class ExecutionReport {
private:
  std::string _id;

public:
  ExecutionReport(const std::string &id);
  virtual ~ExecutionReport() = default;
};