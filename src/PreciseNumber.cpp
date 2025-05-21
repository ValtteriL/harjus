#include <PreciseNumber.h>
#include <stdexcept>

PreciseNumber::PreciseNumber(double amount)
    : smallestUnit(static_cast<long long>(std::round(amount * 1e8))) {}

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

PreciseNumber PreciseNumber::operator*(const PreciseNumber &other) const {
  // Multiply smallest units and scale back to original unit
  PreciseNumber result{0};
  result.smallestUnit = static_cast<long long>(
      std::round((this->smallestUnit * other.smallestUnit) / 1e8));
  return result;
}

PreciseNumber PreciseNumber::operator/(const PreciseNumber &other) const {
  if (other.smallestUnit == 0) {
    throw std::invalid_argument("Division by zero");
  }
  // To preserve precision, scale up before division
  auto quotient = this->smallestUnit / other.smallestUnit;
  return PreciseNumber(quotient);
}

PreciseNumber PreciseNumber::fmod(const PreciseNumber &a, const PreciseNumber &b) {
  if (b.smallestUnit == 0) {
    throw std::invalid_argument("Division by zero");
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

double PreciseNumber::toDouble() const { return smallestUnit / 1e8; }

PreciseNumber PreciseNumber::min(const PreciseNumber &a, const PreciseNumber &b) {
  return (a.smallestUnit < b.smallestUnit) ? a : b;
}