#include <PreciseNumber.h>
#include <boost/multiprecision/cpp_dec_float.hpp>
#include <iomanip>
#include <sstream>
#include <string>

PreciseNumber::PreciseNumber(const std::string &amount)
    : smallestUnit(bm::mpz_int{bm::cpp_dec_float_50{amount} * kPrecision}) {}

PreciseNumber::PreciseNumber(const PreciseNumber &other)
    : smallestUnit(other.smallestUnit) {}

auto PreciseNumber::operator=(const PreciseNumber &other) -> PreciseNumber & {
  if (this != &other) {
    this->smallestUnit = other.smallestUnit;
  }
  return *this;
}

auto PreciseNumber::operator+(const PreciseNumber &other) const
    -> PreciseNumber {
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit + other.smallestUnit;
  return result;
}

auto PreciseNumber::operator-(const PreciseNumber &other) const
    -> PreciseNumber {
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit - other.smallestUnit;
  return result;
}

auto PreciseNumber::operator-=(const PreciseNumber &other) -> PreciseNumber & {
  this->smallestUnit -= other.smallestUnit;
  return *this;
}

auto PreciseNumber::operator+=(const PreciseNumber &other) -> PreciseNumber & {
  this->smallestUnit += other.smallestUnit;
  return *this;
}

auto PreciseNumber::operator*(const PreciseNumber &other) const
    -> PreciseNumber {
  // Multiply smallest units and scale back to original unit
  PreciseNumber result{};
  result.smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return result;
}

auto PreciseNumber::operator*=(const PreciseNumber &other) -> PreciseNumber & {
  this->smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return *this;
}

auto PreciseNumber::operator/(const PreciseNumber &other) const
    -> PreciseNumber {
  PreciseNumber result{};
  if (other.smallestUnit == 0) {
    return result; // Handle division by zero
  }
  // To preserve precision, scale up before division
  result.smallestUnit = this->smallestUnit * kPrecision / other.smallestUnit;
  return result;
}

auto PreciseNumber::operator/=(const PreciseNumber &other) -> PreciseNumber & {
  if (other.smallestUnit == 0) {
    return *this; // Handle division by zero
  }

  // To preserve precision, scale up before division
  this->smallestUnit = this->smallestUnit * kPrecision / other.smallestUnit;
  return *this;
}

auto PreciseNumber::fmod(const PreciseNumber &a,
                         const PreciseNumber &b) -> PreciseNumber {
  PreciseNumber result{};
  if (b.smallestUnit == 0) {
    return result; // Handle division by zero
  }
  result.smallestUnit = a.smallestUnit % b.smallestUnit;
  return result;
}

auto PreciseNumber::operator==(const PreciseNumber &other) const -> bool {
  return this->smallestUnit == other.smallestUnit;
}
auto PreciseNumber::operator<(const PreciseNumber &other) const -> bool {
  return this->smallestUnit < other.smallestUnit;
}

auto PreciseNumber::operator>(const PreciseNumber &other) const -> bool {
  return this->smallestUnit > other.smallestUnit;
}

auto PreciseNumber::operator>=(const PreciseNumber &other) const -> bool {
  return this->smallestUnit >= other.smallestUnit;
}

auto PreciseNumber::min(const PreciseNumber &a,
                        const PreciseNumber &b) -> PreciseNumber {
  return (a.smallestUnit < b.smallestUnit) ? a : b;
}

auto PreciseNumber::toString() const -> std::string {
  // Convert smallestUnit to string with appropriate precision
  bm::cpp_dec_float_50 value{smallestUnit.str()};

  // Scale down by kPrecision to get the original value
  value /= kPrecision;

  // Always output in fixed-point decimal notation (no exponent)
  constexpr int kToStringPrecision = 10;
  std::ostringstream oss{};
  oss << std::fixed << std::setprecision(kToStringPrecision) << value;
  std::string str = oss.str();
  // Strip trailing zeros and possibly the decimal point
  str.erase(str.find_last_not_of('0') + 1, std::string::npos);
  if (!str.empty() && str.back() == '.') {
    str.pop_back();
  }

  return str;
}

// Friend function for output stream
auto operator<<(std::ostream &os, const PreciseNumber &c) -> std::ostream & {
  os << c.toString();
  return os;
}