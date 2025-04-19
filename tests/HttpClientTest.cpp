/*
 * HttpClientTest.cpp
 * Testing the HttpClient class.
 */

#include "HttpClient.h"
#include <gtest/gtest.h>

TEST(HttpClientTest, getUri) {
  // Test with a valid URI
  std::string uri = "https://api.example.com/data";
  std::string response = get(uri);
  EXPECT_FALSE(response.empty());

  // Test with an invalid URI
  std::string invalidUri = "invalid_uri";
  EXPECT_THROW(get(invalidUri), std::runtime_error);

  // Test with an empty URI
  std::string emptyUri = "";
  EXPECT_THROW(get(emptyUri), std::runtime_error);
}
