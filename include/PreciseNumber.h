#pragma once
/**
 * @file PreciseNumber.h
 * @brief Header file for the PreciseNumber class.
 * @details This file contains the definition of the PreciseNumber class, which
 * represents a currency amount in its smallest unit.
 */

#include <boost/multiprecision/gmp.hpp>
#include <cmath>
#include <iostream>

namespace bm = boost::multiprecision;

class PreciseNumber {
private:
  bm::mpz_int smallestUnit = 0;
  static constexpr long long kPrecision = 1e10;

public:
  /**
   * @brief Default constructor for PreciseNumber.
   * Initializes the smallest unit to zero.
   */
  PreciseNumber() = default;

  /**
   * @brief Constructs a PreciseNumber object from a string representation of
   * the amount.
   * @param amount The amount as a string (e.g., "1.23").
   */
  PreciseNumber(const std::string &amount);

  /**
   * @brief Deleted constructor that prevents construction of PreciseNumber from
   * an int.
   *
   * This constructor is explicitly deleted to avoid implicit or accidental
   * conversion from int to PreciseNumber, ensuring type safety and precision.
   *
   * @param int Unused. Construction from int is not allowed.
   */
  PreciseNumber(int) = delete;

  /**
   * @brief Copy assignment
   * @param other The other PreciseNumber object to copy from.
   */
  auto operator=(const PreciseNumber &other) -> PreciseNumber &;

  /**
   * @brief Copy constructor for PreciseNumber.
   * @param other The PreciseNumber object to copy from.
   */
  PreciseNumber(const PreciseNumber &other);

  /**
   * @brief Adds two PreciseNumber objects.
   * @param other The other PreciseNumber object to add.
   * @return The sum as a new PreciseNumber object.
   */
  auto operator+(const PreciseNumber &other) const -> PreciseNumber;

  /**
   * @brief Adds another PreciseNumber to this one (in-place).
   * @param other The other PreciseNumber object to add.
   * @return Reference to this object after addition.
   */
  auto operator+=(const PreciseNumber &other) -> PreciseNumber &;

  /**
   * @brief Subtracts one PreciseNumber object from another.
   * @param other The other PreciseNumber object to subtract.
   * @return The difference as a new PreciseNumber object.
   */
  auto operator-(const PreciseNumber &other) const -> PreciseNumber;

  /**
   * @brief Subtracts another PreciseNumber from this one (in-place).
   * @param other The other PreciseNumber object to subtract.
   * @return Reference to this object after subtraction.
   */
  auto operator-=(const PreciseNumber &other) -> PreciseNumber &;

  /**
   * @brief Multiplies two PreciseNumber amounts.
   * @param other The other PreciseNumber object to multiply by.
   * @return The result as a new PreciseNumber object.
   */
  auto operator*(const PreciseNumber &other) const -> PreciseNumber;

  /**
   * @brief Multiplies this PreciseNumber by another (in-place).
   * @param other The other PreciseNumber object to multiply by.
   * @return Reference to this object after multiplication.
   */
  auto operator*=(const PreciseNumber &other) -> PreciseNumber &;

  /**
   * @brief Divides this PreciseNumber by another.
   * @param other The divisor PreciseNumber object.
   * @return The quotient as a new PreciseNumber object.
   */
  auto operator/(const PreciseNumber &other) const -> PreciseNumber;

  /**
   * @brief Divides this PreciseNumber by another (in-place).
   * @param other The divisor PreciseNumber object.
   * @return Reference to this object after division.
   */
  auto operator/=(const PreciseNumber &other) -> PreciseNumber &;

  /**
   * @brief Computes the floating-point remainder of division (modulo) with
   * another PreciseNumber.
   * @param a The dividend PreciseNumber object.
   * @param b The divisor PreciseNumber object.
   * @return The remainder as a new PreciseNumber object.
   */
  static auto fmod(const PreciseNumber &a,
                   const PreciseNumber &b) -> PreciseNumber;

  /**
   * @brief Checks if two PreciseNumber objects are equal.
   * @param other The other PreciseNumber object to compare.
   * @return True if equal, false otherwise.
   */
  auto operator==(const PreciseNumber &other) const -> bool;

  /**
   * @brief Checks if this PreciseNumber object is less than another.
   * @param other The other PreciseNumber object to compare.
   * @return True if this is less, false otherwise.
   */
  auto operator<(const PreciseNumber &other) const -> bool;

  /**
   * @brief Checks if this PreciseNumber object is greater than another.
   * @param other The other PreciseNumber object to compare.
   * @return True if this is greater, false otherwise.
   */
  auto operator>(const PreciseNumber &other) const -> bool;

  /**
   * @brief Checks if this PreciseNumber object is greater than or equal to
   * another.
   * @param other The other PreciseNumber object to compare.
   * @return True if this is greater or equal, false otherwise.
   */
  auto operator>=(const PreciseNumber &other) const -> bool;

  /**
   * @brief Returns the string representation of the PreciseNumber.
   * @return The amount as a string in the original unit.
   */
  [[nodiscard]] auto toString() const -> std::string;

  /**
   * @brief Returns the smaller of two PreciseNumbers.
   * @param a The first PreciseNumber object to compare.
   * @param b The second PreciseNumber object to compare.
   * @return The minimum PreciseNumber.
   */
  static auto min(const PreciseNumber &a,
                  const PreciseNumber &b) -> PreciseNumber;

  // Friend function for output stream
  friend auto operator<<(std::ostream &os,
                         const PreciseNumber &c) -> std::ostream &;
};
