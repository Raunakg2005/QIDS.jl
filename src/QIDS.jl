"""
    QIDS.jl - Quantum Intrusion Detection System & Quantum Digital Signatures

A high-performance Julia package for post-quantum physical-layer threat detection,
one-time universal hashing (OTUH), and ETSI GS QKD 014 industrial hardware integration.
"""
module QIDS

include("Toeplitz.jl")
include("SPRT.jl")
include("ETSI.jl")

using .Toeplitz
using .SPRT
using .ETSI

export Toeplitz, SPRT, ETSI
export toeplitz_hash, clmul, poly_mod, gf_mul
export SequentialTest, update!, feed!, reset!, SprtState, CONTINUE, ACCEPT_H0, ACCEPT_H1
export ETSI014Client, ETSIKey, ETSIStatus, get_status, get_enc_keys, get_dec_keys, to_bit_list

end # module QIDS
