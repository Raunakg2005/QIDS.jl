module ETSI

# Plain imports, not the old try/import guard: that guard also imported
# Base64, which Project.toml did not declare, so under package loading the
# import failed, the guard went false, and every ETSI call errored with
# "HTTP.jl and JSON3.jl are required" even with both installed.
import HTTP
import JSON3
using Base64: base64decode

export ETSIKey, ETSIStatus, ETSI014Client, get_status, get_enc_keys, get_dec_keys, to_bit_list

struct ETSIKey
    key_id::String
    key_bytes::Vector{UInt8}
    size_bits::Int
end

function to_bit_list(key::ETSIKey)::Vector{Int}
    bits = Int[]
    for byte in key.key_bytes
        for shift in 7:-1:0
            push!(bits, Int((byte >> shift) & 0x01))
        end
    end
    return bits[1:min(length(bits), key.size_bits)]
end

struct ETSIStatus
    source_kme_id::String
    destination_kme_id::String
    source_sae_id::String
    destination_sae_id::String
    key_size::Int
    stored_key_count::Int
    max_key_count::Int
    max_key_per_request::Int
    max_key_size::Int
    min_key_size::Int
end

struct ETSI014Client
    base_url::String
    source_sae_id::String
    destination_sae_id::String
    timeout::Float64

    function ETSI014Client(base_url::String, source::String, dest::String; timeout::Float64=10.0)
        clean_url = endswith(base_url, "/") ? base_url[1:end-1] : base_url
        new(clean_url, source, dest, timeout)
    end
end


function get_status(client::ETSI014Client)::ETSIStatus
    url = "$(client.base_url)/api/v1/keys/$(client.destination_sae_id)/status"
    resp = HTTP.get(url; headers=["Accept" => "application/json"], connect_timeout=client.timeout)
    data = JSON3.read(resp.body)

    return ETSIStatus(
        get(data, :source_KME_ID, ""),
        get(data, :destination_KME_ID, ""),
        get(data, :source_SAE_ID, client.source_sae_id),
        get(data, :destination_SAE_ID, client.destination_sae_id),
        Int(get(data, :key_size, 256)),
        Int(get(data, :stored_key_count, 0)),
        Int(get(data, :max_key_count, 0)),
        Int(get(data, :max_key_per_request, 128)),
        Int(get(data, :max_key_size, 1024)),
        Int(get(data, :min_key_size, 64))
    )
end

function get_enc_keys(client::ETSI014Client; number::Int=1, size::Int=256)::Vector{ETSIKey}
    url = "$(client.base_url)/api/v1/keys/$(client.destination_sae_id)/enc_keys"
    payload = JSON3.write(Dict("number" => number, "size" => size))
    resp = HTTP.post(url, ["Content-Type" => "application/json", "Accept" => "application/json"], payload)
    data = JSON3.read(resp.body)

    keys = ETSIKey[]
    for item in data[:keys]
        kid = string(item[:key_ID])
        key_val = string(item[:key])
        raw_bytes = try
            base64decode(key_val)
        catch
            hex2bytes(key_val)
        end
        push!(keys, ETSIKey(kid, raw_bytes, size))
    end
    return keys
end

function get_dec_keys(client::ETSI014Client, key_ids::Vector{String})::Vector{ETSIKey}
    url = "$(client.base_url)/api/v1/keys/$(client.destination_sae_id)/dec_keys"
    req_body = Dict("key_IDs" => [Dict("key_ID" => kid) for kid in key_ids])
    resp = HTTP.post(url, ["Content-Type" => "application/json", "Accept" => "application/json"], JSON3.write(req_body))
    data = JSON3.read(resp.body)

    keys = ETSIKey[]
    for item in data[:keys]
        kid = string(item[:key_ID])
        key_val = string(item[:key])
        raw_bytes = try
            base64decode(key_val)
        catch
            hex2bytes(key_val)
        end
        push!(keys, ETSIKey(kid, raw_bytes, length(raw_bytes) * 8))
    end
    return keys
end

end # module ETSI
