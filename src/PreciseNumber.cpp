#include <PreciseNumber.h>

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

bool PreciseNumber::operator==(const PreciseNumber &other) const {
  return this->smallestUnit == other.smallestUnit;
}
bool PreciseNumber::operator<(const PreciseNumber &other) const {
  return this->smallestUnit < other.smallestUnit;
}

long long PreciseNumber::getOriginalAmount() const {
  return smallestUnit / 1e8;
}