local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

local CHAR_SET = {[0] =
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "2", "3", "4", "5", "6", "7",
}

local HEX_CHAR_SET = {[0] =
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
    "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
}

local REVERSE_CHAR_SET = {
    [65] = 0, [66] = 1, [67] = 2, [68] = 3, [69] = 4, [70] = 5, [71] = 6, [72] = 7,
    [73] = 8, [74] = 9, [75] = 10, [76] = 11, [77] = 12, [78] = 13, [79] = 14, [80] = 15,
    [81] = 16, [82] = 17, [83] = 18, [84] = 19, [85] = 20, [86] = 21, [87] = 22, [88] = 23,
    [89] = 24, [90] = 25, [50] = 26, [51] = 27, [52] = 28, [53] = 29, [54] = 30, [55] = 31,
}

local REVERSE_HEX_CHAR_SET = {
    [48] = 0, [49] = 1, [50] = 2, [51] = 3, [52] = 4, [53] = 5, [54] = 6, [55] = 7,
    [56] = 8, [57] = 9, [65] = 10, [66] = 11, [67] = 12, [68] = 13, [69] = 14, [70] = 15,
    [71] = 16, [72] = 17, [73] = 18, [74] = 19, [75] = 20, [76] = 21, [77] = 22, [78] = 23,
    [79] = 24, [80] = 25, [81] = 26, [82] = 27, [83] = 28, [84] = 29, [85] = 30, [86] = 31,
}

---Packs four 8-bit integers into one 32-bit integer
local function packUint32(a, b, c, d)
    return bit32.lshift(a, 24)+bit32.lshift(b, 16)+bit32.lshift(c, 8)+d
end

local function encodeBase32(input, omitPadding)
    local output = {}
    local padding = #input%5

    local c = 1
    for i = 1, #input, 5 do
        local b1, b2, b3, b4, b5 = string.byte(input, i, i+4)
        local packed = packUint32(b1, b2 or 0, b3 or 0, b4 or 0)
        output[c] = CHAR_SET[bit32.extract(packed, 27, 5)]
        output[c+1] = CHAR_SET[bit32.extract(packed, 22, 5)]
        if b2 then
            output[c+2] = CHAR_SET[bit32.extract(packed, 17, 5)]
            output[c+3] = CHAR_SET[bit32.extract(packed, 12, 5)]
            if b3 then
                output[c+4] = CHAR_SET[bit32.extract(packed, 7, 5)]
                if b4 then
                    output[c+5] = CHAR_SET[bit32.extract(packed, 2, 5)]
                    output[c+6] = CHAR_SET[bit32.lshift(bit32.extract(packed, 0, 2), 3)+bit32.extract(b5 or 0, 5, 3)]
                    if b5 then
                        output[c+7] = CHAR_SET[bit32.extract(b5, 0, 5)]
                    end
                end
            end
        end
        c = c+8
    end
    if not omitPadding then
        if padding == 1 then
            output[c-6] = "======"
        elseif padding == 2 then
            output[c-4] = "===="
        elseif padding == 3 then
            output[c-3] = "==="
        elseif padding == 4 then
            output[c-1] = "="
        end
    end
    return table.concat(output)
end

local function decodeBase32(input)
    assert(not (string.find(input, "[^A-Z2-7=]")), "input contains invalid characters")

    local output = {}

    local c = 1
    for i = 1, #input, 8 do
        local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(input, i, i+7)
        b1 = REVERSE_CHAR_SET[b1]
        b2 = REVERSE_CHAR_SET[b2]
        b3 = REVERSE_CHAR_SET[b3]
        b4 = REVERSE_CHAR_SET[b4]
        b5 = REVERSE_CHAR_SET[b5]
        b6 = REVERSE_CHAR_SET[b6]
        b7 = REVERSE_CHAR_SET[b7]
        b8 = REVERSE_CHAR_SET[b8]

        local packed = bit32.lshift(b1, 27)+bit32.lshift(b2, 22)+bit32.lshift(b3 or 0, 17)+bit32.lshift(b4 or 0, 12)+bit32.lshift(b5 or 0, 7)+bit32.lshift(b6 or 0, 2)+bit32.extract(b7 or 0, 3, 2)

        output[c] = string.char(bit32.extract(packed, 24, 8))
        if not b3 then break end
        output[c+1] = string.char(bit32.extract(packed, 16, 8))
        if not b5 then break end
        output[c+2] = string.char(bit32.extract(packed, 8, 8))
        if not b6 then break end
        output[c+3] = string.char(bit32.extract(packed, 0, 8))
        if not b8 then break end
        output[c+4] = string.char(bit32.lshift(bit32.extract(b7, 0, 3), 5)+b8)
        c = c+5
    end
    return table.concat(output)
