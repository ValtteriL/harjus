#include <PreciseNumber.h>
#include <cmath>

PreciseNumber::PreciseNumber(double amount)
    : smallestUnit(checked_int128_t{std::floor(amount * kPrecision)}) {}

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
  result.smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return result;
}

PreciseNumber &PreciseNumber::operator*=(const PreciseNumber &other) {
  this->smallestUnit = this->smallestUnit * other.smallestUnit / kPrecision;
  return *this;
}

PreciseNumber PreciseNumber::operator/(const PreciseNumber &other) const {
  PreciseNumber result{0};
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
  PreciseNumber result{0};
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

double PreciseNumber::toDouble() const {
  return smallestUnit.convert_to<double>() / kPrecision;
}

PreciseNumber PreciseNumber::min(const PreciseNumber &a,
                                 const PreciseNumber &b) {
  return (a.smallestUnit < b.smallestUnit) ? a : b;
}

PreciseNumber PreciseNumber::pow(const PreciseNumber &base,
                                 const PreciseNumber &exponent) {

  PreciseNumber result{0};
  auto powValue = std::pow(base.toDouble(), exponent.toDouble());
  result.smallestUnit = checked_int128_t{powValue * kPrecision};
  return PreciseNumber(result);
}

// Friend function for output stream
std::ostream &operator<<(std::ostream &os, const PreciseNumber &c) {
  os << c.toDouble();
  return os;
}