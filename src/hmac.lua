local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

local INNER_PADDING_CHAR = string.char(0x36)
local OUTER_PADDING_CHAR = string.char(0x5C)

local binaryStringMap = {}
for i = 0, 255 do
    binaryStringMap[string.format("%02x", i)] = string.char(i)
end

local function xorStrings(str1, str2)
    local output = {}
    for i = 1, #str1 do
        output[i] = string.char(bit32.bxor(string.byte(str1, i), string.byte(str2, i)))
    end
    return table.concat(output)
end

local function hexToBinary(string)
    return ( string.gsub(string, "%x%x", binaryStringMap) )
end

--- Outputs a HMAC string (in hex) given a key, message, hashing function, and block size.
--- Optionally accepts an output size to truncate the HMAC to. Both blockSize and outputSize are in bytes for ease of computation.
local function hmac(key, message, hash, blockSize, outputSize)
    local innerPadding = string.rep(INNER_PADDING_CHAR, blockSize)
    local outerPadding = string.rep(OUTER_PADDING_CHAR, blockSize)

    if #key > blockSize then
        key = hexToBinary(hash(key))
    end
    if #key < blockSize then
        key = key..string.rep("\0", blockSize-#key)
    end
    local outerKey = xorStrings(key, outerPadding)
    local innerKey = xorStrings(key, innerPadding)

    local mac = hash( outerKey..hexToBinary(hash(innerKey..message)) )

    if outputSize then
        --? Maybe throw a warning if the outputSize is less than 10, as that's considered insecure (https://tools.ietf.org/html/rfc2104#section-5)
        return string.sub(mac, 1, outputSize*2) -- Today's gross hack is brought to you by every byte being represented by two hex digits
    else
        return mac
    end
end

if ASSERTIONS_ENABLED then --TODO: Finish writing test vectors
    local sha1 = require("sha1")
    local sha256 = require("sha256")
    local md5 = require("md5")

    local t = tick()

    -- SHA-256/SHA-224 tests (https://tools.ietf.org/html/rfc4231)
    assert(hmac(string.rep(string.char(0x0b), 20), "Hi There", sha256.sha224, 64) == "896fb1128abbdf196832107cd49df33f47b4b1169912ba4f53684b22", "(HMAC-SHA-224) RFC test case 1 hash does not match")
    assert(hmac(string.rep(string.char(0x0b), 20), "Hi There", sha256.sha256, 64) == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7", "(HMAC-SHA-256) RFC test case 1 hash does not match")

    assert(hmac("Jefe", "what do ya want for nothing?", sha256.sha224, 64) == "a30e01098bc6dbbf45690f3a7e9e6d0f8bbea2a39e6148008fd05e44", "(HMAC-SHA-224) RFC test case 2 hash does not match")
    assert(hmac("Jefe", "what do ya want for nothing?", sha256.sha256, 64) == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "(HMAC-SHA-256) RFC test case 2 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 20), string.rep(string.char(0xdd), 50), sha256.sha224, 64) == "7fb3cb3588c6c1f6ffa9694d7d6ad2649365b0c1f65d69d1ec8333ea", "(HMAC-SHA-224) RFC test case 3 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 20), string.rep(string.char(0xdd), 50), sha256.sha256, 64) == "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe", "(HMAC-SHA-256) RFC test case 3 hash does not match")

    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), sha256.sha224, 64) == "6c11506874013cac6a2abc1bb382627cec6a90d86efc012de7afec5a", "(HMAC-SHA-224) RFC test case 4 hash does not match")
    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), sha256.sha256, 64) == "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b", "(HMAC-SHA-256) RFC test case 4 hash does not match")

    assert(hmac(string.rep(string.char(0x0c), 20), "Test With Truncation", sha256.sha224, 64, 16) == "0e2aea68a90c8d37c988bcdb9fca6fa8", "(HMAC-SHA-224) RFC test case 5 hash does not match")
    assert(hmac(string.rep(string.char(0x0c), 20), "Test With Truncation", sha256.sha256, 64, 16) == "a3b6167473100ee06e0c796c2955552b", "(HMAC-SHA-256) RFC test case 5 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "Test Using Larger Than Block-Size Key - Hash Key First", sha256.sha224, 64) == "95e9a0db962095adaebe9b2d6f0dbce2d499f112f2d2b7273fa6870e", "(HMAC-SHA-224) RFC test case 6 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 131), "Test Using Larger Than Block-Size Key - Hash Key First", sha256.sha256, 64) == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54", "(HMAC-SHA-256) RFC test case 6 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.", sha256.sha224, 64) == "3a854166ac5d9f023f54d517d0b39dbd946770db9c2b95c9f6f565d1", "(HMAC-SHA-224) RFC test case 7 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 131), "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.", sha256.sha256, 64) == "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2", "(HMAC-SHA-256) RFC test case 7 hash does not match")

    -- SHA-1/MD5 tests (https://tools.ietf.org/html/rfc2202)
    assert(hmac(string.rep(string.char(0x0b), 16), "Hi There", md5, 64) == "9294727a3638bb1c13f48ef8158bfc9d", "(HMAC-MD5) RFC test case 1 hash does not match")
    assert(hmac(string.rep(string.char(0x0b), 20), "Hi There", sha1, 64) == "b617318655057264e28bc0b6fb378c8ef146be00", "(HMAC-SHA-1) RFC test case 1 hash does not match")

    assert(hmac("Jefe", "what do ya want for nothing?", md5, 64) == "750c783e6ab0b503eaa86e310a5db738", "(HMAC-MD5) RFC test case 2 hash does not match")
    assert(hmac("Jefe", "what do ya want for nothing?", sha1, 64) == "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79", "(HMAC-SHA-1) RFC test case 2 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 16), string.rep(string.char(0xdd), 50), md5, 64) == "56be34521d144c88dbb8c733f0e8b3f6", "(HMAC-MD5) RFC test case 3 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 20), string.rep(string.char(0xdd), 50), sha1, 64) == "125d7342b9ac11cd91a39af48aa17b4f63f175d3", "(HMAC-SHA-1) RFC test case 3 hash does not match")

    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), md5, 64) == "697eaf0aca3a3aea3a75164746ffaa79", "(HMAC-MD5) RFC test case 4 hash does not match")
    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), sha1, 64) == "4c9007f4026250c6bc8414f9bf50c86c2d7235da", "(HMAC-SHA-1) RFC test case 4 hash does not match")

    assert(hmac(string.rep(string.char(0x0c), 16), "Test With Truncation", md5, 64, 12) == "56461ef2342edc00f9bab995", "(HMAC-MD5) RFC test case 5 hash does not match")
    assert(hmac(string.rep(string.char(0x0c), 20), "Test With Truncation", sha1, 64, 12) == "4c1a03424b55e07fe7f27be1", "(HMAC-SHA-1) RFC test case 5 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 80), "Test Using Larger Than Block-Size Key - Hash Key First", md5, 64) == "6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd", "(HMAC-MD5) RFC test case 6 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 80), "Test Using Larger Than Block-Size Key - Hash Key First", sha1, 64) == "aa4ae5e15272d00e95705637ce8a3b55ed402112", "(HMAC-SHA-1) RFC test case 6 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 80), "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data", md5, 64) == "6f630fad67cda0ee1fb1f562db3aa53e", "(HMAC-MD5) RFC test case 7 hash does not match")
    assert(hmac(string.rep(string.char(0xaa), 80), "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data", sha1, 64) == "e8e99d0f45237d786d6bbaa7965c7808bbff1a91", "(HMAC-SHA-1) RFC test case 7 hash does not match")

    print("HMAC tests completed. Took", tick()-t)
end

return hmac