end

local function encodeBase32Hex(input, omitPadding)
    local output = {}
    local padding = #input%5

    local c = 1
    for i = 1, #input, 5 do
        local b1, b2, b3, b4, b5 = string.byte(input, i, i+4)
        local packed = packUint32(b1, b2 or 0, b3 or 0, b4 or 0)
        output[c] = HEX_CHAR_SET[bit32.extract(packed, 27, 5)]
        output[c+1] = HEX_CHAR_SET[bit32.extract(packed, 22, 5)]
        if b2 then
            output[c+2] = HEX_CHAR_SET[bit32.extract(packed, 17, 5)]
            output[c+3] = HEX_CHAR_SET[bit32.extract(packed, 12, 5)]
            if b3 then
                output[c+4] = HEX_CHAR_SET[bit32.extract(packed, 7, 5)]
                if b4 then
                    output[c+5] = HEX_CHAR_SET[bit32.extract(packed, 2, 5)]
                    output[c+6] = HEX_CHAR_SET[bit32.lshift(bit32.extract(packed, 0, 2), 3)+bit32.extract(b5 or 0, 5, 3)]
                    if b5 then
                        output[c+7] = HEX_CHAR_SET[bit32.extract(b5, 0, 5)]
                    end
                end
            end
        end
        c = c+8
    end
    if not omitPadding then
        if padding == 1 then
            output[c-6] = "======"
        elseif padding == 2 then
            output[c-4] = "===="
        elseif padding == 3 then
            output[c-3] = "==="
        elseif padding == 4 then
            output[c-1] = "="
        end
    end
    return table.concat(output)
end

local function decodeBase32Hex(input)
    assert(not (string.find(input, "[^0-9A-V=]")), "input contains invalid characters")

    local output = {}

    local c = 1
    for i = 1, #input, 8 do
        local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(input, i, i+7)
        b1 = REVERSE_HEX_CHAR_SET[b1]
        b2 = REVERSE_HEX_CHAR_SET[b2]
        b3 = REVERSE_HEX_CHAR_SET[b3]
        b4 = REVERSE_HEX_CHAR_SET[b4]
        b5 = REVERSE_HEX_CHAR_SET[b5]
        b6 = REVERSE_HEX_CHAR_SET[b6]
        b7 = REVERSE_HEX_CHAR_SET[b7]
        b8 = REVERSE_HEX_CHAR_SET[b8]

        local packed = bit32.lshift(b1, 27)+bit32.lshift(b2, 22)+bit32.lshift(b3 or 0, 17)+bit32.lshift(b4 or 0, 12)+bit32.lshift(b5 or 0, 7)+bit32.lshift(b6 or 0, 2)+bit32.extract(b7 or 0, 3, 2)

        output[c] = string.char(bit32.extract(packed, 24, 8))
        if not b3 then break end
        output[c+1] = string.char(bit32.extract(packed, 16, 8))
        if not b5 then break end
        output[c+2] = string.char(bit32.extract(packed, 8, 8))
        if not b6 then break end
        output[c+3] = string.char(bit32.extract(packed, 0, 8))
        if not b8 then break end
        output[c+4] = string.char(bit32.lshift(bit32.extract(b7, 0, 3), 5)+b8)
        c = c+5
    end
    return table.concat(output)
end

