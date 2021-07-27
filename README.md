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

* Optionally, you can install [nix](https://nixos.org/download.html#nix-quick-install).

#### Set Environment Variables
* Edit the `settings` file to add your `SPID`, `IAS_PRIMARY_SUBSCRIPTION_KEY`, and
  `IAS_SECONDARY_SUBSCRIPTION_KEY`. **DO NOT COMMIT changes for this file, as it will
  contain secret data, namely your subscription keys.**

To interact with IAS via Python code, before starting a container, set the two
following environment variables:

* `SGX_SPID` - used to create a quote
* `IAS_PRIMARY_KEY` - used to access Intel's Attestation Service (IAS)

```shell
export SGX_SPID=<your-SPID>
export IAS_PRIMARY_KEY=<your-ias-primary-key>
```

Alternatively, you can place the environment variables in a `.env` file, under
the root of the repository. **NOTE** that the `IAS_PRIMARY_KEY` **MUST** be kept
secret. Consequently, the file `.env` is not tracked by git, as it **MUST NOT** be
uploaded to a public repository, such as on GitHub.

```shell
# .env sample
SGX_SPID=<your-SPID>
IAS_PRIMARY_KEY=<your-ias-primary-key>
```

Build the image, (for the client code):

```shell
$ docker-compose build
```

#### Note about building the enclave
The `Dockerfile`, takes care of building the enclave (`Enclave.signed.so`)
in a reproducible manner using `nix`. For convenience it is done in the docker image,
but it could also be built *just* with `nix`. See the `Dockerfile` for the details on
how to do so.

### Quote Generation
Generate a quote:

```console
$ docker-compose run --rm genquote bash
Creating sgx-hashmachine_genquote_run ... done
root@738d9af342ad:/usr/src/hashmachine# ./run-client -q --debug

MRENCLAVE:      15e1be2fb364d081cf764c25ffd462e07827c75f45877bbcc441a9b3fb240d9c
MRSIGNER:       bd71c6380ef77c5417e8b2d1ce2d4b6504b9f418e5049342440cfff2443d95bd
Report Data:    fceb63059b60138e03a7d6edf6ccb1d942d9165c2812ba926b0fbb0c729eae970000000000000000000000000000000000000000000000000000000000000000

Quote, ready to be sent to IAS (POST /attestation/v4/report):
{
        "isvEnclaveQuote":"AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+iGCTm+uiWguIDMzsdAgH+ACRH//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAABXhvi+zZNCBz3ZMJf/UYuB4J8dfRYd7vMRBqbP7JA2cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD862MFm2ATjgOn1u32zLHZQtkWXCgSupJrD7sMcp6ulwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqAIAAKB1Nv2TiKeveYNGrDKZ4SdpdohudE4koByf5Dk+135Zm6zX5kAEk9pBGhgxnRjAhgPVHZxxkpSo9p/Pxidh/3nK9nUbF/bwHka38IWOwrJacL1f34xJUA5ULiSZtJnFa92szQIuuituXmtmQ96ysq4yoieYPr0L4koMf3d/Mv4CwZMihkiIQyvCE9ipqzNZ2ErKqJW/2ENajJxV/qCqjRiKRPycCFw/10r6j9N5/enhNT+tEp35q8q4/jKGSQjThQhf5Z9TZXDlxKorWEMk6PY3XLeeqakGyZiwHXxm3w6iRplSn3UBCrT274JT2Vh9SoAvkOIZWbS8UnTFloFYxmTHlD41R0d+GYBamAG4xPSKUk9/NDLephFWOVZZft9NZR73fQqvK7IEBic/9WgBAADZ06F8rsxCSL80/ArEV4uJMxMZAj1qD+Y/LjFJyH538y7csUhlQQbpxSyE2zMF5s02IGs/y03z9O9fUpRmUJbErIGCHEchvYUNhSZVVSEovUeOcQH0t2UZetqYNgbxc1zag+dFdnTe/9jMmzesnelRaeS8xrKlnkonzM/P+t3lzip6jsknTP91vJzsNDVFq0zziKLqJ3+nv0w8FFRIjsTDuQE0S/2enI/LTmqHWsqYQHMq9CiKAVVUrt2ScxDhsV67LXAOioWLF82nDoy+GGcd01VVMsc9dqrUKj0xXRh2cx6KEda0lzJSUuFP5F/3qmEvUoYXGRGHmYBd+qROlmRy0TeXgzAOGWgHL3xKE6WjjZZjbe1n7JK6059g5i8xBeUzH4Y0gXhzQIG8lZ4781DXBu8VEFEmBifVxlGHZENWklNNiHcKIrU9pCmhxiVwdVZJuULcpQRjXrxXnHpOIxdWt85nouihclVfzw24O7eOteVwIhFLiKUR",
        "nonce":"bab43d9fcdbef6cf9afc44fc50f184d2"
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
        "isvEnclaveQuote":"AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+iGCTm+uiWguIDMzsdAgH+ACRH//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAABXhvi+zZNCBz3ZMJf/UYuB4J8dfRYd7vMRBqbP7JA2cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD862MFm2ATjgOn1u32zLHZQtkWXCgSupJrD7sMcp6ulwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAqAIAAKB1Nv2TiKeveYNGrDKZ4SdpdohudE4koByf5Dk+135Zm6zX5kAEk9pBGhgxnRjAhgPVHZxxkpSo9p/Pxidh/3nK9nUbF/bwHka38IWOwrJacL1f34xJUA5ULiSZtJnFa92szQIuuituXmtmQ96ysq4yoieYPr0L4koMf3d/Mv4CwZMihkiIQyvCE9ipqzNZ2ErKqJW/2ENajJxV/qCqjRiKRPycCFw/10r6j9N5/enhNT+tEp35q8q4/jKGSQjThQhf5Z9TZXDlxKorWEMk6PY3XLeeqakGyZiwHXxm3w6iRplSn3UBCrT274JT2Vh9SoAvkOIZWbS8UnTFloFYxmTHlD41R0d+GYBamAG4xPSKUk9/NDLephFWOVZZft9NZR73fQqvK7IEBic/9WgBAADZ06F8rsxCSL80/ArEV4uJMxMZAj1qD+Y/LjFJyH538y7csUhlQQbpxSyE2zMF5s02IGs/y03z9O9fUpRmUJbErIGCHEchvYUNhSZVVSEovUeOcQH0t2UZetqYNgbxc1zag+dFdnTe/9jMmzesnelRaeS8xrKlnkonzM/P+t3lzip6jsknTP91vJzsNDVFq0zziKLqJ3+nv0w8FFRIjsTDuQE0S/2enI/LTmqHWsqYQHMq9CiKAVVUrt2ScxDhsV67LXAOioWLF82nDoy+GGcd01VVMsc9dqrUKj0xXRh2cx6KEda0lzJSUuFP5F/3qmEvUoYXGRGHmYBd+qROlmRy0TeXgzAOGWgHL3xKE6WjjZZjbe1n7JK6059g5i8xBeUzH4Y0gXhzQIG8lZ4781DXBu8VEFEmBifVxlGHZENWklNNiHcKIrU9pCmhxiVwdVZJuULcpQRjXrxXnHpOIxdWt85nouihclVfzw24O7eOteVwIhFLiKUR",
        "nonce":"bab43d9fcdbef6cf9afc44fc50f184d2"
}
```

Set the request headers. You need your **unlinkable** subscription key from the
[Intel SGX Attestation Service Utilizing Enhanced Privacy ID (EPID)](https://api.portal.trustedservices.intel.com/).

```python
import os

headers = {
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': os.environ['IAS_PRIMARY_KEY'],
}
```

Using the `requests` library post the quote to IAS:

```python
import requests

url = 'https://api.trustedservices.intel.com/sgx/dev/attestation/v4/report'

res = requests.post(url, json=json, headers=headers)
```

Check the response status:

```ipython
res.ok
```

Check the response body:

```python
>>> res.json()
{'nonce': '7742496c12b3ea3f714b87cb8b25b3a9',
 'id': '54530552470059166105863961431645074139',
 'timestamp': '2021-07-27T02:30:34.925558',
 'version': 4,
 'advisoryURL': 'https://security-center.intel.com',
 'advisoryIDs': ['INTEL-SA-00161',
  'INTEL-SA-00477',
  'INTEL-SA-00381',
  'INTEL-SA-00389',
  'INTEL-SA-00320',
  'INTEL-SA-00329',
  'INTEL-SA-00220',
  'INTEL-SA-00270',
  'INTEL-SA-00293'],
 'isvEnclaveQuoteStatus': 'GROUP_OUT_OF_DATE',
 'platformInfoBlob': '1502006504000F0000111102040101070000000000000000000C00000C000000020000000000000B5B694CA7F64EC0E6C58F53FAFAE9AB30152DBF5B8629856AC638CB7640BD9F7A89A1DB8A40D41279F38AA8F63782875322B52A5CBE26CE6EEB2D6341B0A12BA5AF',
 'isvEnclaveQuoteBody': 'AgAAAFsLAAALAAoAAAAAAFOrdeScwC/lZP1RWReIG+isc7XaonMn21muL3U+DgNyCRL//wECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwAAAAAAAAAHAAAAAAAAAKZAdibMfCjN3/RKXXEKGBAkQjcybmA3z4E7K6+GRwiSAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC9ccY4Dvd8VBfostHOLUtlBLn0GOUEk0JEDP/yRD2VvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmFEL7PY9HCV94hmAKowdZNeFV4n0+Ahg458r2nkv1JgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'}
```

#### Verifying the report authenticity
TODO: check report signature, in response header

The response headers are important as they contain Intel's signature
(`X-IASReport-Signature`) and certificate (`X-IASReport-Signing-Certificate`).

For instance:

```python
>>> res.headers['X-IASReport-Signature']
'jQT5zoWFSNjQy0H0OptqrlLpK59ooZomUCmfp9tt6vMPlgGu0x954KDiJ9AGVhQIp/T0q3PgFE2T7zhTiYZ6oN51T6Ea6q/kR7jc+4GhC0umRL/yeXH0TpiJxFI+Btk2o/+7wSlYaL/BaCK00FsNI9OMZInDyg66KEgQpmuBjQGWtKvQxBHoo6eCHyojZaKcA0rBHsIPjQlsRhsIccPNbmpATp1+VkV7I6vrB/lAwpC4sdUNDpWz99YVOK5olhphINLW7HSaPpp3ShsBk8N2dDOd73h1JciMN7pIDIFd1I5LZGxQ6OMnJujy3JiVLsWUwmcfuXIdYXUAM1YsIU8onA=='
```

```python
>>> from urllib.parse import unquote

>>> unquote(res.headers['X-IASReport-Signing-Certificate'])
'-----BEGIN CERTIFICATE-----\nMIIEoTCCAwmgAwIBAgIJANEHdl0yo7CWMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNV\nBAYTAlVTMQswCQYDVQQIDAJDQTEUMBIGA1UEBwwLU2FudGEgQ2xhcmExGjAYBgNV\nBAoMEUludGVsIENvcnBvcmF0aW9uMTAwLgYDVQQDDCdJbnRlbCBTR1ggQXR0ZXN0\nYXRpb24gUmVwb3J0IFNpZ25pbmcgQ0EwHhcNMTYxMTIyMDkzNjU4WhcNMjYxMTIw\nMDkzNjU4WjB7MQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExFDASBgNVBAcMC1Nh\nbnRhIENsYXJhMRowGAYDVQQKDBFJbnRlbCBDb3Jwb3JhdGlvbjEtMCsGA1UEAwwk\nSW50ZWwgU0dYIEF0dGVzdGF0aW9uIFJlcG9ydCBTaWduaW5nMIIBIjANBgkqhkiG\n9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqXot4OZuphR8nudFrAFiaGxxkgma/Es/BA+t\nbeCTUR106AL1ENcWA4FX3K+E9BBL0/7X5rj5nIgX/R/1ubhkKWw9gfqPG3KeAtId\ncv/uTO1yXv50vqaPvE1CRChvzdS/ZEBqQ5oVvLTPZ3VEicQjlytKgN9cLnxbwtuv\nLUK7eyRPfJW/ksddOzP8VBBniolYnRCD2jrMRZ8nBM2ZWYwnXnwYeOAHV+W9tOhA\nImwRwKF/95yAsVwd21ryHMJBcGH70qLagZ7Ttyt++qO/6+KAXJuKwZqjRlEtSEz8\ngZQeFfVYgcwSfo96oSMAzVr7V0L6HSDLRnpb6xxmbPdqNol4tQIDAQABo4GkMIGh\nMB8GA1UdIwQYMBaAFHhDe3amfrzQr35CN+s1fDuHAVE8MA4GA1UdDwEB/wQEAwIG\nwDAMBgNVHRMBAf8EAjAAMGAGA1UdHwRZMFcwVaBToFGGT2h0dHA6Ly90cnVzdGVk\nc2VydmljZXMuaW50ZWwuY29tL2NvbnRlbnQvQ1JML1NHWC9BdHRlc3RhdGlvblJl\ncG9ydFNpZ25pbmdDQS5jcmwwDQYJKoZIhvcNAQELBQADggGBAGcIthtcK9IVRz4r\nRq+ZKE+7k50/OxUsmW8aavOzKb0iCx07YQ9rzi5nU73tME2yGRLzhSViFs/LpFa9\nlpQL6JL1aQwmDR74TxYGBAIi5f4I5TJoCCEqRHz91kpG6Uvyn2tLmnIdJbPE4vYv\nWLrtXXfFBSSPD4Afn7+3/XUggAlc7oCTizOfbbtOFlYA4g5KcYgS1J2ZAeMQqbUd\nZseZCcaZZZn65tdqee8UXZlDvx0+NdO0LR+5pFy+juM0wWbu59MvzcmTXbjsi7HY\n6zd53Yq5K244fwFHRQ8eOB0IWB+4PfM7FeAApZvlfqlKOlLcZL2uyVmzRkyR5yW7\n2uo9mehX44CiPJ2fse9Y6eQtcfEhMPkmHXI01sN+KwPbpA39+xOsStjhP9N1Y1a2\ntQAVo+yVgLgV2Hws73Fc0o3wC78qPEA+v2aRs/Be3ZFDgDyghc/1fgU+7C+P6kbq\nd4poyb6IW8KCJbxfMJvkordNOgOUUxndPHEi/tb/U7uLjLOgPA==\n-----END CERTIFICATE-----\n-----BEGIN CERTIFICATE-----\nMIIFSzCCA7OgAwIBAgIJANEHdl0yo7CUMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNV\nBAYTAlVTMQswCQYDVQQIDAJDQTEUMBIGA1UEBwwLU2FudGEgQ2xhcmExGjAYBgNV\nBAoMEUludGVsIENvcnBvcmF0aW9uMTAwLgYDVQQDDCdJbnRlbCBTR1ggQXR0ZXN0\nYXRpb24gUmVwb3J0IFNpZ25pbmcgQ0EwIBcNMTYxMTE0MTUzNzMxWhgPMjA0OTEy\nMzEyMzU5NTlaMH4xCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJDQTEUMBIGA1UEBwwL\nU2FudGEgQ2xhcmExGjAYBgNVBAoMEUludGVsIENvcnBvcmF0aW9uMTAwLgYDVQQD\nDCdJbnRlbCBTR1ggQXR0ZXN0YXRpb24gUmVwb3J0IFNpZ25pbmcgQ0EwggGiMA0G\nCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCfPGR+tXc8u1EtJzLA10Feu1Wg+p7e\nLmSRmeaCHbkQ1TF3Nwl3RmpqXkeGzNLd69QUnWovYyVSndEMyYc3sHecGgfinEeh\nrgBJSEdsSJ9FpaFdesjsxqzGRa20PYdnnfWcCTvFoulpbFR4VBuXnnVLVzkUvlXT\nL/TAnd8nIZk0zZkFJ7P5LtePvykkar7LcSQO85wtcQe0R1Raf/sQ6wYKaKmFgCGe\nNpEJUmg4ktal4qgIAxk+QHUxQE42sxViN5mqglB0QJdUot/o9a/V/mMeH8KvOAiQ\nbyinkNndn+Bgk5sSV5DFgF0DffVqmVMblt5p3jPtImzBIH0QQrXJq39AT8cRwP5H\nafuVeLHcDsRp6hol4P+ZFIhu8mmbI1u0hH3W/0C2BuYXB5PC+5izFFh/nP0lc2Lf\n6rELO9LZdnOhpL1ExFOq9H/B8tPQ84T3Sgb4nAifDabNt/zu6MmCGo5U8lwEFtGM\nRoOaX4AS+909x00lYnmtwsDVWv9vBiJCXRsCAwEAAaOByTCBxjBgBgNVHR8EWTBX\nMFWgU6BRhk9odHRwOi8vdHJ1c3RlZHNlcnZpY2VzLmludGVsLmNvbS9jb250ZW50\nL0NSTC9TR1gvQXR0ZXN0YXRpb25SZXBvcnRTaWduaW5nQ0EuY3JsMB0GA1UdDgQW\nBBR4Q3t2pn680K9+QjfrNXw7hwFRPDAfBgNVHSMEGDAWgBR4Q3t2pn680K9+Qjfr\nNXw7hwFRPDAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADANBgkq\nhkiG9w0BAQsFAAOCAYEAeF8tYMXICvQqeXYQITkV2oLJsp6J4JAqJabHWxYJHGir\nIEqucRiJSSx+HjIJEUVaj8E0QjEud6Y5lNmXlcjqRXaCPOqK0eGRz6hi+ripMtPZ\nsFNaBwLQVV905SDjAzDzNIDnrcnXyB4gcDFCvwDFKKgLRjOB/WAqgscDUoGq5ZVi\nzLUzTqiQPmULAQaB9c6Oti6snEFJiCQ67JLyW/E83/frzCmO5Ru6WjU4tmsmy8Ra\nUd4APK0wZTGtfPXU7w+IBdG5Ez0kE1qzxGQaL4gINJ1zMyleDnbuS8UicjJijvqA\n152Sq049ESDz+1rRGc2NVEqh1KaGXmtXvqxXcTB+Ljy5Bw2ke0v8iGngFBPqCTVB\n3op5KBG3RjbF6RRSzwzuWfL7QErNC8WEy5yDVARzTA5+xmBc388v9Dm21HGfcC8O\nDD+gT9sSpssq0ascmvH49MOgjt1yoysLtdCtJW/9FZpoOypaHx0R+mJTLwPXVMrv\nDaVzWh5aiEx+idkSGMnX\n-----END CERTIFICATE-----\n'
```

#### Verifying the MRENCLAVE, and REPORT DATA
Getting the **MRENCLAVE**, **MRSIGNER and **REPORT DATA** out of the report requires
to know the structure of a quote:

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

Extract the report body:

```
import base64

isv_enclave_quote_body = res.json()['isvEnclaveQuoteBody']
report_body = base64.b64decode(isv_enclave_quote_body)[48:432]
```

Check the **MRENCLAVE**:

```ipython
report_body[64:96].hex()    # mrenclave
# a6407626cc7c28cddff44a5d710a1810244237326e6037cf813b2baf86470892
```

Extract the **REPORT DATA**:

```ipython
report_body[320:384].hex()  # report data
# 661442fb3d8f47095f7886600aa3075935e155e27d3e021838e7caf69e4bf5260000000000000000000000000000000000000000000000000000000000000000
```

The sha256 of 'Hello World!', applied 100 million times is supposed to be in
the report data ...

```python
import hashlib

s = b'Hello World!'

# this may take a minute or so
for _ in range(1000000):
    s = hashlib.sha256(s).digest()

report_body[320:384][:32] == s
# True
```
