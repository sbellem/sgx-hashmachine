/*

Copyright 2018 Intel Corporation

This software and the related documents are Intel copyrighted materials,
and your use of them is governed by the express license under which they
were provided to you (License). Unless the License provides otherwise,
you may not use, modify, copy, publish, distribute, disclose or transmit
this software or the related documents without Intel's prior written
permission.

This software and the related documents are provided as is, with no
express or implied warranties, other than those that are expressly stated
in the License.

*/

#include <string.h>

#include <sgx_tcrypto.h>
#include <sgx_tkey_exchange.h>
#include <sgx_tseal.h>
#include <sgx_utils.h>

#include "../config.h"
#include "Enclave_t.h"

static const sgx_ec256_public_t def_service_public_key = {
    {0x72, 0x12, 0x8a, 0x7a, 0x17, 0x52, 0x6e, 0xbf, 0x85, 0xd0, 0x3a,
     0x62, 0x37, 0x30, 0xae, 0xad, 0x3e, 0x3d, 0xaa, 0xee, 0x9c, 0x60,
     0x73, 0x1d, 0xb0, 0x5b, 0xe8, 0x62, 0x1c, 0x4b, 0xeb, 0x38},
    {0xd4, 0x81, 0x40, 0xd9, 0x50, 0xe2, 0x57, 0x7b, 0x26, 0xee, 0xb7,
     0x41, 0xe7, 0xc6, 0x14, 0xe2, 0x24, 0xb7, 0xbd, 0xc9, 0x03, 0xf2,
     0x9a, 0x28, 0xa8, 0x3c, 0xc8, 0x10, 0x11, 0x14, 0x5e, 0x06}

};

#define PSE_RETRIES 5 /* Arbitrary. Not too long, not too short. */

/*----------------------------------------------------------------------
 * WARNING
 *----------------------------------------------------------------------
 *
 * End developers should not normally be calling these functions
 * directly when doing remote attestation:
 *
 *    sgx_get_ps_sec_prop()
 *    sgx_get_quote()
 *    sgx_get_quote_size()
 *    sgx_get_report()
 *    sgx_init_quote()
 *
 * These functions short-circuits the RA process in order
 * to generate an enclave quote directly!
 *
 * The high-level functions provided for remote attestation take
 * care of the low-level details of quote generation for you:
 *
 *   sgx_ra_init()
 *   sgx_ra_get_msg1
 *   sgx_ra_proc_msg2
 *
 *----------------------------------------------------------------------
 */

/*
 * This doesn't really need to be a C++ source file, but a bug in
 * 2.1.3 and earlier implementations of the SGX SDK left a stray
 * C++ symbol in libsgx_tkey_exchange.so so it won't link without
 * a C++ compiler. Just making the source C++ was the easiest way
 * to deal with that.
 */

// sgx_status_t sgx_create_report(
//  const sgx_target_info_t *target_info,
//  const sgx_report_data_t *report_data,
//  sgx_report_t *report
// r

// sgx_status_t get_report(sgx_report_t *report, sgx_target_info_t *target_info,
//                        sgx_report_data_t *report_data) {
sgx_status_t get_report(sgx_report_t *report, sgx_target_info_t *target_info) {
#ifdef SGX_HW_SIM
  return sgx_create_report(NULL, NULL, report);
#else
  sgx_report_data_t report_data = {{0}};

  // Hardcoded "Hello World!" string in hexadecimal format
  const uint8_t x[] = {0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20,
                       0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21};
  int iterations = 1000000;
  sgx_status_t sha_ret;
  sgx_sha256_hash_t tmp_hash;
  sha_ret = sgx_sha256_msg(x, sizeof(x), (sgx_sha256_hash_t *)tmp_hash);

  for (int i = 1; i < iterations - 1; i++) {
    sha_ret = sgx_sha256_msg((const uint8_t *)&tmp_hash, sizeof(tmp_hash),
                             (sgx_sha256_hash_t *)tmp_hash);
  }

  sha_ret = sgx_sha256_msg((const uint8_t *)&tmp_hash, sizeof(tmp_hash),
                           (sgx_sha256_hash_t *)&report_data);

  return sgx_create_report(target_info, &report_data, report);
#endif
}

sgx_status_t enclave_ra_init(sgx_ec256_public_t key, int b_pse,
                             sgx_ra_context_t *ctx, sgx_status_t *pse_status) {
  sgx_status_t ra_status;
  ra_status = sgx_ra_init(&key, 0, ctx);
  return ra_status;
}

sgx_status_t enclave_ra_init_def(int b_pse, sgx_ra_context_t *ctx,
                                 sgx_status_t *pse_status) {
  return enclave_ra_init(def_service_public_key, b_pse, ctx, pse_status);
}

/*
 * Return a SHA256 hash of the requested key. KEYS SHOULD NEVER BE
 * SENT OUTSIDE THE ENCLAVE IN PLAIN TEXT. This function let's us
 * get proof of possession of the key without exposing it to untrusted
 * memory.
 */

sgx_status_t enclave_ra_get_key_hash(sgx_status_t *get_keys_ret,
                                     sgx_ra_context_t ctx,
                                     sgx_ra_key_type_t type,
                                     sgx_sha256_hash_t *hash) {
  sgx_status_t sha_ret;
  sgx_ra_key_128_t k;

  // First get the requested key which is one of:
  //  * SGX_RA_KEY_MK
  //  * SGX_RA_KEY_SK
  // per sgx_ra_get_keys().

  *get_keys_ret = sgx_ra_get_keys(ctx, type, &k);
  if (*get_keys_ret != SGX_SUCCESS)
    return *get_keys_ret;

  /* Now generate a SHA hash */

  sha_ret = sgx_sha256_msg((const uint8_t *)&k, sizeof(k),
                           (sgx_sha256_hash_t *)hash); // Sigh.

  /* Let's be thorough */

  memset(k, 0, sizeof(k));

  return sha_ret;
}

/*
 * Return a SHA256 hash of the given message.
 */
sgx_status_t enclave_set_report_data(sgx_report_data_t *report_data) {
  const uint8_t x[] = {0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20,
                       0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21};
  int iterations = 1000000000;
  sgx_status_t sha_ret;
  sgx_sha256_hash_t tmp_hash;
  sha_ret = sgx_sha256_msg(x, sizeof(x), (sgx_sha256_hash_t *)tmp_hash);

  for (int i = 1; i < iterations - 1; i++) {
    sha_ret = sgx_sha256_msg((const uint8_t *)&tmp_hash, sizeof(tmp_hash),
                             (sgx_sha256_hash_t *)tmp_hash);
  }

  sha_ret = sgx_sha256_msg((const uint8_t *)&tmp_hash, sizeof(tmp_hash),
                           (sgx_sha256_hash_t *)report_data);

  // sha_ret = sgx_sha256_msg(x, sizeof(x), (sgx_sha256_hash_t *)report_data);
  // sha_ret = sgx_sha256_msg((const uint8_t *)&report_data,
  // sizeof(report_data),
  //                         (sgx_sha256_hash_t *)report_data);

  return sha_ret;
}

/*
 * Return a SHA256 hash of the given message.
 */
sgx_status_t enclave_ra_get_msg_hash(const uint8_t *msg,
                                     sgx_sha256_hash_t *hash, uint32_t len) {
  sgx_status_t sha_ret;
  sha_ret = sgx_sha256_msg(msg, len, (sgx_sha256_hash_t *)hash);
  return sha_ret;
}

sgx_status_t enclave_ra_close(sgx_ra_context_t ctx) {
  sgx_status_t ret;
  ret = sgx_ra_close(ctx);
  return ret;
}
