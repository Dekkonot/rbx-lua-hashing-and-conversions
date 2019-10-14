local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

-- Not Ascii85, as Z85 is safer
-- https://rfc.zeromq.org/spec:32/Z85/
local CHAR_SET = { [0] =
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g",
    "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
    "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
    "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", ".", "-", ":", "+", "=", "^",
    "!", "/", "*", "?", "&", "<", ">", "(", ")", "[", "]", "{", "}", "@", "%", "$", "#",
}

local INVERSE_CHAR_SET = {
    [48] = 0, [49] = 1, [50] = 2, [51] = 3, [52] = 4, [53] = 5, [54] = 6, [55] = 7, [56] = 8, [57] = 9, [97] = 10,
    [98] = 11, [99] = 12, [100] = 13, [101] = 14, [102] = 15, [103] = 16, [104] = 17, [105] = 18, [106] = 19, [107] = 20,
    [108] = 21, [109] = 22, [110] = 23, [111] = 24, [112] = 25, [113] = 26, [114] = 27, [115] = 28, [116] = 29, [117] = 30,
    [118] = 31, [119] = 32, [120] = 33, [121] = 34, [122] = 35, [65] = 36, [66] = 37, [67] = 38, [68] = 39, [69] = 40,
    [70] = 41, [71] = 42, [72] = 43, [73] = 44, [74] = 45, [75] = 46, [76] = 47, [77] = 48, [78] = 49, [79] = 50,
    [80] = 51, [81] = 52, [82] = 53, [83] = 54, [84] = 55, [85] = 56, [86] = 57, [87] = 58, [88] = 59, [89] = 60,
    [90] = 61, [46] = 62, [45] = 63, [58] = 64, [43] = 65, [61] = 66, [94] = 67, [33] = 68, [47] = 69, [42] = 70,
    [63] = 71, [38] = 72, [60] = 73, [62] = 74, [40] = 75, [41] = 76, [91] = 77, [93] = 78, [123] = 79, [125] = 80,
    [64] = 81, [37] = 82, [36] = 83, [35] = 84,
}

---Packs four 8-bit integers into one 32-bit integer
local function packUint32(a, b, c, d)
    return bit32.lshift(a, 24)+bit32.lshift(b, 16)+bit32.lshift(c, 8)+d
end

---Unpacks one 32-bit integer into four 8-bit integers
local function unpackUint32(int)
    return bit32.extract(int, 24, 8), bit32.extract(int, 16, 8),
           bit32.extract(int, 08, 8), bit32.extract(int, 00, 8)
end

local function encodeBase85(input)
    assert(#input%4 == 0, "input length must be multiple of 4")
    local output = {}

    local c = 1
    for i = 1, #input, 4 do
        local packed = packUint32(string.byte(input, i, i+3))
        local b0 = packed%85
        packed = math.floor(packed/85)
        local b1 = packed%85
        packed = math.floor(packed/85)
        local b2 = packed%85
        packed = math.floor(packed/85)
        local b3 = packed%85
        packed = math.floor(packed/85)
        local b4 = packed%85
        output[c] = CHAR_SET[b4]
        output[c+1] = CHAR_SET[b3]
        output[c+2] = CHAR_SET[b2]
        output[c+3] = CHAR_SET[b1]
        output[c+4] = CHAR_SET[b0]
        c = c+5
    end
    return table.concat(output)
end

local function decodeBase85(input)
    assert(#input%5 == 0, "input length must be multiple of 5")
    local output = {}

    local c = 1
    for i = 1, #input, 5 do
        local packed = 0
        packed = INVERSE_CHAR_SET[string.byte(input, i)]
        packed = packed*85+INVERSE_CHAR_SET[string.byte(input, i+1)]
        packed = packed*85+INVERSE_CHAR_SET[string.byte(input, i+2)]
        packed = packed*85+INVERSE_CHAR_SET[string.byte(input, i+3)]
        packed = packed*85+INVERSE_CHAR_SET[string.byte(input, i+4)]

        local b1, b2, b3, b4 = unpackUint32(packed)
        output[c] = string.char(b1)
        output[c+1] = string.char(b2)
        output[c+2] = string.char(b3)
        output[c+3] = string.char(b4)
        c = c+4
    end

    return table.concat(output)
end

if ASSERTIONS_ENABLED then
    local t = tick()

    assert(packUint32(255, 167, 125, 235) == 4289166827, "(Base85) packUint32 check 1")
    assert(packUint32(255, 0, 125, 235) == 4278222315, "(Base85) packUint32 check 2")

    local b0, b1, b2, b3 = unpackUint32(4278222315)
    assert(b0 == 255, "(Base85) unpackUint32 check 1")
    assert(b1 == 000, "(Base85) unpackUint32 check 2")
    assert(b2 == 125, "(Base85) unpackUint32 check 3")
    assert(b3 == 235, "(Base85) unpackUint32 check 4")

    assert(encodeBase85("\134\79\210\111\181\89\247\91") == "HelloWorld", "(Base85) \\134\\79\\210\\111\\181\\89\\247\\91 binary string failed to encode into HelloWorld")
    assert(encodeBase85("foobarbazqux") == "w]zP%vrb*=Du17L", "(Base85) foobarbazqux failed to encode into w]zP%vrb*=Du17L")
    assert(encodeBase85("\0\0\0\0☺☻♥♦") == "00000&*vspN7IvCRq^]u", "(Base85) \\0\\0\\0\\0☺☻♥♦ failed to encode into 00000&*vspN7IvCRq^]u")

    assert(decodeBase85("HelloWorld") == "\134\79\210\111\181\89\247\91", "(Base85) HelloWorld failed to decode into \\134\\79\\210\\111\\181\\89\\247\\91 binary string")
    assert(decodeBase85("w]zP%vrb*=Du17L") == "foobarbazqux", "(Base85) w]zP%vrb*=Du17L failed to decode into foobarbazqux")
    assert(decodeBase85("00000&*vspN7IvCRq^]u") == "\0\0\0\0☺☻♥♦", "(Base85) 00000&*vspN7IvCRq^]u failed to decode into \\0\\0\\0\\0☺☻♥♦")

    assert(not (pcall(encodeBase85, "foo")), "(Base85) encodeBase85 failed to throw when input isn't a multiple of 4")
    assert(not (pcall(decodeBase85, "bar")), "(Base85) decodeBase85 failed to throw when input isn't a multiple of 5")

    print("Base85 tests completed. Took", tick()-t)
end

return {
    encode = encodeBase85,
    decode = decodeBase85,
}