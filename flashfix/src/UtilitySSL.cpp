/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* ====================================================================
 * Copyright (c) 1998-2006 Ralf S. Engelschall. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by
 *     Ralf S. Engelschall <rse@engelschall.com> for use in the
 *     mod_ssl project (http://www.modssl.org/)."
 *
 * 4. The names "mod_ssl" must not be used to endorse or promote
 *    products derived from this software without prior written
 *    permission. For written permission, please contact
 *    rse@engelschall.com.
 *
 * 5. Products derived from this software may not be called "mod_ssl"
 *    nor may "mod_ssl" appear in their names without prior
 *    written permission of Ralf S. Engelschall.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by
 *     Ralf S. Engelschall <rse@engelschall.com> for use in the
 *     mod_ssl project (http://www.modssl.org/)."
 *
 * THIS SOFTWARE IS PROVIDED BY RALF S. ENGELSCHALL ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL RALF S. ENGELSCHALL OR
 * HIS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 */

/* ====================================================================
 * Copyright (c) 1995-1999 Ben Laurie. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by Ben Laurie
 *    for use in the Apache-SSL HTTP server project."
 *
 * 4. The name "Apache-SSL Server" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission.
 *
 * 5. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by Ben Laurie
 *    for use in the Apache-SSL HTTP server project."
 *
 * THIS SOFTWARE IS PROVIDED BY BEN LAURIE ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL BEN LAURIE OR
 * HIS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 */

#include "UtilitySSL.h"
#include "Mutex.h"

#include "openssl/bio.h" // BIO objects for I/O
#include "openssl/bn.h"
#include "openssl/crypto.h"
#include "openssl/err.h" // Error reporting
#include "openssl/rand.h"
#ifndef OPENSSL_NO_DH
#include "openssl/dh.h"
#endif

#include "mt_api.h"
#include <micro_thread.h>
#include <mt_incl.h>

namespace FIX
{

#ifndef OPENSSL_NO_DH
    static auto load_dh_param(const char *dhfile) -> DH *
    {
        DH *ret = nullptr;
        BIO *bio = nullptr;

        if ((bio = BIO_new_file(dhfile, "r")) == nullptr)
        {
            goto err;
        }
        ret = PEM_read_bio_DHparams(bio, nullptr, nullptr, nullptr);
    err:
        if (bio != nullptr)
        {
            BIO_free(bio);
        }
        return (ret);
    }

    /*
     * Grab well-defined DH parameters from OpenSSL, see the BN_get_rfc*
     * functions in <openssl/bn.h> for all available primes.
     */
    static auto make_dh_params(BIGNUM *(*prime)(BIGNUM *)) -> DH *
    {
        DH *dh = DH_new();
        BIGNUM *p = nullptr, *g = nullptr;

        if (!dh)
        {
            return nullptr;
        }
        p = prime(nullptr);
        g = BN_new();
        if (g != nullptr)
        {
            BN_set_word(g, 2);
        }
        if (!p || !g || !DH_set0_pqg(dh, p, nullptr, g))
        {
            DH_free(dh);
            BN_free(p);
            BN_free(g);
            return nullptr;
        }
        return dh;
    }

    /* Storage and initialization for DH parameters. */
    static struct dhparam
    {
        BIGNUM *(*const prime)(BIGNUM *); /* function to generate... */
        DH *dh;                           /* ...this, used for keys.... */
        const unsigned int min;           /* ...of length >= this. */
    } dhparams[] = {{get_rfc3526_prime_8192, nullptr, 6145},
                    {get_rfc3526_prime_6144, nullptr, 4097},
                    {get_rfc3526_prime_4096, nullptr, 3073},
                    {get_rfc3526_prime_3072, nullptr, 2049},
                    {get_rfc3526_prime_2048, nullptr, 1025},
                    {get_rfc2409_prime_1024, nullptr, 0}};

    static void init_dh_params()
    {
        unsigned n = 0;

        for (n = 0; n < sizeof(dhparams) / sizeof(dhparams[0]); n++)
        {
            dhparams[n].dh = make_dh_params(dhparams[n].prime);
        }
    }

    static void free_dh_params()
    {
        unsigned n = 0;

        /* DH_free() is a noop for a NULL parameter, so these are harmless
         * in the (unexpected) case where these variables are already
         * NULL. */
        for (n = 0; n < sizeof(dhparams) / sizeof(dhparams[0]); n++)
        {
            DH_free(dhparams[n].dh);
            dhparams[n].dh = nullptr;
        }
    }

    /* Hand out the same DH structure though once generated as we leak
     * memory otherwise and freeing the structure up after use would be
     * hard to track and in fact is not needed at all as it is safe to
     * use the same parameters over and over again security wise (in
     * contrast to the keys itself) and code safe as the returned structure
     * is duplicated by OpenSSL anyway. Hence no modification happens
     * to our copy. */
    auto modssl_get_dh_params(unsigned keylen) -> DH *
    {
        unsigned n = 0;

        for (n = 0; n < sizeof(dhparams) / sizeof(dhparams[0]); n++)
        {
            if (keylen >= dhparams[n].min)
            {
                return dhparams[n].dh;
            }
        }

        return nullptr; /* impossible to reach. */
    }

    /*
     * Hand out standard DH parameters, based on the authentication strength
     */
    auto ssl_callback_TmpDH(SSL *ssl, int exportvar, int keylen) -> DH *
    {
        EVP_PKEY *pkey = nullptr;
        int type = 0;

        pkey = SSL_get_privatekey(ssl);
        type = pkey ? EVP_PKEY_base_id(pkey) : EVP_PKEY_NONE;

        /*
         * OpenSSL will call us with either keylen == 512 or keylen == 1024
         * (see the definition of SSL_EXPORT_PKEYLENGTH in ssl_locl.h).
         * Adjust the DH parameter length according to the size of the
         * RSA/DSA private key used for the current connection, and always
         * use at least 1024-bit parameters.
         * Note: This may cause interoperability issues with implementations
         * which limit their DH support to 1024 bit - e.g. Java 7 and earlier.
         * In this case, SSLCertificateFile can be used to specify fixed
         * 1024-bit DH parameters (with the effect that OpenSSL skips this
         * callback).
         */
        if ((type == EVP_PKEY_RSA) || (type == EVP_PKEY_DSA))
        {
            keylen = EVP_PKEY_bits(pkey);
        }

        return modssl_get_dh_params(keylen);
    }
#endif

    /* Mutex to protect ssl init and terminate */
    static Mutex ssl_mutex;
    /* Reference count of ssl users. Should always call ssl_init/ssl_term */
    static int ssl_users = 0;
    static int ssl_initialized = 0;
    /* This array will store all of the mutexes available to OpenSSL. */

    static pthread_mutex_t *lock_cs = nullptr;

    static void thread_setup(); // For thread safety.
    static void thread_cleanup();
    static void ssl_rand_seed();

    /* SSL key logging for Wireshark traffic decryption */
    static FILE *ssl_keylog_file = nullptr;
    static std::string ssl_keylog_file_path;

    static void ssl_keylog_callback(const SSL * /*ssl*/, const char *line)
    {
        if (ssl_keylog_file != nullptr)
        {
            fprintf(ssl_keylog_file, "%s\n", line);
            fflush(ssl_keylog_file);
        }
    }

    void ssl_set_keylog_file(const std::string &filePath)
    {
        if (filePath.empty())
        {
            ssl_keylog_file_path.clear();
            return;
        }

        ssl_keylog_file_path = filePath;
        ssl_keylog_file = fopen(filePath.c_str(), "a");
    }

    void ssl_close_keylog_file()
    {
        if (ssl_keylog_file != nullptr)
        {
            fclose(ssl_keylog_file);
            ssl_keylog_file = nullptr;
        }
        ssl_keylog_file_path.clear();
    }

    auto ssl_is_keylog_enabled() -> bool
    {
        return ssl_keylog_file != nullptr;
    }

    void ssl_init()
    {

        Locker locker(ssl_mutex);
        ++ssl_users;

        thread_setup();

        if (ssl_initialized)
        {
            return;
        }

        OPENSSL_init_ssl(OPENSSL_INIT_LOAD_SSL_STRINGS | OPENSSL_INIT_LOAD_CRYPTO_STRINGS, nullptr);
        OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_CIPHERS | OPENSSL_INIT_ADD_ALL_DIGESTS, nullptr);

        ssl_rand_seed();

        ssl_initialized = 1;

#ifndef OPENSSL_NO_DH
        init_dh_params();
#endif

        return;
    }

    void ssl_term()
    {

        Locker locker(ssl_mutex);
        --ssl_users;

        if (ssl_users > 0)
        {
            return;
        }

        thread_cleanup();

        /* Close SSL keylog file if open */
        ssl_close_keylog_file();

#ifndef OPENSSL_NO_DH
        free_dh_params();
#endif
    }

    void ssl_socket_close(socket_handle socket, SSL *ssl)
    {

        if (ssl == nullptr)
        {
            socket_close(socket);
            return;
        }

        int i = 0;
        int rc = 0;

        for (i = 0; i < 4; i++)
        {
            if ((rc = SSL_shutdown(ssl)) == 1)
            {
                break;
            }
        }
    }

    static void thread_setup()
    {

        if (lock_cs != nullptr)
        {
            return;
        }

        int i = 0;

        lock_cs = (pthread_mutex_t *)OPENSSL_malloc(CRYPTO_num_locks() * sizeof(pthread_mutex_t));
        for (i = 0; i < CRYPTO_num_locks(); i++)
        {
            pthread_mutex_init(&(lock_cs[i]), nullptr);
        }

#ifndef _MSC_VER
        CRYPTO_set_id_callback((unsigned long (*)(void))thread_id_func);
#endif
        CRYPTO_set_locking_callback((void (*)(int, int, const char *, int))locking_callback);
    }

    static void thread_cleanup()
    {

        if (lock_cs == nullptr)
        {
            return;
        }

#ifndef _MSC_VER
        CRYPTO_set_id_callback(0);
#endif
        CRYPTO_set_locking_callback(0);

        int i = 0;

        for (i = 0; i < CRYPTO_num_locks(); i++)
        {
            pthread_mutex_destroy(&(lock_cs[i]));
        }
        OPENSSL_free(lock_cs);

        lock_cs = nullptr;
    }

    static auto ssl_rand_choose_num(int l, int h) -> int
    {
        int i = 0;
        char buf[50];

        srand((unsigned int)time(nullptr));
        snprintf(buf, sizeof(buf), "%.0f", (((double)(rand() % RAND_MAX) / RAND_MAX) * (h - l)));
        buf[sizeof(buf) - 1] = 0;
        i = atoi(buf) + 1;
        if (i < l)
        {
            i = l;
        }
        if (i > h)
        {
            i = h;
        }
        return i;
    }

    static void ssl_rand_seed()
    {
#ifdef _MSC_VER
        int pid;
#else
        pid_t pid = 0;
#endif
        int n = 0, l = 0;
        unsigned char stackdata[256];
        time_t t = time(nullptr);

        /*
         * seed in the current time (usually just 4 bytes)
         */
        l = sizeof(time_t);
        RAND_seed((unsigned char *)&t, l);
        /*
         * seed in the current process id (usually just 4 bytes)
         */
        pid = getpid();
        l = sizeof(pid);
        RAND_seed((unsigned char *)&pid, l);
        /*
         * seed in some current state of the run-time stack (128 bytes)
         */
        n = ssl_rand_choose_num(0, sizeof(stackdata) - 128 - 1);
        RAND_seed(stackdata + n, 128);
    }

    auto caListX509NameCmp(const X509_NAME *const *a, const X509_NAME *const *b) -> int { return (X509_NAME_cmp(*a, *b)); }

    auto callbackVerify(int ok, X509_STORE_CTX *ctx) -> int
    {
        X509 *xs = nullptr;
        int errnum = 0;
        int errdepth = 0;
        char *cp = nullptr;
        char *cp2 = nullptr;

        /*
         * Get verify ingredients
         */
        xs = X509_STORE_CTX_get_current_cert(ctx);
        errnum = X509_STORE_CTX_get_error(ctx);
        errdepth = X509_STORE_CTX_get_error_depth(ctx);

        /*
         * Log verification information
         */
        cp = X509_NAME_oneline(X509_get_subject_name(xs), nullptr, 0);
        cp2 = X509_NAME_oneline(X509_get_issuer_name(xs), nullptr, 0);
        printf(
            "Certificate Verification: depth: %d, subject: %s, issuer: %s\n",
            errdepth,
            cp != nullptr ? cp : "-unknown-",
            cp2 != nullptr ? cp2 : "-unknown");

        if (cp)
        {
            free(cp);
        }
        if (cp2)
        {
            free(cp2);
        }

        /*
         * If we already know it's not ok, log the real reason
         */
        if (!ok)
        {
            printf("Certificate Verification: Error (%d): %s\n", errnum, X509_verify_cert_error_string(errnum));
            ERR_print_errors_fp(stderr);
        }

        return (ok);
    }

    auto typeofSSLAlgo(X509 *pCert, EVP_PKEY *pKey) -> int
    {

        int t = 0;

        t = SSL_ALGO_UNKNOWN;
        if (pCert != nullptr)
        {
            pKey = X509_get_pubkey(pCert);
        }
        if (pKey != nullptr)
        {
#if OPENSSL_VERSION_NUMBER < 0x10100000L
            switch (EVP_PKEY_type(pKey->type))
#else
            switch (EVP_PKEY_base_id(pKey))
#endif
            {
            case EVP_PKEY_RSA:
                t = SSL_ALGO_RSA;
                break;
            case EVP_PKEY_DSA:
                t = SSL_ALGO_DSA;
                break;
            case EVP_PKEY_EC:
                t = SSL_ALGO_EC;
                break;
            default:
                break;
            }
        }
        return t;
    }

    auto findCAList(const char *cpCAfile, const char *cpCApath) -> STACK_OF(X509_NAME) *
    {
        STACK_OF(X509_NAME) *skCAList = nullptr;
        STACK_OF(X509_NAME) *sk = nullptr;
#ifndef HAVE_ACE_DIRENT
        DIR *dir = nullptr;
        struct dirent *direntry = nullptr;
#else
        ACE_DIR *dir;
        struct ACE_DIRENT *direntry;
#endif
        char *cp = nullptr;
        int n = 0;

/*
 * Start with a empty stack/list where new
 * entries get added in sorted order.
 */
#ifndef __SUNPRO_CC
        skCAList = sk_X509_NAME_new(caListX509NameCmp);
#else
        skCAList = sk_X509_NAME_new((int (*)(const X509_name_st *const *, const X509_name_st *const *))caListX509NameCmp);
#endif

        /*
         * Process CA certificate bundle file
         */
        if (cpCAfile != nullptr)
        {
            sk = SSL_load_client_CA_file(cpCAfile);
            for (n = 0; sk != nullptr && n < sk_X509_NAME_num(sk); n++)
            {
                // TODO log->onEvent(std::string("CA certificate: ") +
                // X509_NAME_oneline(sk_X509_NAME_value(sk, n), 0, 0));
                if (sk_X509_NAME_find(skCAList, sk_X509_NAME_value(sk, n)) < 0)
                {
                    sk_X509_NAME_push(skCAList, sk_X509_NAME_value(sk, n));
                }
            }
        }

        /*
         * Process CA certificate path files
         */
        if (cpCApath != nullptr)
        {
#ifndef HAVE_ACE_DIRENT
            dir = opendir(cpCApath);
#else
            dir = ACE_OS::opendir(cpCApath);
#endif

#ifndef HAVE_ACE_DIRENT
            while ((direntry = readdir(dir)) != nullptr)
            {
#else
            while ((direntry = ACE_OS::readdir(dir)) != 0)
            {
#endif
                cp = string_concat(cpCApath, SLASH, direntry->d_name, 0);
                sk = SSL_load_client_CA_file(cp);
                for (n = 0; sk != nullptr && n < sk_X509_NAME_num(sk); n++)
                {
                    // TODO log->onEvent(std::string("CA certificate: %s") +
                    //           X509_NAME_oneline(sk_X509_NAME_value(sk, n), 0, 0));
                    if (sk_X509_NAME_find(skCAList, sk_X509_NAME_value(sk, n)) < 0)
                    {
                        sk_X509_NAME_push(skCAList, sk_X509_NAME_value(sk, n));
                    }
                }
            }
#ifndef HAVE_ACE_DIRENT
            closedir(dir);
#else
            ACE_OS::closedir(dir);
#endif
        }

        /*
         * Cleanup
         */
        sk_X509_NAME_set_cmp_func(skCAList, nullptr);
        return skCAList;
    }

    auto createX509Store(const char *cpFile, const char *cpPath) -> X509_STORE *
    {
        X509_STORE *pStore = nullptr;
        X509_LOOKUP *pLookup = nullptr;

        if (cpFile == nullptr && cpPath == nullptr)
        {
            return nullptr;
        }
        if ((pStore = X509_STORE_new()) == nullptr)
        {
            return nullptr;
        }
        if (cpFile != nullptr)
        {
            if ((pLookup = X509_STORE_add_lookup(pStore, X509_LOOKUP_file())) == nullptr)
            {
                X509_STORE_free(pStore);
                return nullptr;
            }
            X509_LOOKUP_load_file(pLookup, cpFile, X509_FILETYPE_PEM);
        }
        if (cpPath != nullptr)
        {
            if ((pLookup = X509_STORE_add_lookup(pStore, X509_LOOKUP_hash_dir())) == nullptr)
            {
                X509_STORE_free(pStore);
                return nullptr;
            }
            X509_LOOKUP_add_dir(pLookup, cpPath, X509_FILETYPE_PEM);
        }
        return pStore;
    }
    auto readX509(FILE *fp, X509 **x509, passPhraseHandleCallbackType cb, void *passwordCallbackParam) -> X509 *
    {
        X509 *rc = nullptr;
        BIO *bioS = nullptr;
        BIO *bioF = nullptr;

        rc = PEM_read_X509(fp, x509, cb, passwordCallbackParam);
        if (rc == nullptr)
        {
            /* 2. try DER+Base64 */
            fseek(fp, 0L, SEEK_SET);
            if ((bioS = BIO_new(BIO_s_fd())) == nullptr)
            {
                return nullptr;
            }
            BIO_set_fd(bioS, fileno(fp), BIO_NOCLOSE);
            if ((bioF = BIO_new(BIO_f_base64())) == nullptr)
            {
                BIO_free(bioS);
                return nullptr;
            }
            bioS = BIO_push(bioF, bioS);
            rc = d2i_X509_bio(bioS, nullptr);
            BIO_free_all(bioS);
            if (rc == nullptr)
            {
                /* 3. try plain DER */
                fseek(fp, 0L, SEEK_SET);
                if ((bioS = BIO_new(BIO_s_fd())) == nullptr)
                {
                    return nullptr;
                }
                BIO_set_fd(bioS, fileno(fp), BIO_NOCLOSE);
                rc = d2i_X509_bio(bioS, nullptr);
                BIO_free(bioS);
            }
        }
        if (rc != nullptr && x509 != nullptr)
        {
            if (*x509 != nullptr)
            {
                X509_free(*x509);
            }
            *x509 = rc;
        }
        return rc;
    }

    auto readPrivateKey(FILE *fp, EVP_PKEY **key, passPhraseHandleCallbackType cb, void *passwordCallbackParam) -> EVP_PKEY *
    {
        EVP_PKEY *rc = nullptr;
        BIO *bioS = nullptr;
        BIO *bioF = nullptr;

        rc = PEM_read_PrivateKey(fp, key, cb, passwordCallbackParam);
        if (rc == nullptr)
        {
            /* 2. try DER+Base64 */
            fseek(fp, 0L, SEEK_SET);
            if ((bioS = BIO_new(BIO_s_fd())) == nullptr)
            {
                return nullptr;
            }
            BIO_set_fd(bioS, fileno(fp), BIO_NOCLOSE);
            if ((bioF = BIO_new(BIO_f_base64())) == nullptr)
            {
                BIO_free(bioS);
                return nullptr;
            }
            bioS = BIO_push(bioF, bioS);
            rc = d2i_PrivateKey_bio(bioS, nullptr);
            BIO_free_all(bioS);
            if (rc == nullptr)
            {
                fseek(fp, 0L, SEEK_SET);
                if ((bioS = BIO_new(BIO_s_fd())) == nullptr)
                {
                    return nullptr;
                }
                BIO_set_fd(bioS, fileno(fp), BIO_NOCLOSE);
                rc = d2i_PrivateKey_bio(bioS, nullptr);
                BIO_free(bioS);
            }
        }
        if (rc != nullptr && key != nullptr)
        {
            if (*key != nullptr)
            {
                EVP_PKEY_free(*key);
            }
            *key = rc;
        }
        return rc;
    }

    auto setSocketNonBlocking(socket_handle pSocket) -> int
    /********************************************************************************
     * switch socket to non-blocking mode
     * Returns: 0 in the case of success, -1 in the case of error
     *
     */
    {
#ifdef _MSC_VER
        {
            unsigned long arg = 1; /* ie enable non-blocking mode */

            if (ioctlsocket(pSocket, FIONBIO, &arg) == SOCKET_ERROR)
            {
                int ecode = WSAGetLastError();

                /* EINVAL returned when an attempt is made to set non-blocking a socket
                 * accepted on a non-blocking listen socket.  dont know why */

                if (ecode != WSAEINVAL)
                {
                    // TODO LogEvent(
                    //  ERROR_ID,
                    //"SetSocketNonBlocking:ioctlsocket(%d,FIONBIO,0) failed: %s(%d)",
                    // pSocket, WSAErrString(ecode), ecode);
                    return -1;
                }
            }
            return 0;
        }

#else /* unix */
        {
            int f = fcntl(pSocket, F_GETFL);

            if (f == -1)
            {
                // TODO LogEvent(ERROR_ID,
                //       "SetSocketNonBlocking: fcntl(%d,F_GETFL) failed: %s(errno=%d)",
                //     pSocket, strerror(errno), errno);

                f |= O_NONBLOCK;
            }
            if (fcntl(pSocket, F_SETFL, f) == -1)
            {
                // TODO LogEvent(ERROR_ID,
                //"SetSocketNonBlocking: fcntl(%d,F_SETFL) failed: %s(errno=%d)",
                // pSocket, strerror(errno), errno);
                return -1;
            }
            return 0;
        }
#endif
    }

    auto protocolOptions(const char *opt) -> long
    {
        long options = SSL_PROTOCOL_NONE, thisopt = 0;
        char action = 0;
        const char *w = nullptr, *e = nullptr;

        if (*opt)
        {
            w = opt;
            e = w + strlen(w);
            while (w && (w < e))
            {
                action = '\0';
                while ((*w == ' ') || (*w == '\t'))
                {
                    w++;
                }
                if (*w == '+' || *w == '-')
                {
                    action = *(w++);
                }

                if (!strncasecmp(w, "SSLv2", 5 /* strlen("SSLv2") */))
                {
                    thisopt = SSL_PROTOCOL_SSLV2;
                    w += 5 /* strlen("SSLv2")*/;
                }
                else if (!strncasecmp(w, "SSLv3", 5 /* strlen("SSLv3") */))
                {
                    thisopt = SSL_PROTOCOL_SSLV3;
                    w += 5 /*strlen("SSLv3") */;
                }
                else if (!strncasecmp(w, "TLSv1_1", 7 /* strlen("TLSv1_1") */))
                {
                    thisopt = SSL_PROTOCOL_TLSV1_1;
                    w += 7 /* strlen("TLSv1_1") */;
                }
                else if (!strncasecmp(w, "TLSv1_2", 7 /* strlen("TLSv1_2") */))
                {
                    thisopt = SSL_PROTOCOL_TLSV1_2;
                    w += 7 /* strlen("TLSv1_2") */;
                }
#if (OPENSSL_VERSION_NUMBER >= 0x1010100FL)
                else if (!strncasecmp(w, "TLSv1_3", 7 /* strlen("TLSv1_3") */))
                {
                    thisopt = SSL_PROTOCOL_TLSV1_3;
                    w += 7 /* strlen("TLSv1_3") */;
                }
#endif
                else if (!strncasecmp(w, "TLSv1", 5 /* strlen("TLSv1") */))
                {
                    thisopt = SSL_PROTOCOL_TLSV1;
                    w += 5 /* strlen("TLSv1") */;
                }
                else if (!strncasecmp(w, "all", 3 /* strlen("all") */))
                {
                    thisopt = SSL_PROTOCOL_ALL;
                    w += 3 /* strlen("all") */;
                }
                else
                {
                    return -1;
                }

                if (action == '-')
                {
                    options &= ~thisopt;
                }
                else if (action == '+')
                {
                    options |= thisopt;
                }
                else
                {
                    options = thisopt;
                }
            }
        }
        else
        { /* default all except SSLv2 */
            options = SSL_PROTOCOL_ALL;
            thisopt = SSL_PROTOCOL_SSLV2;
            options &= ~thisopt;
        }

        return options;
    }

    void setCtxOptions(SSL_CTX *ctx, long options)
    {
        SSL_CTX_set_options(ctx, SSL_OP_ALL);
        if (!(options & SSL_PROTOCOL_SSLV2))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv2);
        }
        if (!(options & SSL_PROTOCOL_SSLV3))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_SSLv3);
        }
        if (!(options & SSL_PROTOCOL_TLSV1))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_TLSv1);
        }
        if (!(options & SSL_PROTOCOL_TLSV1_1))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_TLSv1_1);
        }
        if (!(options & SSL_PROTOCOL_TLSV1_2))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_TLSv1_2);
        }
