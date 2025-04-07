/*
 * Ed25519Test.cpp
 * Testing the Ed25519 class.
 */

#include <gtest/gtest.h>
#include "Ed25519.h"
#include <sodium.h>

using namespace std::string_literals;

TEST(Ed25519Test, base64EncodeDecode)
{
  std::string input{"Hello, World!"};
  std::string expectedOutput{"SGVsbG8sIFdvcmxkIQ"};

  // Encode the input string to base64
  std::string encoded = Ed25519::base64_encode(reinterpret_cast<const unsigned char *>(input.c_str()), input.size());

  // Decode the base64 encoded string back to original
  std::string decoded = Ed25519::base64_decode(encoded);

  ASSERT_EQ(encoded, expectedOutput);
  ASSERT_EQ(decoded, input);
}

TEST(Ed25519Test, signatureIsValid)
{

  // base64-encoded seed for a ed25519 keypair
  std::string extracted_seed{"MC4CAQAwBQYDK2VwBCIEIJpJm/MC4CAQAwBQYDK2VwBCIEIG8WQL/z+p+GpQhT/2jMHGsr7ENyABR+SxcuxV8ppJI3"};

  // Decode the base64 encoded seed and convert to byte array
  auto seedDecoded = Ed25519::base64_decode(extracted_seed);
  std::vector<unsigned char> seedBytes{seedDecoded.begin(), seedDecoded.end()};

  ASSERT_TRUE(seedBytes.size() == crypto_sign_SEEDBYTES);

  unsigned char seed[crypto_sign_SEEDBYTES];
  unsigned char publicKey[crypto_sign_PUBLICKEYBYTES];
  unsigned char privateKey[crypto_sign_SECRETKEYBYTES];

  // Load the seed (32 bytes) from your extracted seed file
  memcpy(seed, seedBytes.data(), crypto_sign_SEEDBYTES);

  // Generate the Libsodium keypair
  crypto_sign_seed_keypair(publicKey, privateKey, seed);

  if (sodium_init() < 0)
  {
    throw std::runtime_error("Failed to initialize libsodium");
  }

  std::string payload{"timestamp=1234567890"}; // Replace with a valid payload
  std::string b64Signature = Ed25519::sign(extracted_seed, payload);

  // base64 decode the signature
  std::string b64SignatureDecoded = Ed25519::base64_decode(b64Signature);

  // verify the signature
  // https://libsodium.gitbook.io/doc/public-key_cryptography/public-key_signatures#notes
  const int verifStatus = crypto_sign_verify_detached(reinterpret_cast<const unsigned char *>(b64SignatureDecoded.data()),
                                                      reinterpret_cast<const unsigned char *>(payload.data()),
                                                      payload.size(),
                                                      publicKey);
  ASSERT_EQ(verifStatus, 0);
}
