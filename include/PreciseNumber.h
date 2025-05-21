#pragma once
/**
 * @file PreciseNumber.h
 * @brief Header file for the PreciseNumber class.
 * @details This file contains the definition of the PreciseNumber class, which
 * represents a currency amount in its smallest unit.
 */

#include <cmath> // For std::round
#include <iostream>

class PreciseNumber {
private:
  long long smallestUnit = 0;

public:
  /**
   * @brief Default constructor for PreciseNumber.
   * Initializes the smallest unit to zero.
   */
  PreciseNumber() = default;

  /**
   * @brief Constructs a PreciseNumber object from a double amount.
   * @param amount The amount in the original currency (e.g., 1.23 for 1.23
   * units).
   */
  PreciseNumber(double amount);

  /**
   * @brief Adds two PreciseNumber objects.
   * @param other The other PreciseNumber object to add.
   * @return The sum as a new PreciseNumber object.
   */
  PreciseNumber operator+(const PreciseNumber &other) const;

  /**
   * @brief Subtracts one PreciseNumber object from another.
   * @param other The other PreciseNumber object to subtract.
   * @return The difference as a new PreciseNumber object.
   */
  PreciseNumber operator-(const PreciseNumber &other) const;

  /**
   * @brief Multiplies the PreciseNumber amount by a multiplier.
   * @param multiplier The value to multiply by (e.g., quantity or percentage).
   * @return The result as a new PreciseNumber object.
   */
  PreciseNumber operator*(double multiplier) const;

  /**
   * @brief Checks if two PreciseNumber objects are equal.
   * @param other The other PreciseNumber object to compare.
   * @return True if equal, false otherwise.
   */
  bool operator==(const PreciseNumber &other) const;

  /**
   * @brief Checks if this PreciseNumber object is less than another.
   * @param other The other PreciseNumber object to compare.
   * @return True if this is less, false otherwise.
   */
  bool operator<(const PreciseNumber &other) const;

  /**
   * @brief Gets the amount in the original unit.
   * @return The amount as a double in the original unit.
   */
  double toDouble() const;

  // Friend function for output stream
  friend std::ostream &operator<<(std::ostream &os, const PreciseNumber &c) {
    os << (c.smallestUnit < 0 ? "-" : "") << std::abs(c.smallestUnit)
       << "(smallest unit)";
    return os;
  }
};
