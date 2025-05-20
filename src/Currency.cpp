#include <Currency.h>

Currency::Currency(double amount)
    : smallestUnit(static_cast<long long>(std::round(amount * 1e8))) {}

Currency Currency::operator+(const Currency &other) const {
  Currency result{0};
  result.smallestUnit = this->smallestUnit + other.smallestUnit;
  return result;
}

Currency Currency::operator-(const Currency &other) const {
  Currency result{0};
  result.smallestUnit = this->smallestUnit - other.smallestUnit;
  return result;
}

Currency Currency::operator*(double multiplier) const {
  Currency result{0};
  result.smallestUnit =
      static_cast<long long>(std::round(this->smallestUnit * multiplier));
  return result;
}

bool Currency::operator==(const Currency &other) const {
  return this->smallestUnit == other.smallestUnit;
}
bool Currency::operator<(const Currency &other) const {
  return this->smallestUnit < other.smallestUnit;
}

long long Currency::getOriginalAmount() const { return smallestUnit / 1e8; }