#if (OPENSSL_VERSION_NUMBER >= 0x1010100FL)
        if (!(options & SSL_PROTOCOL_TLSV1_3))
        {
            SSL_CTX_set_options(ctx, SSL_OP_NO_TLSv1_3);
        }
#endif
    }

    auto enable_DH_ECDH(SSL_CTX *ctx, const char *certFile) -> int
    {
#ifndef OPENSSL_NO_DH
        int no_dhe = 0;
        if (!no_dhe)
        {
            DH *dh = nullptr;

            if (certFile)
            {
                dh = load_dh_param(certFile);
            }

            if (dh != nullptr)
            {
                SSL_CTX_set_tmp_dh(ctx, dh);

                DH_free(dh);
            }
            else
            {
                SSL_CTX_set_tmp_dh_callback(ctx, ssl_callback_TmpDH);
            }
            //(void)BIO_flush(bio_s_out);
        }
#endif

#ifndef OPENSSL_NO_ECDH
        EC_KEY *ecdh = nullptr;
        ecdh = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
        if (ecdh == nullptr)
        {
            return 2;
        }
        SSL_CTX_set_tmp_ecdh(ctx, ecdh);
        EC_KEY_free(ecdh);
#endif

        return 0;
    }

    auto createSSLContext(bool server, const SessionSettings &settings, std::string &errStr) -> SSL_CTX *
    {
        errStr.erase();

        SSL_CTX *ctx = nullptr;

        std::string strOptions;
        if (settings.get().has(SSL_PROTOCOL))
        {
            strOptions = settings.get().getString(SSL_PROTOCOL);
        }

        long options = protocolOptions(strOptions.c_str());

        /* set up the application context */
#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
        if (server)
        {
            ctx = SSL_CTX_new(TLS_server_method());
        }
        else
        {
            ctx = SSL_CTX_new(TLS_client_method());
        }
#else
        if (server)
        {
            ctx = SSL_CTX_new(SSLv23_server_method());
        }
        else
        {
            ctx = SSL_CTX_new(SSLv23_client_method());
        }
#endif

        if (ctx == nullptr)
        {
            errStr.append("Unable to get context");
            return ctx;
        }

        setCtxOptions(ctx, options);

        SSL_CTX_set_options(ctx, SSL_OP_SINGLE_DH_USE);
        if (server)
        {
            SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_SERVER);
        }

        SSL_CTX_set_mode(ctx, SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);

        if (settings.get().has(SSL_CIPHER_SUITE))
        {
            std::string strCipherSuite = settings.get().getString(SSL_CIPHER_SUITE);

            if (!strCipherSuite.empty() && !SSL_CTX_set_cipher_list(ctx, strCipherSuite.c_str()))
            {
                errStr.append("Unable to configure permitted SSL ciphers");
                SSL_CTX_free(ctx);
                return nullptr;
            }
        }

        if (settings.get().has(TLS_CIPHER_SUITES))
        {
            std::string strCipherSuites = settings.get().getString(TLS_CIPHER_SUITES);

#if (OPENSSL_VERSION_NUMBER >= 0x1010100FL)
            if (!strCipherSuites.empty() && !SSL_CTX_set_ciphersuites(ctx, strCipherSuites.c_str()))
            {
                errStr.append("Unable to configure permitted TLS ciphersuites");
                SSL_CTX_free(ctx);
                return nullptr;
            }
#else
            if (!strCipherSuites.empty())
            {
                errStr.append("Unable to configure TLS ciphersuites (OpenSSl < 1.1.1)");
                SSL_CTX_free(ctx);
                return 0;
            }
#endif
        }

        /* Set up SSL keylog callback for Wireshark traffic decryption if enabled */
        if (ssl_is_keylog_enabled())
        {
            SSL_CTX_set_keylog_callback(ctx, ssl_keylog_callback);
        }

        return ctx;
    }

    auto loadSSLCert(
        SSL_CTX *ctx,
        bool server,
        const SessionSettings &settings,
        Log *log,
        passPhraseHandleCallbackType cb,
        void *passwordCallbackParam,
        std::string &errStr) -> bool
    {
        errStr.erase();

        log->onEvent("Loading SSL certificate");

        std::string cert;
        std::string key;

        if (server)
        {
            if (!settings.get().has(SERVER_CERTIFICATE_FILE))
            {
                errStr.assign(SERVER_CERTIFICATE_FILE);
                errStr.append(" parameter not found");
                return false;
            }

            cert.assign(settings.get().getString(SERVER_CERTIFICATE_FILE));

            if (settings.get().has(SERVER_CERTIFICATE_KEY_FILE))
            {
                key.assign(settings.get().getString(SERVER_CERTIFICATE_KEY_FILE));
            }
            else
            {
                key.assign(cert);
            }
        }
        else
        {
            if (!settings.get().has(CLIENT_CERTIFICATE_FILE))
            {
                log->onEvent("No SSL certificate configured for client.");

                int ret = enable_DH_ECDH(ctx, nullptr);
                if (ret != 0)
                {
                    if (ret == 1)
                    {
                        errStr.assign("Could not enable DH");
                    }
                    else if (ret == 2)
                    {
                        errStr.assign("Could not enable ECDH");
                    }
                    else
                    {
                        errStr.assign("Unknown error enabling DH, ECDH");
                    }

                    return false;
                }

                return true;
            }

            cert.assign(settings.get().getString(CLIENT_CERTIFICATE_FILE));

            if (settings.get().has(CLIENT_CERTIFICATE_KEY_FILE))
            {
                key.assign(settings.get().getString(CLIENT_CERTIFICATE_KEY_FILE));
            }
            else
            {
                key.assign(cert);
            }
        }

#if (OPENSSL_VERSION_NUMBER >= 0x10100000L) && !defined(LIBRESSL_VERSION_NUMBER)
        ::SSL_CTX_set_default_passwd_cb_userdata(ctx, passwordCallbackParam);
#else
        ctx->default_passwd_callback_userdata = passwordCallbackParam;
#endif

        SSL_CTX_set_default_passwd_cb(ctx, cb);

        FILE *fp = nullptr;

        if ((fp = fopen(cert.c_str(), "r")) == nullptr)
        {
            errStr.assign(cert);
            errStr.append(" file could not be opened");
            return false;
        }

        X509 *X509Cert = readX509(fp, nullptr, nullptr, nullptr);

        fclose(fp);

        if (X509Cert == nullptr)
        {
            errStr.assign(cert);
            errStr.append(" readX509 failed");
            return false;
        }

        switch (typeofSSLAlgo(X509Cert, nullptr))
        {
        case SSL_ALGO_RSA:
            log->onEvent("Configuring RSA client certificate");

            if (SSL_CTX_use_certificate(ctx, X509Cert) <= 0)
            {
                errStr.assign("Unable to configure RSA client certificate");
                return false;
            }
            break;

        case SSL_ALGO_DSA:
            log->onEvent("Configuring DSA client certificate");
            if (SSL_CTX_use_certificate(ctx, X509Cert) <= 0)
            {
                errStr.assign("Unable to configure DSA client certificate");
                return false;
            }
            break;

        case SSL_ALGO_EC:
            log->onEvent("Configuring EC client certificate");
            if (SSL_CTX_use_certificate(ctx, X509Cert) <= 0)
            {
                errStr.assign("Unable to configure EC client certificate");
                return false;
            }
            break;

        default:
            errStr.assign("Unable to configure client certificate");
            return false;
            break;
        }
        X509_free(X509Cert);

        if ((fp = fopen(key.c_str(), "r")) == nullptr)
        {
            errStr.assign(key);
            errStr.append(" file could not be opened");
            return false;
        }

        EVP_PKEY *privateKey = readPrivateKey(fp, nullptr, cb, passwordCallbackParam);

        fclose(fp);

        if (privateKey == nullptr)
        {
            errStr.assign(key);
            errStr.append(" readPrivateKey failed");
            return false;
        }

        switch (typeofSSLAlgo(nullptr, privateKey))
        {
        case SSL_ALGO_RSA:
            log->onEvent("Configuring RSA client private key");
            if (SSL_CTX_use_PrivateKey(ctx, privateKey) <= 0)
            {
                errStr.assign("Unable to configure RSA server private key");
                return false;
            }
            break;

        case SSL_ALGO_DSA:
            log->onEvent("Configuring DSA client private key");
            if (SSL_CTX_use_PrivateKey(ctx, privateKey) <= 0)
            {
                errStr.assign("Unable to configure DSA server private key");
                return false;
            }
            break;

        case SSL_ALGO_EC:
            log->onEvent("Configuring EC client private key");
            if (SSL_CTX_use_PrivateKey(ctx, privateKey) <= 0)
            {
                errStr.assign("Unable to configure EC server private key");
                return false;
            }
            break;
        default:

            errStr.assign("Unable to configure client certificate");
            return false;
            break;
        }
        EVP_PKEY_free(privateKey);

        /* Now we know that a key and cert have been set against
         * the SSL context */
        if (!SSL_CTX_check_private_key(ctx))
        {
            errStr.assign("Private key does not match the certificate public key");
            return false;
        }

        int ret = enable_DH_ECDH(ctx, cert.c_str());
        if (ret != 0)
        {
            if (ret == 1)
            {
                errStr.assign("Could not enable DH");
            }
            else if (ret == 2)
            {
                errStr.assign("Could not enable ECDH");
            }
            else
            {
                errStr.assign("Unknown error enabling DH, ECDH");
            }

            return false;
        }

        return true;
        ;
    }

    auto loadCAInfo(
        SSL_CTX *ctx,
        bool server,
        const SessionSettings &settings,
        Log *log,
        std::string &errStr,
        int &verifyLevel) -> bool
    {
        errStr.erase();

        log->onEvent("Loading CA info");

        std::string caFile;
        if (settings.get().has(CERTIFICATE_AUTHORITIES_FILE))
        {
            caFile.assign(settings.get().getString(CERTIFICATE_AUTHORITIES_FILE));
        }

        std::string caDir;
        if (settings.get().has(CERTIFICATE_AUTHORITIES_DIRECTORY))
        {
            caDir.assign(settings.get().getString(CERTIFICATE_AUTHORITIES_DIRECTORY));
        }

        if (caFile.empty() && caDir.empty())
        {
            return true;
        }

        if (!SSL_CTX_load_verify_locations(ctx, caFile.empty() ? nullptr : caFile.c_str(), caDir.empty() ? nullptr : caDir.c_str()) || !SSL_CTX_set_default_verify_paths(ctx))
        {
            errStr.assign("Unable to configure verify locations for client authentication");
            return false;
        }

        STACK_OF(X509_NAME) *caList = nullptr;
        if ((caList = findCAList(caFile.empty() ? nullptr : caFile.c_str(), caDir.empty() ? nullptr : caDir.c_str())) == nullptr)
        {
            errStr.assign("Unable to determine list of available CA certificates "
                          "for client authentication");
            return false;
        }
        SSL_CTX_set_client_CA_list(ctx, caList);

        if (server)
        {
            if (settings.get().has(CERTIFICATE_VERIFY_LEVEL))
            {
                verifyLevel = (settings.get().getInt(CERTIFICATE_VERIFY_LEVEL));
            }

            if (verifyLevel != SSL_CLIENT_VERIFY_NOTSET)
            {
                /* configure new state */
                int cVerify = SSL_VERIFY_NONE;
                if (verifyLevel == SSL_CLIENT_VERIFY_REQUIRE)
                {
                    cVerify |= SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
                }
                else if (verifyLevel == SSL_CLIENT_VERIFY_OPTIONAL)
                {
                    cVerify |= SSL_VERIFY_PEER;
                }

                SSL_CTX_set_verify(ctx, cVerify, callbackVerify);
            }
        }
        else
        {
            /* Set the certificate verification callback */
            SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, callbackVerify);
        }

        return true;
    }

    auto loadCRLInfo(SSL_CTX *ctx, const SessionSettings &settings, Log *log, std::string &errStr) -> X509_STORE *
    {
        errStr.erase();

        X509_STORE *revocationStore = nullptr;

        log->onEvent("Loading CRL information");

        errStr.erase();

        std::string crlFile;
        if (settings.get().has(CERTIFICATE_REVOCATION_LIST_FILE))
        {
            crlFile.assign(settings.get().getString(CERTIFICATE_REVOCATION_LIST_FILE));
        }

        std::string crlDir;
        if (settings.get().has(CERTIFICATE_REVOCATION_LIST_DIRECTORY))
        {
            crlDir.assign(settings.get().getString(CERTIFICATE_REVOCATION_LIST_DIRECTORY));
        }

        if (crlFile.empty() && crlDir.empty())
        {
            return revocationStore;
        }

        X509_STORE *store = SSL_CTX_get_cert_store(ctx);
        if (!store || !X509_STORE_load_locations(store, crlFile.c_str(), crlDir.c_str()))
        {
            errStr.assign("Unable to create revocation store");
            return nullptr;
        }
        X509_STORE_set_flags(store, X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL);

        return revocationStore;
    }

    auto doAccept(SSL *ssl, int &result) -> int
    {
        int rc = SSL_accept(ssl);
        if (rc <= 0)
        {
            result = SSL_get_error(ssl, rc);
        }

        return rc;
    }

    auto acceptSSLConnection(socket_handle socket, SSL *ssl, Log *log, int verify) -> int
    {
        int rc = 0;
        int result = -1;
        char *subjName = nullptr;
        time_t timeout = time(nullptr) + 10;
#ifdef __TOS_AIX__
        int retries = 0;
#endif
        /*
         * Now enter the SSL Handshake Phase
         */
        while (!SSL_is_init_finished(ssl))
        {
            ERR_clear_error();
            while ((rc = doAccept(ssl, result)) <= 0)
            {

                if (result == SSL_ERROR_WANT_READ)
                    ;
                else if (result == SSL_ERROR_WANT_WRITE)
                    ;
                else if (result == SSL_ERROR_ZERO_RETURN)
                {
                    /*
                     * The case where the connection was closed before any data
                     * was transferred. That's not a real error and can occur
                     * sporadically with some clients.
                     */
                    if (log)
                    {
                        log->onEvent("SSL handshake stopped: connection was closed");
                    }
                    SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
                    ssl_socket_close(socket, ssl);
                    return result;
                }
                else if (ERR_GET_REASON(ERR_peek_error()) == SSL_R_HTTP_REQUEST)
                {
                    /*
                     * The case where OpenSSL has recognized a HTTP request:
                     * This means the client speaks plain HTTP on our HTTPS
                     * port. Hmmmm...  At least for this error we can be more friendly
                     * and try to provide him with a HTML error page. We have only one
                     * problem: OpenSSL has already read some bytes from the HTTP
                     * request. So we have to skip the request line manually and
                     * instead provide a faked one in order to continue the internal
                     * Apache processing.
                     *
                     */
                    char ca[2];
                    int rv = 0;

                    /* log the situation */
                    if (log)
                    {
                        log->onEvent("SSL handshake failed: HTTP spoken on HTTPS port");
                    }

                    /* first: skip the remaining bytes of the request line */
                    do
                    {
                        do
                        {
                            rv = NS_MICRO_THREAD::mt_read(socket, ca, 1, -1);
                        } while (rv == -1 && errno == EINTR);
                    } while (rv > 0 && ca[0] != '\012' /*LF*/);

                    SSL_set_shutdown(ssl, SSL_SENT_SHUTDOWN | SSL_RECEIVED_SHUTDOWN);
                    ssl_socket_close(socket, ssl);
                    ;
                    return result;
                }
                else if (result == SSL_ERROR_SYSCALL)
                {

                    if (errno == EINTR)
                    {
                        continue;
                    }
                    if (errno > 0)
                    {
                        if (log)
                        {
                            log->onEvent(std::string("SSL handshake interrupted by system, errno ") + IntConvertor::convert(errno));
                        }
                    }
                    else if (log)
                    {
                        log->onEvent("Spurious SSL handshake interrupt");
                    }
                    SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
                    ssl_socket_close(socket, ssl);
                    return result;
                }
                else
                {
                    /*
                     * Ok, anything else is a fatal error
                     */
                    unsigned long err = ERR_get_error();
                    if (log)
                    {
                        log->onEvent("SSL handshake failed");
                    }

                    while (err)
                    {
                        if (log)
                        {
                            log->onEvent(std::string("SSL failure reason: ") + ERR_reason_error_string(err));
                        }
                        err = ERR_get_error();
                    }

                    /*
                     * try to gracefully shutdown the connection:
                     * - send an own shutdown message (be gracefully)
                     * - don't wait for peer's shutdown message (deadloop)
                     * - kick away the SSL stuff immediately
                     */
                    SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
                    ssl_socket_close(socket, ssl);
                    return result;
                }
                if (time(nullptr) > timeout)
                {
                    if (log)
                    {
                        log->onEvent("SSL handshake stopped: connection was closed");
                    }
                    SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
                    ssl_socket_close(socket, ssl);
                    return result;
                }
                mt_swap_thread();
            }

            X509 *xs = nullptr;

            /*
             * Check for failed client authentication
             */
            if ((result = SSL_get_verify_result(ssl)) != X509_V_OK)
            {
                if (log)
                {
                    log->onEvent("SSL client authentication failed: ");
                }
                SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
                ssl_socket_close(socket, ssl);
                return result;
            }
            else
            {
                if ((xs = SSL_get_peer_certificate(ssl)) != nullptr)
                {
                    subjName = X509_NAME_oneline(X509_get_subject_name(xs), nullptr, 0);
                }
            }
        }

        if ((verify == SSL_CLIENT_VERIFY_REQUIRE) && subjName == nullptr)
        {
            if (log)
            {
                log->onEvent("No acceptable peer certificate available");
            }
            SSL_set_shutdown(ssl, SSL_RECEIVED_SHUTDOWN);
            ssl_socket_close(socket, ssl);
            result = 2;
        }

        if (subjName)
        {
            free(subjName);
        }

        return result;
    }
} // namespace FIX
