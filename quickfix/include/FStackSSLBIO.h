/*
 * Custom BIO implementation for F-Stack SSL connections
 */

#pragma once

#include <arpa/inet.h>
#include <cstring>
#include <iostream>
#include <netdb.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

#include <errno.h>
#include <ff_api.h>
#include <mt_api.h>

namespace FIX
{
    /**
     * @brief A unique type ID for our BIO.
     *
     * This value is populated at runtime via BIO_get_new_index().
     */
    static int BIO_TYPE_FF_SOCKET = 0;

    /**
     * @brief The static method structure that holds our callbacks.
     *
     * Allocated once by BIO_s_ff_socket().
     */
    static BIO_METHOD *method_ff_socket = nullptr;

    // --- BIO Callbacks ---

    /**
     * @brief Create (constructor) for the custom BIO.
     *
     * Initializes internal BIO state. Called by OpenSSL when the BIO is allocated.
     *
     * @param b Pointer to the BIO instance to initialize.
     * @return 1 on success, 0 on failure.
     */
    static int bio_ff_create(BIO *b);

    /**
     * @brief Destroy (destructor) for the custom BIO.
     *
     * Cleans up any resources owned by the BIO. If the BIO owns a socket and the
     * shutdown flag is set, closes it via ff_close().
     *
     * @param b Pointer to the BIO instance to destroy.
     * @return 1 on success, 0 on failure.
     */
    static int bio_ff_destroy(BIO *b);

    /**
     * @brief Read data from the underlying ff socket.
     *
     * This function must behave similarly to the read callback expected by OpenSSL.
     * Non-blocking behaviour and retry flags should be handled by the implementation.
     *
     * @param b   Pointer to the BIO.
     * @param out Buffer to receive data.
     * @param outl Length of the buffer.
     * @return Number of bytes read, 0 or negative on error.
     */
    static int bio_ff_read(BIO *b, char *out, int outl);

    /**
     * @brief Write data to the underlying ff socket.
     *
     * Writes up to inl bytes from in to the socket. Non-blocking behaviour should
     * set appropriate retry flags on the BIO.
     *
     * @param b   Pointer to the BIO.
     * @param in  Buffer containing data to send.
     * @param inl Number of bytes to write.
     * @return Number of bytes written, 0 or negative on error.
     */
    static int bio_ff_write(BIO *b, const char *in, int inl);

    /**
     * @brief Control function for the BIO.
     *
     * Handles various BIO control commands (set/get fd, set/get close, flush, etc.).
     *
     * @param b   Pointer to the BIO.
     * @param cmd Control command identifier.
     * @param num Numeric argument for the command.
     * @param ptr Pointer argument for the command.
     * @return Command-specific return value (see OpenSSL BIO_ctrl conventions).
     */
    static long bio_ff_ctrl(BIO *b, int cmd, long num, void *ptr);

    /**
     * @brief Puts implementation, typically forwarded to write.
     *
     * @param b   Pointer to the BIO.
     * @param str Null-terminated string to write.
     * @return Number of bytes written, 0 or negative on error.
     */
    static int bio_ff_puts(BIO *b, const char *str);

    // --- Method Registration ---

    /**
     * @brief Returns the BIO_METHOD for the ff_socket BIO.
     *
     * Allocates and initializes method_ff_socket on first call.
     *
     * @return Pointer to a BIO_METHOD describing the ff_socket BIO.
     */
    BIO_METHOD *BIO_s_ff_socket(void);

    /**
     * @brief Helper to create a new BIO using our method.
     *
     * @param fd File descriptor (ff socket) to associate with the BIO.
     * @param close_flag If non-zero, BIO will close the fd on destroy.
     * @return Newly allocated BIO, or nullptr on failure.
     */
    BIO *BIO_new_ff_socket(int fd, int close_flag);
}