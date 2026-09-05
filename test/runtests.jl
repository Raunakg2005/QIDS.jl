using Test
include("../src/QIDS.jl")
using .QIDS

@testset "QIDS.jl Comprehensive Test Suite" begin

    @testset "Toeplitz Universal Hashing" begin
        # Test carryless multiplication over GF(2)
        # 3 * 3 = 0b11 * 0b11 = 0b101 = 5
        @test clmul(UInt128(3), UInt128(3)) == UInt128(5)

        # Modulo irreducible polynomial x^3 + x + 1 (11)
        @test poly_mod(UInt128(5), 3, UInt128(11)) == UInt128(5)
        @test poly_mod(UInt128(8), 3, UInt128(11)) == UInt128(3)

        # Test hash determinism on payload
        payload = Vector{UInt8}("FINANCIAL_LEDGER_TRANSFER_TX9982")
        poly = (UInt128(1) << 64) | UInt128(0b11011)
        seed = UInt128(0xCAFEF00D12345678)

        h1 = toeplitz_hash(payload, poly, seed, 64)
        h2 = toeplitz_hash(payload, poly, seed, 64)
        @test h1 == h2
        @test h1 != 0

        # Different payload yields distinct hash (almost-universal property)
        alt_payload = Vector{UInt8}("FINANCIAL_LEDGER_TRANSFER_TX9983")
        h_alt = toeplitz_hash(alt_payload, poly, seed, 64)
        @test h1 != h_alt
    end

    @testset "Wald SPRT Real-Time Threat Detection" begin
        # Honest rate 2%, attack rate 25% (Intercept-Resend)
        test = SequentialTest(0.02, 0.25; alpha=1e-4, beta=1e-4)

        # Feed attack stream (1 error every 4 bits)
        attack_noise = [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false]
        state = feed!(test, attack_noise)
        @test state == ACCEPT_H1
        @test test.stopped_at <= length(attack_noise)

        # Clean honest stream accepts H0
        clean_test = SequentialTest(0.02, 0.25; alpha=1e-4, beta=1e-4)
        honest_stream = fill(false, 40)
        clean_state = feed!(clean_test, honest_stream)
        @test clean_state == ACCEPT_H0
    end

    @testset "ETSI Key Bit Integrity" begin
        raw_bytes = UInt8[0b10101010, 0b11000011]
        key = ETSIKey("key-uuid-1", raw_bytes, 16)
        bits = to_bit_list(key)
        @test length(bits) == 16
        @test bits == [1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1]
    end

end
