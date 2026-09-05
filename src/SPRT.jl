module SPRT

export SprtState, CONTINUE, ACCEPT_H0, ACCEPT_H1, SequentialTest, update!, feed!, reset!

@enum SprtState begin
    CONTINUE = 0
    ACCEPT_H0 = 1
    ACCEPT_H1 = 2
end

mutable struct SequentialTest
    p0::Float64
    p1::Float64
    alpha::Float64
    beta::Float64
    llr::Float64
    n_samples::Int
    n_errors::Int
    state::SprtState
    stopped_at::Int
    log_err_ratio::Float64
    log_ok_ratio::Float64
    upper_bound::Float64
    lower_bound::Float64

    function SequentialTest(p0::Float64, p1::Float64; alpha::Float64=1e-6, beta::Float64=1e-6)
        @assert 0.0 <= p0 < p1 <= 1.0 "Must have 0 <= p0 < p1 <= 1"
        @assert 0.0 < alpha < 1.0 && 0.0 < beta < 1.0 "alpha and beta must be in (0, 1)"

        q0 = max(p0, 1e-6)
        q1 = min(p1, 1.0 - 1e-6)

        log_err = log(q1 / q0)
        log_ok = log((1.0 - q1) / (1.0 - q0))
        upper = log((1.0 - beta) / alpha)
        lower = log(beta / (1.0 - alpha))

        new(p0, p1, alpha, beta, 0.0, 0, 0, CONTINUE, 0, log_err, log_ok, upper, lower)
    end
end

"""
    update!(test::SequentialTest, error::Bool)::SprtState

Feed one observation into the sequential test.
"""
function update!(test::SequentialTest, error::Bool)::SprtState
    if test.state != CONTINUE
        return test.state
    end

    test.n_samples += 1
    if error
        test.n_errors += 1
        test.llr += test.log_err_ratio
    else
        test.llr += test.log_ok_ratio
    end

    if test.llr >= test.upper_bound
        test.state = ACCEPT_H1
        test.stopped_at = test.n_samples
    elseif test.llr <= test.lower_bound
        test.state = ACCEPT_H0
        test.stopped_at = test.n_samples
    end

    return test.state
end

"""
    feed!(test::SequentialTest, errors)::SprtState

Feed an iterable of boolean or integer outcomes into the test.
"""
function feed!(test::SequentialTest, errors)::SprtState
    for err in errors
        res = update!(test, Bool(err))
        if res != CONTINUE
            break
        end
    end
    return test.state
end

"""
    reset!(test::SequentialTest)

Reset test back to uninitialized state.
"""
function reset!(test::SequentialTest)
    test.llr = 0.0
    test.n_samples = 0
    test.n_errors = 0
    test.state = CONTINUE
    test.stopped_at = 0
end

end # module SPRT
