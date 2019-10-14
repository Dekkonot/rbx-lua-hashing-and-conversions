local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

--x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1
--msb = x^31:       00000100110000010001110110110111 (little endian)
--invert:           11101101101110001000001100100000 (big endian)
local POLYNOMIAL = 0xedb88320

local polyLookup = {}
for i = 0, 255 do
    local crc = i
    for _ = 1, 8 do
        local mask = -bit32.band(crc, 1)
        crc = bit32.bxor(bit32.rshift(crc, 1), bit32.band(POLYNOMIAL, mask))
    end
    polyLookup[i] = crc
end

local function crc32(data)
    local crc = 0xffffffff

    for i = 1, #data do
        local poly = polyLookup[bit32.bxor(crc, string.byte(data, i))%256]
        crc = bit32.rshift(crc, 8)
        crc = bit32.bxor(crc, poly)
    end

    return bit32.bnot(crc)%0xffffffff --TODO: make this output a string, maybe
end

if ASSERTIONS_ENABLED then
    -- A lot of these aren't necessarily 'test vectors' but they are tests to make sure it works
    local t = tick()

    assert(crc32("123456789") == 0xcbf43926, "(CRC-32) 123456789 checksum does not match")

    assert(crc32("abc") == 0x352441c2, "(CRC-32) abc checksum does not match")
    assert(crc32("") == 0x00000000, "(CRC-32) empty checksum does not match")
    assert(crc32("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == 0x171a3f5f, "(CRC-32) 448 bit alphabet checksum does not match")
    assert(crc32("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") == 0x191f3349, "(CRC-32) 896 bit alphabet checksum does not match")
    assert(crc32("foo") == 0x8c736521, "(CRC-32) foo checksum does not match")
    assert(crc32("bar") == 0x76ff8caa, "(CRC-32) bar checksum does not match")
    assert(crc32("baz") == 0x78240498, "(CRC-32) baz checksum does not match")
    assert(crc32("The Fitness-Gram Pacer Test is a multi-stage aerobic capacity test") == 0xfe1fc480, "(CRC-32) Fitness-Gram checksum does not match")
    if true then
        assert(crc32(string.rep("e", 199999)) == 0x95dbf705, "(CRC-32) e checksum does not match")
    end

    print("CRC-32 tests completed. Took", tick()-t)
end

return crc32