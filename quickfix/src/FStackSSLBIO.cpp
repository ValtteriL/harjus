#include "FStackSSLBIO.h"
#include <climits>
#include <unistd.h>

namespace FIX
{

    static auto bio_ff_create(BIO *b) -> int
    {
        // Initialize BIO state.
        // OpenSSL stores the file descriptor in b->num usually.
        BIO_set_init(b, 0);
        BIO_set_shutdown(b, 0);
        return 1;
    }

    static auto bio_ff_destroy(BIO *b) -> int
    {
        if (b == nullptr)
            return 0;

        // If the BIO owns the socket (shutdown flag is set), close it using ff_close
        if (BIO_get_shutdown(b))
        {
            int fd = BIO_get_fd(b, nullptr);
            if (fd != -1)
            {
                ff_close(fd);
            }
        }

        return 1;
    }
    static auto bio_ff_read(BIO *b, char *out, int outl) -> int
    {
        int fd = BIO_get_fd(b, nullptr);
        if (out == nullptr || outl == 0)
            return 0;

        // infinite timeout https://deepwiki.com/F-Stack/f-stack/4.2-micro-thread-integration#timeout-strategy
        ssize_t r = NS_MICRO_THREAD::mt_read(fd, out, outl, -1);

        BIO_clear_retry_flags(b);
        if (r <= 0 && errno == EAGAIN)
        {
            BIO_set_retry_read(b);
        }

        if (r > INT_MAX)
            return INT_MAX;
        if (r < INT_MIN)
            return INT_MIN;
        return static_cast<int>(r);
    }

    static auto bio_ff_write(BIO *b, const char *in, int inl) -> int
    {
        int fd = BIO_get_fd(b, nullptr);
        if (in == nullptr || inl == 0)
            return 0;

        // 1s timeout https://deepwiki.com/F-Stack/f-stack/4.2-micro-thread-integration#timeout-strategy
        ssize_t r = NS_MICRO_THREAD::mt_write(fd, in, inl, 1000);

        BIO_clear_retry_flags(b);
        if (r <= 0 && errno == EAGAIN)
        {
            BIO_set_retry_write(b);
        }

        if (r > INT_MAX)
            return INT_MAX;
        if (r < INT_MIN)
            return INT_MIN;
        return static_cast<int>(r);
    }

    static auto bio_ff_ctrl(BIO *b, int cmd, long num, void *ptr) -> long
    {
        long ret = 1;
        int *ip = nullptr;

        int fd = BIO_get_fd(b, nullptr);

        switch (cmd)
        {
        case BIO_C_SET_FD:
            // Store the FD in the BIO structure
            bio_ff_destroy(b); // Close old one if exists and we own it
            BIO_set_init(b, 1);
            BIO_set_fd(b, (int)num, BIO_CLOSE); // Store in b->num
            BIO_set_shutdown(b, (int)num);      // Default to closing on destroy
            break;

        case BIO_C_GET_FD:
            // Retrieve the FD
            if (BIO_get_init(b))
            {
                ip = (int *)ptr;
                if (ip != nullptr)
                    *ip = fd;
                ret = fd;
            }
            else
            {
                ret = -1;
            }
            break;

        case BIO_CTRL_GET_CLOSE:
            ret = BIO_get_shutdown(b);
            break;

        case BIO_CTRL_SET_CLOSE:
            BIO_set_shutdown(b, (int)num);
            break;

        case BIO_CTRL_FLUSH:
            // Sockets usually don't need explicit flushing at BIO level, return 1
            ret = 1;
            break;

        case BIO_CTRL_DUP:
        case BIO_CTRL_PUSH:
        case BIO_CTRL_POP:
        default:
            ret = 0;
            break;
        }
        return ret;
    }

    static auto bio_ff_puts(BIO *b, const char *str) -> int
    {
        return bio_ff_write(b, str, strlen(str));
    }

    auto BIO_s_ff_socket() -> BIO_METHOD *
    {
        if (method_ff_socket == nullptr)
        {
            // Get a unique type index for this BIO
            BIO_TYPE_FF_SOCKET = BIO_get_new_index() | BIO_TYPE_SOURCE_SINK;

            method_ff_socket = BIO_meth_new(BIO_TYPE_FF_SOCKET, "ff_socket");

            BIO_meth_set_write(method_ff_socket, bio_ff_write);
            BIO_meth_set_read(method_ff_socket, bio_ff_read);
            BIO_meth_set_puts(method_ff_socket, bio_ff_puts);
            BIO_meth_set_ctrl(method_ff_socket, bio_ff_ctrl);
            BIO_meth_set_create(method_ff_socket, bio_ff_create);
            BIO_meth_set_destroy(method_ff_socket, bio_ff_destroy);
        }
        return method_ff_socket;
    }

    auto BIO_new_ff_socket(int fd, int close_flag) -> BIO *
    {
        BIO *ret = BIO_new(BIO_s_ff_socket());
        if (ret == nullptr)
            return nullptr;

        BIO_set_fd(ret, fd, close_flag);
        return ret;
    }
}