if ASSERTIONS_ENABLED then
    -- local t = tick()

    assert(packUint32(255, 167, 125, 235) == 4289166827, "(Base32) packUint32 check 1")
    assert(packUint32(255, 0, 125, 235) == 4278222315, "(Base32) packUint32 check 2")

    -- Base32 tests
    assert(encodeBase32("Man") == "JVQW4===", "(Base32) Man failed to encode into JVQW4===")
    assert(encodeBase32("Ma") == "JVQQ====", "(Base32) Ma failed to encode into JVQQ====")
    assert(encodeBase32("M") == "JU======", "(Base32) M failed to encode into JU======")
    assert(encodeBase32("Baby shark") == "IJQWE6JAONUGC4TL", "(Base32) Baby shark failed to encode into IJQWE6JAONUGC4TL")
    assert(encodeBase32("Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads") == "IFWG233TOQQGQZLBOZSW4LBAK5SXG5BAKZUXEZ3JNZUWCCSCNR2WKICSNFSGOZJAJVXXK3TUMFUW44ZMEBJWQZLOMFXGI33BNAQFE2LWMVZAUTDJMZSSA2LTEBXWYZBAORUGK4TFFQQG63DEMVZCA5DIMFXCA5DIMUQHI4TFMVZQUWLPOVXGOZLSEB2GQYLOEB2GQZJANVXXK3TUMFUW44ZMEBRGY33XNFXGOIDMNFVWKIDBEBRHEZLFPJSQUQ3POVXHI4TZEBZG6YLEOMWCA5DBNNSSA3LFEBUG63LFBJKG6IDUNBSSA4DMMFRWKICJEBRGK3DPNZTQUV3FON2CAVTJOJTWS3TJMEWCA3LPOVXHIYLJNYQG2YLNMEFFIYLLMUQG2ZJANBXW2ZJMEBRW65LOORZHSIDSN5QWI4YKIFWGYIDNPEQG2ZLNN5ZGSZLTEBTWC5DIMVZCA4TPOVXGIIDIMVZAUTLJNZSXEJ3TEBWGCZDZFQQHG5DSMFXGOZLSEB2G6IDCNR2WKIDXMF2GK4QKIRQXE2ZAMFXGIIDEOVZXI6JMEBYGC2LOORSWIIDPNYQHI2DFEBZWW6IKJVUXG5DZEB2GC43UMUQG6ZRANVXW63TTNBUW4ZJMEB2GKYLSMRZG64BANFXCA3LZEBSXSZIKINXXK3TUOJ4SA4TPMFSHGLBAORQWWZJANVSSA2DPNVSQUVDPEB2GQZJAOBWGCY3FEBESAYTFNRXW4ZYKK5SXG5BAKZUXEZ3JNZUWCLBANVXXK3TUMFUW4IDNMFWWCCSUMFVWKIDNMUQGQ33NMUWCAY3POVXHI4TZEBZG6YLEOMFESIDIMVQXEIDIMVZCA5TPNFRWKLBANFXCA5DIMUQG233SNZUW4ZZANBXXK4RAONUGKIDDMFWGY4ZANVSQUVDIMUQHEYLENFXSA4TFNVUW4ZDTEBWWKIDPMYQG26JANBXW2ZJAMZQXEIDBO5QXSCSBNZSCAZDSNF3GS3THEBSG653OEB2GQZJAOJXWCZBAJEQGOZLUEBQSAZTFMVWGS3THBJKGQYLUEBESA43IN52WYZBANBQXMZJAMJSWK3RANBXW2ZJAPFSXG5DFOJSGC6JMEB4WK43UMVZGIYLZBJBW65LOORZHSIDSN5QWI4ZMEB2GC23FEBWWKIDIN5WWKCSUN4QHI2DFEBYGYYLDMUQESIDCMVWG63THBJLWK43UEBLGS4THNFXGSYJMEBWW65LOORQWS3RANVQW2YIKKRQWWZJANVSSA2DPNVSSYIDDN52W45DSPEQHE33BMRZQUQ3POVXHI4TZEBZG6YLEOMWCA5DBNNSSA3LFEBUG63LFBJKG6IDUNBSSA4DMMFRWKICJEBRGK3DPNZTQUV3FON2CAVTJOJTWS3TJMEWCA3LPOVXHIYLJNYQG2YLNMEFFIYLLMUQG2ZJANBXW2ZJMEBRW65LOORZHSIDSN5QWI4YKKRQWWZJANVSSA2DPNVSSYIDEN53W4IDDN52W45DSPEQHE33BMRZQUVDBNNSSA3LFEBUG63LFFQQGI33XNYQGG33VNZ2HE6JAOJXWCZDT", "(Base32) Country Roads failed to encode properly")

    assert(encodeBase32("Man", true) == "JVQW4", "(Base32) Man with padding disabled failed to encode into JVQW4")
    assert(encodeBase32("Ma", true) == "JVQQ", "(Base32) Ma with padding disabled failed to encode into JVQQ")
    assert(encodeBase32("M", true) == "JU", "(Base32) M with padding disabled failed to encode into JU")
    assert(encodeBase32("Baby shark", true) == "IJQWE6JAONUGC4TL", "(Base32) Baby shark with padding disabled failed to encode into IJQWE6JAONUGC4TL")

    assert(encodeBase32("") == "", "(Base32) Empty string failed to encode properly")
    assert(encodeBase32("f") == "MY======", "(Base32) f failed to encode into MY======")
    assert(encodeBase32("fo") == "MZXQ====", "(Base32) fo failed to encode into MZXQ====")
    assert(encodeBase32("foo") == "MZXW6===", "(Base32) foo failed to encode into MZXW6===")
    assert(encodeBase32("foob") == "MZXW6YQ=", "(Base32) foob failed to encode into MZXW6YQ=")
    assert(encodeBase32("fooba") == "MZXW6YTB", "(Base32) fooba failed to encode into MZXW6YTB")
    assert(encodeBase32("foobar") == "MZXW6YTBOI======", "(Base32) foobar failed to encode into MZXW6YTBOI======")

    assert(encodeBase32("A\0B") == "IEAEE===", "(Base32) A\\0B failed to encode into IEAEE===")
    assert(encodeBase32("A\n\t\v") == "IEFASCY=", "(Base32) A\\n\\t\\v failed to encode into IEFASCY=")
    assert(encodeBase32("☺☻") == "4KMLVYUYXM======", "(Base32) ☺☻ failed to encode into 4KMLVYUYXM======")
    assert(encodeBase32("テスト") == "4OBYNY4CXHRYHCA=", "(Base32) テスト failed to encode into 4OBYNY4CXHRYHCA=")

    assert(decodeBase32("JVQW4===") == "Man", "(Base32) JVQW4=== failed to decode into Man")
    assert(decodeBase32("JVQQ====") == "Ma", "(Base32) JVQQ==== failed to decode into Ma")
    assert(decodeBase32("JU======") == "M", "(Base32) JU====== failed to decode into M")
    assert(decodeBase32("IJQWE6JAONUGC4TL") == "Baby shark", "(Base32) IJQWE6JAONUGC4TL failed to decode into Baby shark")
    assert(decodeBase32("IFWG233TOQQGQZLBOZSW4LBAK5SXG5BAKZUXEZ3JNZUWCCSCNR2WKICSNFSGOZJAJVXXK3TUMFUW44ZMEBJWQZLOMFXGI33BNAQFE2LWMVZAUTDJMZSSA2LTEBXWYZBAORUGK4TFFQQG63DEMVZCA5DIMFXCA5DIMUQHI4TFMVZQUWLPOVXGOZLSEB2GQYLOEB2GQZJANVXXK3TUMFUW44ZMEBRGY33XNFXGOIDMNFVWKIDBEBRHEZLFPJSQUQ3POVXHI4TZEBZG6YLEOMWCA5DBNNSSA3LFEBUG63LFBJKG6IDUNBSSA4DMMFRWKICJEBRGK3DPNZTQUV3FON2CAVTJOJTWS3TJMEWCA3LPOVXHIYLJNYQG2YLNMEFFIYLLMUQG2ZJANBXW2ZJMEBRW65LOORZHSIDSN5QWI4YKIFWGYIDNPEQG2ZLNN5ZGSZLTEBTWC5DIMVZCA4TPOVXGIIDIMVZAUTLJNZSXEJ3TEBWGCZDZFQQHG5DSMFXGOZLSEB2G6IDCNR2WKIDXMF2GK4QKIRQXE2ZAMFXGIIDEOVZXI6JMEBYGC2LOORSWIIDPNYQHI2DFEBZWW6IKJVUXG5DZEB2GC43UMUQG6ZRANVXW63TTNBUW4ZJMEB2GKYLSMRZG64BANFXCA3LZEBSXSZIKINXXK3TUOJ4SA4TPMFSHGLBAORQWWZJANVSSA2DPNVSQUVDPEB2GQZJAOBWGCY3FEBESAYTFNRXW4ZYKK5SXG5BAKZUXEZ3JNZUWCLBANVXXK3TUMFUW4IDNMFWWCCSUMFVWKIDNMUQGQ33NMUWCAY3POVXHI4TZEBZG6YLEOMFESIDIMVQXEIDIMVZCA5TPNFRWKLBANFXCA5DIMUQG233SNZUW4ZZANBXXK4RAONUGKIDDMFWGY4ZANVSQUVDIMUQHEYLENFXSA4TFNVUW4ZDTEBWWKIDPMYQG26JANBXW2ZJAMZQXEIDBO5QXSCSBNZSCAZDSNF3GS3THEBSG653OEB2GQZJAOJXWCZBAJEQGOZLUEBQSAZTFMVWGS3THBJKGQYLUEBESA43IN52WYZBANBQXMZJAMJSWK3RANBXW2ZJAPFSXG5DFOJSGC6JMEB4WK43UMVZGIYLZBJBW65LOORZHSIDSN5QWI4ZMEB2GC23FEBWWKIDIN5WWKCSUN4QHI2DFEBYGYYLDMUQESIDCMVWG63THBJLWK43UEBLGS4THNFXGSYJMEBWW65LOORQWS3RANVQW2YIKKRQWWZJANVSSA2DPNVSSYIDDN52W45DSPEQHE33BMRZQUQ3POVXHI4TZEBZG6YLEOMWCA5DBNNSSA3LFEBUG63LFBJKG6IDUNBSSA4DMMFRWKICJEBRGK3DPNZTQUV3FON2CAVTJOJTWS3TJMEWCA3LPOVXHIYLJNYQG2YLNMEFFIYLLMUQG2ZJANBXW2ZJMEBRW65LOORZHSIDSN5QWI4YKKRQWWZJANVSSA2DPNVSSYIDEN53W4IDDN52W45DSPEQHE33BMRZQUVDBNNSSA3LFEBUG63LFFQQGI33XNYQGG33VNZ2HE6JAOJXWCZDT") == "Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads", "(Base32) Country Roads failed to decode properly")

    assert(decodeBase32("JVQW4") == "Man", "(Base32) JVQW4 failed to decode into Man")
    assert(decodeBase32("JVQQ") == "Ma", "(Base32) JVQQ failed to decode into Ma")
    assert(decodeBase32("JU") == "M", "(Base32) JU failed to decode into M")

    assert(decodeBase32("") == "", "(Base32) Empty string failed to decode")
    assert(decodeBase32("MY======") == "f", "(Base32) MY====== failed to decode into f")
    assert(decodeBase32("MZXQ====") == "fo", "(Base32) MZXQ==== failed to decode into fo")
    assert(decodeBase32("MZXW6===") == "foo", "(Base32) MZXW6=== failed to decode into foo")
    assert(decodeBase32("MZXW6YQ=") == "foob", "(Base32) MZXW6YQ= failed to decode into foob")
    assert(decodeBase32("MZXW6YTB") == "fooba", "(Base32) MZXW6YTB failed to decode into fooba")
    assert(decodeBase32("MZXW6YTBOI======") == "foobar", "(Base32) MZXW6YTBOI====== failed to decode into foobar")

    assert(decodeBase32("IEAEE===") == "A\0B", "(Base32) IEAEE=== failed to decode into A\\0B")
    assert(decodeBase32("IEFASCY=") == "A\n\t\v", "(Base32) IEFASCY= failed to decode into A\\n\\t\\v")
    assert(decodeBase32("4KMLVYUYXM======") == "☺☻", "(Base32) 4KMLVYUYXM====== failed to decode into ☺☻")
    assert(decodeBase32("4OBYNY4CXHRYHCA=") == "テスト", "(Base32) 4OBYNY4CXHRYHCA= failed to decode into テスト")

    -- Base32-Hex tests
    assert(encodeBase32Hex("Man") == "9LGMS===", "(Base32-Hex) Man failed to encode into 9LGMS===")
    assert(encodeBase32Hex("Ma") == "9LGG====", "(Base32-Hex) Ma failed to encode into 9LGG====")
    assert(encodeBase32Hex("M") == "9K======", "(Base32-Hex) M failed to encode into 9K======")
    assert(encodeBase32Hex("Baby shark") == "89GM4U90EDK62SJB", "(Base32-Hex) Baby shark failed to encode into 89GM4U90EDK62SJB")
    assert(encodeBase32Hex("Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads") == "85M6QRRJEGG6GPB1EPIMSB10ATIN6T10APKN4PR9DPKM22I2DHQMA82ID5I6EP909LNNARJKC5KMSSPC419MGPBEC5N68RR1D0G54QBMCLP0KJ39CPII0QBJ41NMOP10EHK6ASJ55GG6UR34CLP20T38C5N20T38CKG78SJ5CLPGKMBFELN6EPBI41Q6GOBE41Q6GP90DLNNARJKC5KMSSPC41H6ORRND5N6E83CD5LMA83141H74PB5F9IGKGRFELN78SJP41P6UOB4ECM20T31DDII0RB541K6URB519A6U83KD1II0S3CC5HMA82941H6AR3FDPJGKLR5EDQ20LJ9E9JMIRJ9C4M20RBFELN78OB9DOG6QOBDC4558OBBCKG6QP90D1NMQP9C41HMUTBEEHP7I83IDTGM8SOA85M6O83DF4G6QPBDDTP6IPBJ41JM2T38CLP20SJFELN68838CLP0KJB9DPIN49RJ41M62P3P5GG76T3IC5N6EPBI41Q6U832DHQMA83NC5Q6ASGA8HGN4QP0C5N68834ELPN8U9C41O62QBEEHIM883FDOG78Q3541PMMU8A9LKN6T3P41Q62SRKCKG6UPH0DLNMURJJD1KMSP9C41Q6AOBICHP6US10D5N20RBP41INIP8A8DNNARJKE9SI0SJFC5I76B10EHGMMP90DLII0Q3FDLIGKL3F41Q6GP90E1M62OR5414I0OJ5DHNMSPOAATIN6T10APKN4PR9DPKM2B10DLNNARJKC5KMS83DC5MM22IKC5LMA83DCKG6GRRDCKM20ORFELN78SJP41P6UOB4EC54I838CLGN4838CLP20TJFD5HMAB10D5N20T38CKG6QRRIDPKMSPP0D1NNASH0EDK6A833C5M6OSP0DLIGKL38CKG74OB4D5NI0SJ5DLKMSP3J41MMA83FCOG6QU90D1NMQP90CPGN4831ETGNI2I1DPI20P3ID5R6IRJ741I6UTRE41Q6GP90E9NM2P1094G6EPBK41GI0PJ5CLM6IRJ719A6GOBK414I0SR8DTQMOP10D1GNCP90C9IMARH0D1NMQP90F5IN6T35E9I62U9C41SMASRKCLP68OBP191MUTBEEHP7I83IDTGM8SPC41Q62QR541MMA838DTMMA2IKDSG78Q3541O6OOB3CKG4I832CLM6URJ719BMASRK41B6ISJ7D5N6IO9C41MMUTBEEHGMIRH0DLGMQO8AAHGMMP90DLII0Q3FDLIIO833DTQMST3IF4G74RR1CHPGKGRFELN78SJP41P6UOB4ECM20T31DDII0RB541K6URB519A6U83KD1II0S3CC5HMA82941H6AR3FDPJGKLR5EDQ20LJ9E9JMIRJ9C4M20RBFELN78OB9DOG6QOBDC4558OBBCKG6QP90D1NMQP9C41HMUTBEEHP7I83IDTGM8SOAAHGMMP90DLII0Q3FDLIIO834DTRMS833DTQMST3IF4G74RR1CHPGKL31DDII0RB541K6URB55GG68RRNDOG66RRLDPQ74U90E9NM2P3J", "(Base32-Hex) Country Roads failed to encode properly")

    assert(encodeBase32Hex("Man", true) == "9LGMS", "(Base32-Hex) Man with padding disabled failed to encode into 9LGMS")
    assert(encodeBase32Hex("Ma", true) == "9LGG", "(Base32-Hex) Ma with padding disabled failed to encode into 9LGG")
    assert(encodeBase32Hex("M", true) == "9K", "(Base32-Hex) M with padding disabled failed to encode into 9K")
    assert(encodeBase32Hex("Baby shark", true) == "89GM4U90EDK62SJB", "(Base32-Hex) Baby shark with padding disabled failed to encode into 89GM4U90EDK62SJB")

    assert(encodeBase32Hex("") == "", "(Base32-Hex) Empty string failed to encode properly")
    assert(encodeBase32Hex("f") == "CO======", "(Base32-Hex) f failed to encode into CO======")
    assert(encodeBase32Hex("fo") == "CPNG====", "(Base32-Hex) fo failed to encode into CPNG====")
    assert(encodeBase32Hex("foo") == "CPNMU===", "(Base32-Hex) foo failed to encode into CPNMU===")
    assert(encodeBase32Hex("foob") == "CPNMUOG=", "(Base32-Hex) foob failed to encode into CPNMUOG=")
    assert(encodeBase32Hex("fooba") == "CPNMUOJ1", "(Base32-Hex) fooba failed to encode into CPNMUOJ1")
    assert(encodeBase32Hex("foobar") == "CPNMUOJ1E8======", "(Base32-Hex) foobar failed to encode into CPNMUOJ1E8======")

    assert(encodeBase32Hex("A\0B") == "84044===", "(Base32-Hex) A\\0B failed to encode into 84044===")
    assert(encodeBase32Hex("A\n\t\v") == "8450I2O=", "(Base32-Hex) A\\n\\t\\v failed to encode into 8450I2O=")
    assert(encodeBase32Hex("☺☻") == "SACBLOKONC======", "(Base32-Hex) ☺☻ failed to encode into SACBLOKONC======")
    assert(encodeBase32Hex("テスト") == "SE1ODOS2N7HO720=", "(Base32-Hex) テスト failed to encode into SE1ODOS2N7HO720=")

    assert(decodeBase32Hex("9LGMS===") == "Man", "(Base32-Hex) 9LGMS=== failed to decode into Man")
    assert(decodeBase32Hex("9LGG====") == "Ma", "(Base32-Hex) 9LGG==== failed to decode into Ma")
    assert(decodeBase32Hex("9K======") == "M", "(Base32-Hex) 9K====== failed to decode into M")
    assert(decodeBase32Hex("89GM4U90EDK62SJB") == "Baby shark", "(Base32-Hex) 89GM4U90EDK62SJB failed to decode into Baby shark")
    assert(decodeBase32Hex("85M6QRRJEGG6GPB1EPIMSB10ATIN6T10APKN4PR9DPKM22I2DHQMA82ID5I6EP909LNNARJKC5KMSSPC419MGPBEC5N68RR1D0G54QBMCLP0KJ39CPII0QBJ41NMOP10EHK6ASJ55GG6UR34CLP20T38C5N20T38CKG78SJ5CLPGKMBFELN6EPBI41Q6GOBE41Q6GP90DLNNARJKC5KMSSPC41H6ORRND5N6E83CD5LMA83141H74PB5F9IGKGRFELN78SJP41P6UOB4ECM20T31DDII0RB541K6URB519A6U83KD1II0S3CC5HMA82941H6AR3FDPJGKLR5EDQ20LJ9E9JMIRJ9C4M20RBFELN78OB9DOG6QOBDC4558OBBCKG6QP90D1NMQP9C41HMUTBEEHP7I83IDTGM8SOA85M6O83DF4G6QPBDDTP6IPBJ41JM2T38CLP20SJFELN68838CLP0KJB9DPIN49RJ41M62P3P5GG76T3IC5N6EPBI41Q6U832DHQMA83NC5Q6ASGA8HGN4QP0C5N68834ELPN8U9C41O62QBEEHIM883FDOG78Q3541PMMU8A9LKN6T3P41Q62SRKCKG6UPH0DLNMURJJD1KMSP9C41Q6AOBICHP6US10D5N20RBP41INIP8A8DNNARJKE9SI0SJFC5I76B10EHGMMP90DLII0Q3FDLIGKL3F41Q6GP90E1M62OR5414I0OJ5DHNMSPOAATIN6T10APKN4PR9DPKM2B10DLNNARJKC5KMS83DC5MM22IKC5LMA83DCKG6GRRDCKM20ORFELN78SJP41P6UOB4EC54I838CLGN4838CLP20TJFD5HMAB10D5N20T38CKG6QRRIDPKMSPP0D1NNASH0EDK6A833C5M6OSP0DLIGKL38CKG74OB4D5NI0SJ5DLKMSP3J41MMA83FCOG6QU90D1NMQP90CPGN4831ETGNI2I1DPI20P3ID5R6IRJ741I6UTRE41Q6GP90E9NM2P1094G6EPBK41GI0PJ5CLM6IRJ719A6GOBK414I0SR8DTQMOP10D1GNCP90C9IMARH0D1NMQP90F5IN6T35E9I62U9C41SMASRKCLP68OBP191MUTBEEHP7I83IDTGM8SPC41Q62QR541MMA838DTMMA2IKDSG78Q3541O6OOB3CKG4I832CLM6URJ719BMASRK41B6ISJ7D5N6IO9C41MMUTBEEHGMIRH0DLGMQO8AAHGMMP90DLII0Q3FDLIIO833DTQMST3IF4G74RR1CHPGKGRFELN78SJP41P6UOB4ECM20T31DDII0RB541K6URB519A6U83KD1II0S3CC5HMA82941H6AR3FDPJGKLR5EDQ20LJ9E9JMIRJ9C4M20RBFELN78OB9DOG6QOBDC4558OBBCKG6QP90D1NMQP9C41HMUTBEEHP7I83IDTGM8SOAAHGMMP90DLII0Q3FDLIIO834DTRMS833DTQMST3IF4G74RR1CHPGKL31DDII0RB541K6URB55GG68RRNDOG66RRLDPQ74U90E9NM2P3J") == "Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads", "(Base32-Hex) Country Roads failed to decode properly")

    assert(decodeBase32Hex("9LGMS") == "Man", "(Base32-Hex) 9LGMS failed to decode into Man")
    assert(decodeBase32Hex("9LGG") == "Ma", "(Base32-Hex) 9LGG failed to decode into Ma")
    assert(decodeBase32Hex("9K") == "M", "(Base32-Hex) 9K failed to decode into M")

    assert(decodeBase32Hex("") == "", "(Base32-Hex) Empty string failed to decode")
    assert(decodeBase32Hex("CO======") == "f", "(Base32-Hex) CO====== failed to decode into f")
    assert(decodeBase32Hex("CPNG====") == "fo", "(Base32-Hex) CPNG==== failed to decode into fo")
    assert(decodeBase32Hex("CPNMU===") == "foo", "(Base32-Hex) CPNMU=== failed to decode into foo")
    assert(decodeBase32Hex("CPNMUOG=") == "foob", "(Base32-Hex) CPNMUOG= failed to decode into foob")
    assert(decodeBase32Hex("CPNMUOJ1") == "fooba", "(Base32-Hex) CPNMUOJ1 failed to decode into fooba")
    assert(decodeBase32Hex("CPNMUOJ1E8======") == "foobar", "(Base32-Hex) CPNMUOJ1E8====== failed to decode into foobar")

    assert(decodeBase32Hex("84044===") == "A\0B", "(Base32-Hex) 84044=== failed to decode into A\\0B")
    assert(decodeBase32Hex("8450I2O=") == "A\n\t\v", "(Base32-Hex) 8450I2O= failed to decode into A\\n\\t\\v")
    assert(decodeBase32Hex("SACBLOKONC======") == "☺☻", "(Base32-Hex) SACBLOKONC====== failed to decode into ☺☻")
    assert(decodeBase32Hex("SE1ODOS2N7HO720=") == "テスト", "(Base32-Hex) SE1ODOS2N7HO720= failed to decode into テスト")

    -- print("Base32 tests completed. Took", tick()-t)
end

return {
    encode = encodeBase32,
    decode = decodeBase32,
    hexEncode = encodeBase32Hex,
    hexDecode = decodeBase32Hex,
}