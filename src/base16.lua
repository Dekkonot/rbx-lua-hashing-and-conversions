local CHAR_SET = {[0] =
    "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "A", "B", "C", "D", "E", "F",
}

local REVERSE_CHAR_SET = {
    [48] = 0, [49] = 1, [50] = 2, [51] = 3, [52] = 4, [53] = 5, [54] = 6, [55] = 7,
    [56] = 8, [57] = 9, [65] = 10, [66] = 11, [67] = 12, [68] = 13, [69] = 14, [70] = 15,
    [97] = 10, [98] = 11, [99] = 12, [100] = 13, [101] = 14, [102] = 15,
}

local function encodeBase16(input)
    local output = {}

    local c = 1
    for i = 1, #input do
        local b = string.byte(input, i)
        output[c] = CHAR_SET[bit32.extract(b, 4, 4)]
        output[c+1] = CHAR_SET[bit32.extract(b, 0, 4)]
        c = c+2
    end

    return table.concat(output)
end

local function decodeBase16(input)
    assert(not (string.find(input, "%X")), "input contains invalid characters")
    assert(#input%2 == 0, "input size must be a multiple of 2")

    local output = {}

    local c = 1
    for i = 1, #input, 2 do
        local b0, b1 = string.byte(input, i, i+1)
        b0 = REVERSE_CHAR_SET[b0]
        b1 = REVERSE_CHAR_SET[b1]
        output[c] = string.char(bit32.lshift(b0, 4)+b1)
        c = c+1
    end

    return table.concat(output)
end

return {
    encode = encodeBase16,
    decode = decodeBase16,
}