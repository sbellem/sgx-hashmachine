# Demo

```shell
docker-compose run --rm genquote bash
```

## Generate quote

```shell
./run-client -q --debug
```

Copy quote

## Sending the quote to IAS

```shell
ipython
```

Set request body:

```python
json = {"... copied quote ..."}
```

Set request headers:

```python
import os

headers = {
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': os.environ['IAS_PRIMARY_KEY'],
}
```

Send the quote to Intel:

```python
import requests

url = 'https://api.trustedservices.intel.com/sgx/dev/attestation/v4/report'

res = requests.post(url, json=json, headers=headers)
```

Check the response status:

```ipython
res.ok
```

Display response:

```ipython
res.json()
```

Extract report body:

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

Let's "re-do" the computation, to verify the result:

```ipython
import hashlib

s = b'Hello World!'

# this may take a minute or so
for _ in range(1000000):
    s = hashlib.sha256(s).digest()

report_body[320:384][:32] == s
# True
```
