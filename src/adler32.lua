local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

local function adler32(input)
    local a = 1
    local b = 0

    -- 5552 is the maximum amount of bytes that can be processed before modulo is required:
    -- Assuming a and b are both 65520 (one less than the chosen prime), and all data in the block is \255,
    -- b will be 4294690200 (277096 less than 2^32). Any larger and it will be well over 2^32.
    -- (https://software.intel.com/en-us/articles/fast-computation-of-adler32-checksums)

    for i = 1, #input, 5553 do
        for j = 0, 5552 do
            local byte = string.byte(input, i+j)
            if not byte then
                break
            end
            a = a+byte
            b = b+a
        end
        a = a%65521
        b = b%65521
    end

    return bit32.lshift(b, 16)+a
end

if ASSERTIONS_ENABLED then
    -- A lot of these aren't necessarily 'test vectors' but they are tests to make sure it works
    local t = tick()

    assert(adler32("123456789") == 0x091e01de, "(ADLER-32) 123456789 checksum does not match")

    assert(adler32("abc") == 0x024d0127, "(ADLER-32) abc checksum does not match")
    assert(adler32("") == 0x00000001, "(ADLER-32) empty checksum does not match")
    assert(adler32("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == 0x807416f9, "(ADLER-32) 448 bit alphabet checksum does not match")
    assert(adler32("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") == 0x1ac22ed1, "(ADLER-32) 896 bit alphabet checksum does not match")
    assert(adler32("foo") == 0x02820145, "(ADLER-32) foo checksum does not match")
    assert(adler32("bar") == 0x025d0136, "(ADLER-32) bar checksum does not match")
    assert(adler32("baz") == 0x0265013e, "(ADLER-32) baz checksum does not match")
    assert(adler32("The Fitness-Gram Pacer Test is a multi-stage aerobic capacity test") == 0x0f0d17e9, "(ADLER-32) Fitness-Gram checksum does not match")
    if true then
        assert(adler32(string.rep("e", 199999)) == 0x31744be8, "(ADLER-32) e checksum does not match")
    end

    print("ADLER-32 tests completed. Took", tick()-t)
end

return adler32