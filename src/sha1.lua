-- Do not use this for serious purposes.
-- https:///shattered.io/

local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded and when a message is preprocessed.

local INIT_0 = 0x67452301
local INIT_1 = 0xEFCDAB89
local INIT_2 = 0x98BADCFE
local INIT_3 = 0x10325476
local INIT_4 = 0xC3D2E1F0

local APPEND_CHAR = string.char(0x80)
local INT_32_CAP = 2^32

---Packs four 8-bit integers into one 32-bit integer
local function packUint32(a, b, c, d)
    return bit32.lshift(a, 24)+bit32.lshift(b, 16)+bit32.lshift(c, 8)+d
end

---Unpacks one 32-bit integer into four 8-bit integers
local function unpackUint32(int)
    return bit32.extract(int, 24, 8), bit32.extract(int, 16, 8),
           bit32.extract(int, 08, 8), bit32.extract(int, 00, 8)
end

local function F(t, A, B, C)
    if t <= 19 then
        -- C ~ (A & (B ~ C)) has less ops than (A & B) ~ (~A & C)
        return bit32.bxor(C, bit32.band(A, bit32.bxor(B, C)))
    elseif t <= 39 then
        return bit32.bxor(A, B, C)
    elseif t <= 59 then
        -- A | (B | C) | (B & C) has less ops than (A & B) ~ (A & C) ~ (B & C)
        return bit32.bor(bit32.band(A, bit32.bor(B, C)), bit32.band(B, C))
    else
        return bit32.bxor(A, B, C)
    end
end

local function K(t)
    if t <= 19 then
        return 0x5A827999
    elseif t <= 39 then
        return 0x6ED9EBA1
    elseif t <= 59 then
        return 0x8F1BBCDC
    else
        return 0xCA62C1D6
    end
end

local function preprocessMessage(message)
    local initMsgLen = #message*8 -- Message length in bits
    local msgLen = initMsgLen+8
    local nulCount = 4 -- This is equivalent to 32 bits.
    -- We're packing 32 bits of size, but the SHA-1 standard calls for 64, meaning we have to add at least 32 0s
    message = message..APPEND_CHAR
    while (msgLen+64)%512 ~= 0 do
        nulCount = nulCount+1
        msgLen = msgLen+8
    end
    message = message..string.rep("\0", nulCount)
    message = message..string.char(unpackUint32(initMsgLen))
    if ASSERTIONS_ENABLED then
        assert(msgLen%512 == 448, "message length space check")
        assert(#message%64 == 0, "message length check")
    end
    return message
end

local function sha1(message)
    local message = preprocessMessage(message)

    local H0 = INIT_0
    local H1 = INIT_1
    local H2 = INIT_2
    local H3 = INIT_3
    local H4 = INIT_4

    local W = {}
    for chunkStart = 1, #message, 64 do
        local place = chunkStart
        for t = 0, 15 do
            W[t] = packUint32(string.byte(message, place, place+3))
            place = place+4
        end
        for t = 16, 79 do
            W[t] = bit32.lrotate(bit32.bxor(W[t-3], W[t-8], W[t-14], W[t-16]), 1)
        end

        local A, B, C, D, E = H0, H1, H2, H3, H4

        for t = 0, 79 do
            local TEMP = ( bit32.lrotate(A, 5)+F(t, B, C, D)+E+W[t]+K(t) )%INT_32_CAP

            E, D, C, B, A = D, C, bit32.lrotate(B, 30), A, TEMP
        end

        H0 = (H0+A)%INT_32_CAP
        H1 = (H1+B)%INT_32_CAP
        H2 = (H2+C)%INT_32_CAP
        H3 = (H3+D)%INT_32_CAP
        H4 = (H4+E)%INT_32_CAP
    end
    return string.format("%08x%08x%08x%08x%08x", H0, H1, H2, H3, H4)
end

if ASSERTIONS_ENABLED then
    local t = tick()

    assert(packUint32(255, 167, 125, 235) == 4289166827, "(SHA-1) packUint32 check 1")
    assert(packUint32(255, 0, 125, 235) == 4278222315, "(SHA-1) packUint32 check 2")

    local b0, b1, b2, b3 = unpackUint32(4278222315)
    assert(b0 == 255, "(SHA-1) unpackUint32 check 1")
    assert(b1 == 000, "(SHA-1) unpackUint32 check 2")
    assert(b2 == 125, "(SHA-1) unpackUint32 check 3")
    assert(b3 == 235, "(SHA-1) unpackUint32 check 4")

    assert(sha1("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d", "(SHA-1) abc hash does not match")
    assert(sha1("") == "da39a3ee5e6b4b0d3255bfef95601890afd80709", "(SHA-1) empty hash does not match")
    assert(sha1("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == "84983e441c3bd26ebaae4aa1f95129e5e54670f1", "(SHA-1) 448 bit alphabet hash does not match")
    assert(sha1("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") == "a49b2446a02c645bf419f995b67091253a04a259", "(SHA-1) 896 bit alphabet hash does not match")
    assert(sha1("foo") == "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33", "(SHA-1) foo hash does not match")
    assert(sha1("bar") == "62cdb7020ff920e5aa642c3d4066950dd1f01f4d", "(SHA-1) bar hash does not match")
    assert(sha1("baz") == "bbe960a25ea311d21d40669e93df2003ba9b90a2", "(SHA-1) baz hash does not match")
    assert(sha1("The Fitness-Gram Pacer Test is a multi-stage aerobic capacity test") == "fe32af74bc982dc5da23e54055f5515e948a10bd", "(SHA-1) Fitness-Gram hash does not match")
    if true then
        assert(sha1(string.rep("e", 199999)) == "07fe6fab7549089cb7b256545b1f31fe7ed74207", "(SHA-1) e hash does not match")
        assert(sha1(string.rep("a", 1e6)) == "34aa973cd4c4daa4f61eeb2bdbad27316534016f", "(SHA-1) million a hash does not match")
    end

    print("SHA-1 tests completed. Took", tick()-t)
end

return sha1