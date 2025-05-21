#include <PreciseNumber.h>
#include <cmath>

PreciseNumber::PreciseNumber(double amount)
    : smallestUnit(static_cast<long long>(std::round(amount * kPrecision))) {}

PreciseNumber PreciseNumber::operator+(const PreciseNumber &other) const {
  PreciseNumber result{0};
  result.smallestUnit = this->smallestUnit + other.smallestUnit;
  return result;
}

PreciseNumber PreciseNumber::operator-(const PreciseNumber &other) const {
  PreciseNumber result{0};
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
  PreciseNumber result{0};
  result.smallestUnit = static_cast<long long>(
      std::round((this->smallestUnit * other.smallestUnit) / kPrecision));
  return result;
}

PreciseNumber &PreciseNumber::operator*=(const PreciseNumber &other) {
  this->smallestUnit = static_cast<long long>(
      std::round((this->smallestUnit * other.smallestUnit) / kPrecision));
  return *this;
}

PreciseNumber PreciseNumber::operator/(const PreciseNumber &other) const {
  if (other.smallestUnit == 0) {
    return PreciseNumber{0}; // Handle division by zero
  }
  // To preserve precision, scale up before division
  double quotient =
      static_cast<double>(this->smallestUnit) / other.smallestUnit;
  return PreciseNumber(quotient);
}

PreciseNumber &PreciseNumber::operator/=(const PreciseNumber &other) {
  if (other.smallestUnit == 0) {
    return *this; // Handle division by zero
  }
  double quotient =
      static_cast<double>(this->smallestUnit) / other.smallestUnit;
  this->smallestUnit =
      static_cast<long long>(std::round(quotient * kPrecision));
  return *this;
}

PreciseNumber PreciseNumber::fmod(const PreciseNumber &a,
                                  const PreciseNumber &b) {
  if (b.smallestUnit == 0) {
    return PreciseNumber{0}; // Handle division by zero
  }
  PreciseNumber result;
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

double PreciseNumber::toDouble() const { return smallestUnit / kPrecision; }

PreciseNumber PreciseNumber::min(const PreciseNumber &a,
                                 const PreciseNumber &b) {
  return (a.smallestUnit < b.smallestUnit) ? a : b;
}

PreciseNumber PreciseNumber::pow(const PreciseNumber &base,
                                 const PreciseNumber &exponent) {
  double result = std::pow(base.toDouble(), exponent.toDouble());
  return PreciseNumber(result);
}

// Friend function for output stream
std::ostream &operator<<(std::ostream &os, const PreciseNumber &c) {
  os << c.toDouble();
  return os;
}