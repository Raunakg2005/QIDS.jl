module Toeplitz

export clmul, poly_mod, gf_mul, message_chunks, toeplitz_hash, reverse_bits

function _calc_rev_byte(i::Int)::UInt8
    b = UInt8(i)
    rev = UInt8(0)
    for _ in 1:8
        rev = (rev << 1) | (b & 0x01)
        b >>= 1
    end
    return rev
end

const REVERSE_BITS_TABLE = UInt8[_calc_rev_byte(i) for i in 0:255]

"""
    reverse_bits(b::UInt8)::UInt8

Reverse the 8 bits of a single byte.
"""
@inline function reverse_bits(b::UInt8)::UInt8
    return REVERSE_BITS_TABLE[Int(b) + 1]
end

"""
    clmul(a::UInt128, b::UInt128)::UInt128

Carry-less multiplication of two polynomials over GF(2).
"""
function clmul(a::UInt128, b::UInt128)::UInt128
    r = UInt128(0)
    shifted_a = a
    temp_b = b
    while temp_b > 0
        if (temp_b & UInt128(1)) != 0
            r ⊻= shifted_a
        end
        shifted_a <<= 1
        temp_b >>= 1
    end
    return r
end

"""
    poly_mod(v::UInt128, n::Int, p::UInt128)::UInt128

Reduce polynomial `v` modulo degree-`n` polynomial `p` over GF(2).
"""
function poly_mod(v::UInt128, n::Int, p::UInt128)::UInt128
    rem = v
    limit = UInt128(1) << n
    while rem >= limit
        deg = 127 - leading_zeros(rem)
        if deg < n
            break
        end
        rem ⊻= (p << (deg - n))
    end
    return rem
end

"""
    gf_mul(a::UInt128, b::UInt128, n::Int, p::UInt128)::UInt128

Multiply in GF(2^n) modulo irreducible polynomial `p`.
"""
function gf_mul(a::UInt128, b::UInt128, n::Int, p::UInt128)::UInt128
    prod = clmul(a, b)
    return poly_mod(prod, n, p)
end

"""
    message_chunks(data::Vector{UInt8}, n::Int=64)::Vector{UInt128}

Split message bytes into n-bit chunks with injectivity terminator 0x01.
"""
function message_chunks(data::Vector{UInt8}, n::Int=64)::Vector{UInt128}
    width = div(n, 8)
    buf = UInt8[reverse_bits(b) for b in data]
    push!(buf, 0x01) # Injectivity terminator

    while mod(length(buf), width) != 0
        push!(buf, 0x00)
    end

    chunks = UInt128[]
    for i in 1:width:length(buf)
        slice = buf[i:(i + width - 1)]
        val = UInt128(0)
        for (idx, byte) in enumerate(slice)
            val |= UInt128(byte) << (8 * (idx - 1))
        end
        push!(chunks, val)
    end
    return chunks
end

"""
    toeplitz_hash(data::Vector{UInt8}, poly::UInt128, seed::UInt128, n::Int=64)::UInt128

Compute the almost-universal Toeplitz hash of `data`.
"""
function toeplitz_hash(data::Vector{UInt8}, poly::UInt128, seed::UInt128, n::Int=64)::UInt128
    x_n = poly ⊻ (UInt128(1) << n)
    chunks = message_chunks(data, n)
    acc = UInt128(0)

    for chunk in reverse(chunks)
        acc = gf_mul(acc, x_n, n, poly) ⊻ chunk
    end
    return gf_mul(acc, seed, n, poly)
end

end # module Toeplitz
