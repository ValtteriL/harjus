#pragma once
/**
 * @file Currency.h
 * @brief Header file for the Currency class.
 * @details This file contains the definition of the Currency class, which
 * represents a currency amount in its smallest unit.
 */

#include <cmath> // For std::round
#include <iostream>

class Currency {
private:
  long long smallestUnit = 0;

public:
  /**
   * @brief Constructs a Currency object from a double amount.
   * @param amount The amount in the original currency (e.g., 1.23 for 1.23
   * units).
   */
  Currency(double amount);

  /**
   * @brief Adds two Currency objects.
   * @param other The other Currency object to add.
   * @return The sum as a new Currency object.
   */
  Currency operator+(const Currency &other) const;

  /**
   * @brief Subtracts one Currency object from another.
   * @param other The other Currency object to subtract.
   * @return The difference as a new Currency object.
   */
  Currency operator-(const Currency &other) const;

  /**
   * @brief Multiplies the Currency amount by a multiplier.
   * @param multiplier The value to multiply by (e.g., quantity or percentage).
   * @return The result as a new Currency object.
   */
  Currency operator*(double multiplier) const;

  /**
   * @brief Checks if two Currency objects are equal.
   * @param other The other Currency object to compare.
   * @return True if equal, false otherwise.
   */
  bool operator==(const Currency &other) const;

  /**
   * @brief Checks if this Currency object is less than another.
   * @param other The other Currency object to compare.
   * @return True if this is less, false otherwise.
   */
  bool operator<(const Currency &other) const;

  /**
   * @brief Gets the amount in the original unit.
   * @return The amount as a long long in the original unit.
   */
  long long getOriginalAmount() const;

  // Friend function for output stream
  friend std::ostream &operator<<(std::ostream &os, const Currency &c) {
    os << (c.smallestUnit < 0 ? "-" : "") << "Crypto"
       << std::abs(c.smallestUnit) << "units";
    return os;
  }
};
