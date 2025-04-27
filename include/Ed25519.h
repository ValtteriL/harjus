#include <string>

namespace Ed25519 {

/**
 * @brief Sign a message using the private key
 * @param message The message to sign
 * @param privateKey The private key to use for signing
 * @return The base64 encoded signature
 */
std::string sign(std::string privateKey, std::string payload);

/**
 * @brief Base64 decode a string
 * @param encoded The base64 encoded string
 * @return The decoded string
 */
std::string base64_decode(const std::string encoded);

/**
 * @brief Base64 encode a string
 * @param data The data to encode
 * @param length The length of the data
 * @return The base64 encoded string
 */
std::string base64_encode(const unsigned char *data, size_t length);
} // namespace Ed25519