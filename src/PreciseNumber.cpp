#include <PreciseNumber.h>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <string>

PreciseNumber::PreciseNumber(const std::string &amount)
    : smallestUnit(checked_int128_t{
          boost::multiprecision::cpp_dec_float_50{amount} * kPrecision}) {}

PreciseNumber PreciseNumber::operator+(const PreciseNumber &other) const {
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit + other.smallestUnit;
  return result;
}

PreciseNumber PreciseNumber::operator-(const PreciseNumber &other) const {
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit - other.smallestUnit;
  return result;
}

PreciseNumber &PreciseNumber::operator-=(const PreciseNumber &other) {
  this->smallestUnit -= other.smallestUnit;
  return *this;
}

PreciseNumber &PreciseNumber::operator+=(const PreciseNumber &other) {
  this->smallestUnit += other.smallestUnit;
  return *this;
}

PreciseNumber PreciseNumber::operator*(const PreciseNumber &other) const {
  // Multiply smallest units and scale back to original unit
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return result;
}

PreciseNumber &PreciseNumber::operator*=(const PreciseNumber &other) {
  this->smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return *this;
}

PreciseNumber PreciseNumber::operator/(const PreciseNumber &other) const {
  PreciseNumber result{};
  if (other.smallestUnit == 0) {
    return result; // Handle division by zero
  }
  // To preserve precision, scale up before division
  result.smallestUnit = this->smallestUnit * kPrecision / other.smallestUnit;
  return result;
}

PreciseNumber &PreciseNumber::operator/=(const PreciseNumber &other) {
  if (other.smallestUnit == 0) {
    return *this; // Handle division by zero
  }

  // To preserve precision, scale up before division
  this->smallestUnit = this->smallestUnit * kPrecision / other.smallestUnit;
  return *this;
}

PreciseNumber PreciseNumber::fmod(const PreciseNumber &a,
                                  const PreciseNumber &b) {
  PreciseNumber result{};
  if (b.smallestUnit == 0) {
    return result; // Handle division by zero
  }
  result.smallestUnit = a.smallestUnit % b.smallestUnit;
  return result;
}

bool PreciseNumber::operator==(const PreciseNumber &other) const {
  return this->smallestUnit == other.smallestUnit;
}
bool PreciseNumber::operator<(const PreciseNumber &other) const {
  return this->smallestUnit < other.smallestUnit;
}

bool PreciseNumber::operator>(const PreciseNumber &other) const {
  return this->smallestUnit > other.smallestUnit;
}

bool PreciseNumber::operator>=(const PreciseNumber &other) const {
  return this->smallestUnit >= other.smallestUnit;
}

PreciseNumber PreciseNumber::min(const PreciseNumber &a,
                                 const PreciseNumber &b) {
  return (a.smallestUnit < b.smallestUnit) ? a : b;
}

std::string PreciseNumber::toString() const {
  // Convert smallestUnit to string with appropriate precision
  boost::multiprecision::cpp_dec_float_50 value{smallestUnit.str()};

  // Scale down by kPrecision to get the original value
  value /= kPrecision;

  // Always output in fixed-point decimal notation (no exponent)
  std::ostringstream oss;
  oss << std::fixed << std::setprecision(10) << value;
  std::string str = oss.str();
  // Strip trailing zeros and possibly the decimal point
  str.erase(str.find_last_not_of('0') + 1, std::string::npos);
  if (!str.empty() && str.back() == '.') {
    str.pop_back();
  }

  return str;
}

// Friend function for output stream
std::ostream &operator<<(std::ostream &os, const PreciseNumber &c) {
  os << c.toString();
  return os;
}