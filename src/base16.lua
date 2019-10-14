local function encodeBase16(input)
    local output = {}

    for i = 1, #input do
        output[i] = string.format("%02x", string.byte(input, i))
    end

    return table.concat(output)
end

local function decodeBase16(input)
    assert(not (string.find(input, "%X")), "input contains invalid characters")
    assert(#input%2 == 0, "input size must be a multiple of 2")

    local output = {}

    local c = 1
    for i = 1, #input, 2 do
        local byte = tonumber(string.sub(input, i, i+1), 16)
        output[c] = string.char(byte)
        c = c+1
    end

    return table.concat(output)
end

return {
    encode = encodeBase16,
    decode = decodeBase16,
}