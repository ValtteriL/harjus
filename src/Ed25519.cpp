#include "Ed25519.h"
#include <cstring>
#include <sodium.h>
#include <stdexcept>
#include <string>
#include <vector>

auto Ed25519::base64_encode(const unsigned char *data,
                            size_t length) -> std::string {
  // construct a buffer to hold the base64 encoded string
  const size_t b64Length =
      sodium_base64_encoded_len(length, sodium_base64_VARIANT_ORIGINAL);
  std::vector<char> b64Buffer(b64Length, 0);

  char *encoded = sodium_bin2base64(b64Buffer.data(), b64Length, data, length,
                                    sodium_base64_VARIANT_ORIGINAL);

  if (!encoded) {
    throw std::runtime_error("Failed to allocate memory for base64 encoding");
  }

  std::string b64String(encoded);
  return b64String;
}

auto Ed25519::base64_decode(const std::string &encoded) -> std::string {
  std::vector<unsigned char> decoded(encoded.size());
  size_t decoded_length = 0;

  if (sodium_base642bin(decoded.data(), decoded.size(), encoded.c_str(),
                        encoded.size(), nullptr, &decoded_length, nullptr,
                        sodium_base64_VARIANT_ORIGINAL) != 0) {
    throw std::runtime_error("Failed to decode base64 string");
  }

  return std::string(decoded.begin(), decoded.begin() + decoded_length);
}

auto Ed25519::sign(const std::string &extracted_seed,
                   const std::string &payload) -> std::string {
  if (sodium_init() < 0) {
    throw std::runtime_error("Failed to initialize libsodium");
  }

  // Decode the base64 encoded seed and convert to byte array
  std::string seedDecoded;
  try {
    seedDecoded = base64_decode(extracted_seed);
  } catch (const std::exception &e) {
    throw std::runtime_error("Failed to decode base64 seed: " +
                             std::string(e.what()));
  }

  std::vector<unsigned char> seedBytes{seedDecoded.begin(), seedDecoded.end()};

  unsigned char seed[crypto_sign_SEEDBYTES];
  unsigned char publicKey[crypto_sign_PUBLICKEYBYTES];
  unsigned char privateKey[crypto_sign_SECRETKEYBYTES];

  // Load the seed (32 bytes) from your extracted seed file
  memcpy(seed, seedBytes.data(), crypto_sign_SEEDBYTES);

  // Generate the Libsodium keypair
  crypto_sign_seed_keypair(publicKey, privateKey, seed);

  std::vector<unsigned char> signature(crypto_sign_BYTES);
  unsigned long long signatureLength = 0;

  // Generate detached signature
  if (crypto_sign_detached(
          signature.data(), &signatureLength,
          reinterpret_cast<const unsigned char *>(payload.data()),
          payload.size(),
          reinterpret_cast<const unsigned char *>(privateKey)) != 0) {
    throw std::runtime_error("Failed to sign payload with Ed25519");
  }

  // Encode the signature to base64
  return base64_encode(signature.data(), signatureLength);
}
