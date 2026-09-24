# QIDS.jl

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/Raunakg2005/QIDS.jl?label=version)](https://github.com/Raunakg2005/QIDS.jl/releases)

**Julia primitives for the QIDS quantum digital signature stack: an ETSI GS QKD 014 key-management client, Wald SPRT detection, and Toeplitz universal hashing.**

`QIDS.jl` does not sign documents. Signing and verification happen on a QIDS gateway, whose one-time universal-hash key is what makes a tag unforgeable. For gateway clients, see the Python, TypeScript, Go and Java SDKs.

---

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/Raunakg2005/QIDS.jl.git")
```

---

## Quickstart

```julia
using QIDS

# 1. ETSI GS QKD 014 key-management client
kms = ETSI014Client(ENV["QIDS_KMS_URL"], "bank_node_alpha", "bank_node_beta")

status = get_status(kms)
println("Available keys: $(status.stored_key_count)")

keys = get_enc_keys(kms; number=1, size=256)
println("Key ID: $(keys[1].key_id) ($(keys[1].size_bits) bits)")

# 2. Wald SPRT detector (false = observation matched, true = error)
sprt = SequentialTest(0.01, 0.1111; alpha=1e-4, beta=1e-4)
state = update!(sprt, false)
println("Link state: $(state)")
```

`QIDS_KMS_URL` is your key-management entity's base URL. To try it locally, the `qids` Python package ships a mock: `pip install qids && python -m qids.hardware.etsi_mock_server 8085`, then `QIDS_KMS_URL=http://127.0.0.1:8085`.

---

## What's in the package

- **ETSI GS QKD 014 client**: `ETSI014Client`, `get_status`, `get_enc_keys`, `get_dec_keys`.
- **Wald SPRT**: `SequentialTest`, `update!`, `feed!`, `reset!`, closed-form with no ML.
- **Toeplitz universal hashing**: `toeplitz_hash` over GF(2^n). This is a keyed hash, and it is only as secret as the polynomial and seed you pass it.

---

## License

Proprietary and Confidential. Copyright (c) 2026 QIDS. All Rights Reserved. See [LICENSE](LICENSE) for details.
