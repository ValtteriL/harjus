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

PreciseNumber PreciseNumber::operator*(double multiplier) const {
  PreciseNumber result{0};
  result.smallestUnit =
      static_cast<long long>(std::round(this->smallestUnit * multiplier));
  return result;
}

PreciseNumber PreciseNumber::fmod(const PreciseNumber &other) const {
  PreciseNumber result;
  if (other.smallestUnit == 0) {
    // Division by zero, return zero or throw if desired
    throw std::invalid_argument("Division by zero");
  }
  result.smallestUnit = this->smallestUnit % other.smallestUnit;
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