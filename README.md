# QIDS.jl — Quantum Digital Signatures Julia SDK

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/Raunakg2005/QIDS.jl?label=version)](https://github.com/Raunakg2005/QIDS.jl/releases)

**Official Julia SDK for Quantum Digital Signatures (QDS), ETSI GS QKD 014 Ingestion & Wald SPRT Threat Detection.**

`QIDS.jl` is designed for high-performance quantitative finance, high-frequency settlement, and post-quantum cryptographic analysis in Julia.

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

# 1. Initialize ETSI GS QKD 014 Key Management Entity Client
kms = ETSIClient("https://qkd-kms.internal.net", "bank_node_alpha", "bank_node_beta")

# 2. Ingest carrier-grade quantum key stream
status = get_status(kms)
println("Available Key Slices: $(status.stored_key_count)")

keys = get_enc_keys(kms, 1, 256)
println("Ingested Quantum Key ID: $(keys[1].key_id)")

# 3. Real-Time Sequential Threat Detection (Wald SPRT)
sprt = SPRTDetector(0.01, 0.1111, 1e-4, 1e-4)
update!(sprt, false) # channel observation match
println("Link Security State: $(get_state(sprt))")
```

---

## Capabilities

- **Information-Theoretic Security**: Immunity against quantum computer attacks (Shor's algorithm).
- **Sub-Millisecond Verification**: Zero allocations during hot-path polynomial hashing.
- **ETSI GS QKD 014 Ingestion**: Native HTTP/JSON3 carrier KMS streaming.
- **Auditable & Deterministic**: Zero black-box AI/ML models.

---

## License

Proprietary and Confidential. Copyright (c) 2026 QIDS. All Rights Reserved. See [LICENSE](LICENSE) for details.
