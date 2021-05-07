**NOTE**: Experimental work-in-progress repository based on Intel's original
[sgx-ra-sample](https://github.com/intel/sgx-ra-sample) repository. The goal is to
provide a minimal client example that only requests a quote from an enclave. The server
component that communicates with Intel's attestation service has been removed.

# Intel&reg; SGX Quote Generation Sample

<!--
* [Introduction](#intro)
* [What's New](#new)
* [License](#license)
* [Building](#build)
  * [Linux*](#build-linux)
    * [Linux build notes](#build-linux-notes)
* [Running (Quick-start)](#running-quick)
* [Running (Advanced)](#running-adv)
* [Sample Output](#output)

## <a name="intro"></a>Introduction
-->
This code sample demonstrates a simple client requesting a quote from an enclave. Upon
receiving the quote from the enclave, the client dumps it to the terminal. It could be
sent to Intel's Attestation Service (IAS) by another component.

A docker-compose based development environment is provided, and is the recommended way
to try this sample, as it has not been tested on other platforms. See the Quickstart
section just below to see how to try it.

## <a name="quickstart"></a>Quickstart
### Prerequisites
* You need [docker](https://docs.docker.com/engine/install/) and
  [docker-compose](https://docs.docker.com/compose/install/).

* The docker-based development environment assumes it is running on an SGX-enabled
  processor. If you are not sure whether your computer supports SGX, and/or how to
  enable it, see https://github.com/ayeks/SGX-hardware#test-sgx.

* Obtain an **Unlinkable** subscription key for the
  [Intel SGX Attestation Service Utilizing Enhanced Privacy ID (EPID)](https://api.portal.trustedservices.intel.com/).

* Edit the `settings` file to add your `SPID`, `IAS_PRIMARY_SUBSCRIPTION_KEY`, and
  `IAS_SECONDARY_SUBSCRIPTION_KEY`. **DO NOT COMMIT changes for this file, as it will
  contain secret data, namely your subscription keys.**

Build the image, (for the client code):

```shell
$ docker-compose build
```

Build the `Enclave.signed.so` file in a reproducible manner using `nix`
and `docker`:

```shell
DOCKER_BUILDKIT=1 docker build --file nix.Dockerfile --target export-stage --output type=local,dest=out .
```

The `Enclave.signed.so` file will be under the `out/` directory, and is mounted
into a container when generating a quote, in the next step.


### Quote Generation
Generate a quote:

```console
$ docker-compose run --rm genquote bash
Creating sgx-hashmachine_genquote_run ... done
root@738d9af342ad:/usr/src/hashmachine# ./run-client -q --debug

MRENCLAVE:      46eba17f7432c6939e58f7fd47130a8ec5ef87eb270bac0a641a5c66b36e6231
MRSIGNER:       bd71c6380ef77c5417e8b2d1ce2d4b6504b9f418e5049342440cfff2443d95bd
Report Data:    fceb63059b60138e03a7d6edf6ccb1d942d9165c2812ba926b0fbb0c729eae970000000000000000000000000000000000000000000000000000000000000000

Quote, ready to be sent to IAS (POST /attestation/v4/report):
{
        "isvEnclaveQuote":"AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+ghPzV3ts4iaavlsWN5RmE5CRH//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAAEbroX90MsaTnlj3/UcTCo7F74frJwusCmQaXGazbmIxAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD862MFm2ATjgOn1u32zLHZQtkWXCgSupJrD7sMcp6ulwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqAIAACqmMEf1EVs4Ey/+MJ4TGQ976ATc8Jgrna1VYknhyOpVxUMr0C8LUDrVc7pt2w6S+DJvpP6sGj0znO7R2A5iIcKpmZh1yClmt7XrH/EmgeYtEy9yHrPDeFXuh9EJEPNqskEM4CQyLxINeN4xiSpCm39bZi9MCfQebGg6T/Eo4ugZCvQW30INsgAlwt31tgAbLEYbSwRg35Jcwc82hJCTjFO3wyIZdNzhkcHEGCutKxboDIj0UURJXfJSo2zknHGpM0iAEdsLUyQ7MI/34enQl5qCbt2j/ER5nOWOQYgvT7Jt+H0h6pOlnKHa+8J/eb3HUmmAX/wLXhepkTHg3bVTZP/K8dutXPuEKO64BLLR/ZZvs2yRBOf5yYGYx4VEpUiQNmF0VMgaaXZ6zkpPm2gBAABiEwU6INLwLrgB2K1MJL+6uSGDR55AOBJG6tpx4eyS3+jpkbqQm5mhu1g/Rez1d3SOxNbvHfpYHk7cptpd7EsgNZnDlj6JrTKF1NVBiLCtnKpVGWRloi7FfOTIrUQFrUoEb0ClL29VHbjvdqaidrpmiNRzfQtX80pRK5lFNDaUo00bfCZ02jF7sIMcPUGUl3JCKKLNnfMB2RHwwXxR4vrO+uPXsxMYa5SGVNJEKexJDQ/+oAk9NuDp5h+si3eKofxS1TAtTZ1Ru4KYYVN0godsKzsDWnAywXaPUcbNbefZJ3tKkgFDe0bF7nfQN81WkE7lX7ZyztXch1fjVjoANj8x/UKvqQEGMCkIasNnl1DF9AJN0Y2Zegq4QFdYqk0iK+F+g1/O2EuZ6YAXKEPvtsjsdlcTh3APF4aocmFnz7uVyjdQLNBqf5eTuOk1zA6G+OA5R2uKDBmJ2bx9rMH3KAEDvjAekvN+oEsgVmKkcBOIBZ7ffBlnwcMC",
        "nonce":"bab8b09dfc7550035e5ed5beb2e6c245"
}

See https://api.trustedservices.intel.com/documents/sgx-attestation-api-spec.pdf
```

In the above output, the `MRENCLAVE`, `MRSIGNER` and report data of the quote are shown,
in hexadecimal format. The first 32 bytes of the report data are the sha256 of the
string 'Hello World!'. This is currently hardcoded in the enclave code just as an
example of using the report data field with custom data.

The quote is printed out in a json-like format, which is ready to be sent to IAS for
verification. The API specifications for IAS is documented at
https://api.trustedservices.intel.com/documents/sgx-attestation-api-spec.pdf.

### Sending the quote to IAS
Here's a simple example of sending out the quote to IAS for verification using Python's
`requests` library:

Continuing from the above container session, start an `ipython` session

```console
root@738d9af342ad:/usr/src/hashmachine# ipython
```

Copy-paste the quote json body:

```ipython
json = {
        "isvEnclaveQuote":"AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+ghPzV3ts4iaavlsWN5RmE5CRH//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAAEbroX90MsaTnlj3/UcTCo7F74frJwusCmQaXGazbmIxAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD862MFm2ATjgOn1u32zLHZQtkWXCgSupJrD7sMcp6ulwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqAIAACqmMEf1EVs4Ey/+MJ4TGQ976ATc8Jgrna1VYknhyOpVxUMr0C8LUDrVc7pt2w6S+DJvpP6sGj0znO7R2A5iIcKpmZh1yClmt7XrH/EmgeYtEy9yHrPDeFXuh9EJEPNqskEM4CQyLxINeN4xiSpCm39bZi9MCfQebGg6T/Eo4ugZCvQW30INsgAlwt31tgAbLEYbSwRg35Jcwc82hJCTjFO3wyIZdNzhkcHEGCutKxboDIj0UURJXfJSo2zknHGpM0iAEdsLUyQ7MI/34enQl5qCbt2j/ER5nOWOQYgvT7Jt+H0h6pOlnKHa+8J/eb3HUmmAX/wLXhepkTHg3bVTZP/K8dutXPuEKO64BLLR/ZZvs2yRBOf5yYGYx4VEpUiQNmF0VMgaaXZ6zkpPm2gBAABiEwU6INLwLrgB2K1MJL+6uSGDR55AOBJG6tpx4eyS3+jpkbqQm5mhu1g/Rez1d3SOxNbvHfpYHk7cptpd7EsgNZnDlj6JrTKF1NVBiLCtnKpVGWRloi7FfOTIrUQFrUoEb0ClL29VHbjvdqaidrpmiNRzfQtX80pRK5lFNDaUo00bfCZ02jF7sIMcPUGUl3JCKKLNnfMB2RHwwXxR4vrO+uPXsxMYa5SGVNJEKexJDQ/+oAk9NuDp5h+si3eKofxS1TAtTZ1Ru4KYYVN0godsKzsDWnAywXaPUcbNbefZJ3tKkgFDe0bF7nfQN81WkE7lX7ZyztXch1fjVjoANj8x/UKvqQEGMCkIasNnl1DF9AJN0Y2Zegq4QFdYqk0iK+F+g1/O2EuZ6YAXKEPvtsjsdlcTh3APF4aocmFnz7uVyjdQLNBqf5eTuOk1zA6G+OA5R2uKDBmJ2bx9rMH3KAEDvjAekvN+oEsgVmKkcBOIBZ7ffBlnwcMC",
        "nonce":"bab8b09dfc7550035e5ed5beb2e6c245"
}
```

Set the request headers. You need your **unlinkable** subscription key from the
[Intel SGX Attestation Service Utilizing Enhanced Privacy ID (EPID)](https://api.portal.trustedservices.intel.com/).

```python
headers = {
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': 'your-ias-primary-subscription-key',
}
```

Using the `requests` library post the quote to IAS:

```python
import requests

url = 'https://api.trustedservices.intel.com/sgx/dev/attestation/v4/report'

res = requests.post(url, json=json, headers=headers)
```

Check `res.ok` to be sure it worked, and if it did the json response can be viewed:

```python
>>> res.json()
{'nonce': 'bab8b09dfc7550035e5ed5beb2e6c245',
 'id': '5527860830771743068604276656887133438',
 'timestamp': '2021-05-07T05:20:40.170261',
 'version': 4,
 'advisoryURL': 'https://security-center.intel.com',
 'advisoryIDs': ['INTEL-SA-00161',
  'INTEL-SA-00381',
  'INTEL-SA-00389',
  'INTEL-SA-00320',
  'INTEL-SA-00329',
  'INTEL-SA-00220',
  'INTEL-SA-00270',
  'INTEL-SA-00293'],
 'isvEnclaveQuoteStatus': 'GROUP_OUT_OF_DATE',
 'platformInfoBlob': '150200650400090000111102040101070000000000000000000B00000B000000020000000000000B5BC4AF80711B8C27E9DB99FFA60C63B9342020F297FB2531EA810D367F80D22C91F5B24F1D2CFBA1536E498D149D0153DBEC90698A7F7D9C6C9CA753EAD9616A88',
 'isvEnclaveQuoteBody': 'AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+ghPzV3ts4iaavlsWN5RmE5CRH//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAAEbroX90MsaTnlj3/UcTCo7F74frJwusCmQaXGazbmIxAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD862MFm2ATjgOn1u32zLHZQtkWXCgSupJrD7sMcp6ulwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'}
```

#### Verifying the report authenticity
TODO: check report signature, in response header

The response headers are important as they contain Intel's signature
(`X-IASReport-Signature`) and certificate (`X-IASReport-Signing-Certificate`).

For instance:

```python
>>> res.headers['X-IASReport-Signature']
'EqZR1HcmqkuRwYgQ6t0BgT/nUkjBW5oKvoSAgs/kuywC3RJajXL3ZUo2AoXf4fxhJBYxxK2/bw19TjVGb5yec9mX0hrzBxucBPJGkWb5xDzBViYfmzSnlVsXy29wT0u1AnZ394E1LQG3oqHy66N85R3e9NyknOAitFzDs3689PlmLJIPQxF1Kc/V8coJXR21seTS1rDD7MUychGnNOe2en0dCpml6gJeU5/8+7Nd8aEOo1SR0OGJ+Tjqx31k1+ht77RI9wGbV6mDBFaREntJ1GjCKw+dRfmcpa27F6Ebtzjbn4f8eo/7BSIUBd1Ofa3naHsfw24aQe4SJ+mQA7NeLA=='
```

```python
>>> from urllib.parse import unquote

>>> unquote(res.headers['X-IASReport-Signing-Certificate'])
'-----BEGIN CERTIFICATE-----\nMIIEoTCCAwmgAwIBAgIJANEHdl0yo7CWMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNV ... U7uLjLOgPA==\n-----END CERTIFICATE-----\n-----BEGIN CERTIFICATE-----\nMIIFSzCCA7OgAwIBAgIJANEHdl0yo7CUMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNV ... \nDaVzWh5aiEx+idkSGMnX\n-----END CERTIFICATE-----\n'
```

#### Verifying the MRENCLAVE, and report data
Getting the MRENCLAVE, MRSIGNER and report data out of the report requires to know
the structure of a quote:

```C
typedef struct _quote_t
{
    uint16_t            version;        /* 0   */
    uint16_t            sign_type;      /* 2   */
    sgx_epid_group_id_t epid_group_id;  /* 4   */
    sgx_isv_svn_t       qe_svn;         /* 8   */
    sgx_isv_svn_t       pce_svn;        /* 10  */
    uint32_t            xeid;           /* 12  */
    sgx_basename_t      basename;       /* 16  */
    sgx_report_body_t   report_body;    /* 48  */
    uint32_t            signature_len;  /* 432 */
    uint8_t             signature[];    /* 436 */
} sgx_quote_t;
```

The report body is the structure that contains the MRENCLAVE:

```C
typedef struct _report_body_t
{
    sgx_cpu_svn_t           cpu_svn;        /* (  0) Security Version of the CPU */
    sgx_misc_select_t       misc_select;    /* ( 16) Which fields defined in SSA.MISC */
    uint8_t                 reserved1[SGX_REPORT_BODY_RESERVED1_BYTES];  /* ( 20) */
    sgx_isvext_prod_id_t    isv_ext_prod_id;/* ( 32) ISV assigned Extended Product ID */
    sgx_attributes_t        attributes;     /* ( 48) Any special Capabilities the Enclave possess */
    sgx_measurement_t       mr_enclave;     /* ( 64) The value of the enclave's ENCLAVE measurement */
    uint8_t                 reserved2[SGX_REPORT_BODY_RESERVED2_BYTES];  /* ( 96) */
    sgx_measurement_t       mr_signer;      /* (128) The value of the enclave's SIGNER measurement */
    uint8_t                 reserved3[SGX_REPORT_BODY_RESERVED3_BYTES];  /* (160) */
    sgx_config_id_t         config_id;      /* (192) CONFIGID */
    sgx_prod_id_t           isv_prod_id;    /* (256) Product ID of the Enclave */
    sgx_isv_svn_t           isv_svn;        /* (258) Security Version of the Enclave */
    sgx_config_svn_t        config_svn;     /* (260) CONFIGSVN */
    uint8_t                 reserved4[SGX_REPORT_BODY_RESERVED4_BYTES];  /* (262) */
    sgx_isvfamily_id_t      isv_family_id;  /* (304) ISV assigned Family ID */
    sgx_report_data_t       report_data;    /* (320) Data provided by the user */
} sgx_report_body_t;
```

```python
import base64

isv_enclave_quote_body = res.json()['isvEnclaveQuoteBody']
report_body = base64.b64decode(isv_enclave_quote_body)[48:432]

report_body[64:96].hex()    # mrenclave
# 46eba17f7432c6939e58f7fd47130a8ec5ef87eb270bac0a641a5c66b36e6231 

report_body[320:384].hex()  # report data
# fceb63059b60138e03a7d6edf6ccb1d942d9165c2812ba926b0fbb0c729eae970000000000000000000000000000000000000000000000000000000000000000
```

The sha256 of 'Hello World!', applied 100 million times is supposed to be in
the report data ...

```python
import hashlib

s = b'Hello World!'

# this may take a minute or so
for _ in range(100000000):
    s = hashlib.sha256(s).digest()

report_body[320:384][:32] == s
# True
```
