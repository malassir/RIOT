/*
 * Copyright (C) 2019 HAW Hamburg
 *
 * This file is subject to the terms and conditions of the GNU Lesser
 * General Public License v2.1. See the file LICENSE in the top level
 * directory for more details.
 */

/**
 * @{
 *
 * @file
 * @brief   tinydtls-specific types and functions definitions
 *
 * @author  Aiman Ismail <muhammadaimanbin.ismail@haw-hamburg.de>
 * @author  Leandro Lanzieri <leandro.lanzieri@haw-hamburg.de>
 */

#ifndef SOCK_DTLS_TYPES_H
#define SOCK_DTLS_TYPES_H

#include "dtls.h"
#include "net/sock/udp.h"
#include "net/credman.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef SOCK_DTLS_MBOX_SIZE
#define SOCK_DTLS_MBOX_SIZE     (4)         /**< Size of DTLS sock mailbox */
#endif

/**
 * @brief Information about DTLS sock
 */
struct sock_dtls {
    dtls_context_t *dtls_ctx;               /**< TinyDTLS context for sock */
    sock_udp_t *udp_sock;                   /**< Underlying UDP sock to use */
    mbox_t mbox;                            /**< Mailbox for internal event
                                                handling */
    msg_t mbox_queue[SOCK_DTLS_MBOX_SIZE];  /**< Queue for struct
                                                sock_dtls::mbox */
    uint8_t *buf;                           /**< Buffer to pass decrypted data
                                                back to user */
    size_t buflen;                          /**< Size of buffer */
    credman_tag_t tag;                      /**< Credential tag of a registered
                                                (D)TLS credential */
    dtls_peer_type role;                    /**< DTLS role of the socket */
};

/**
 * @brief Information about remote client connected to the server
 */
struct sock_dtls_session {
    sock_udp_ep_t   ep;              /**< Remote endpoint the session
                                         is connected to */
    session_t       dtls_session;    /**< TinyDTLS session */
};

#ifdef __cplusplus
}
#endif

#endif /* SOCK_DTLS_TYPES_H */
/** @} */
