-- http://base91.sourceforge.net/
-- Based roughly on the reference implementation, though this is entirely written from scratch
-- Licensed under WTFPL (http://www.wtfpl.net/txt/copying/)

local ASSERTIONS_ENABLED = false -- Whether to run several checks when the module is first loaded
local MAKE_JSON_SAFE = false -- If this is true, " will be replaced by ' in the encoding

local CHAR_SET = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~"]]

local encode_CharSet = {}
local decode_CharSet = {}
for i = 1, 91 do
    encode_CharSet[i-1] = string.sub(CHAR_SET, i, i)
    decode_CharSet[string.sub(CHAR_SET, i, i)] = i-1
end

if MAKE_JSON_SAFE then
    encode_CharSet[90] = "'"
    decode_CharSet['"'] = nil
    decode_CharSet["'"] = 90
end

local function encodeBase91(input)
    local output = {}
    local c = 1

    local counter = 0
    local numBits = 0

    for i = 1, #input do
        counter = bit32.bor(counter, bit32.lshift(string.byte(input, i), numBits))
        numBits = numBits+8
        if numBits > 13 then
            local entry = bit32.band(counter, 8191) -- 2^13-1 = 8191
            if entry > 88 then -- Voodoo magic (https://www.reddit.com/r/learnprogramming/comments/8sbb3v/understanding_base91_encoding/e0y85ot/)
                counter = bit32.rshift(counter, 13)
                numBits = numBits-13
            else
                entry = bit32.band(counter, 16383) -- 2^14-1 = 16383
                counter = bit32.rshift(counter, 14)
                numBits = numBits-14
            end
            output[c] = encode_CharSet[entry%91]..encode_CharSet[math.floor(entry/91)]
            c = c+1
        end
    end

    if numBits > 0 then
        output[c] = encode_CharSet[counter%91]
        if numBits > 7 or counter > 90 then
            output[c+1] = encode_CharSet[math.floor(counter/91)]
        end
    end

    return table.concat(output)
end

local function decodeBase91(input)
    local output = {}
    local c = 1

    local counter = 0
    local numBits = 0
    local entry = -1

    for i = 1, #input do
        if decode_CharSet[string.sub(input, i, i)] then
            if entry == -1 then
                entry = decode_CharSet[string.sub(input, i, i)]
            else
                entry = entry+decode_CharSet[string.sub(input, i, i)]*91
                counter = bit32.bor(counter, bit32.lshift(entry, numBits))
                if bit32.band(entry, 8191) > 88 then
                    numBits = numBits+13
                else
                    numBits = numBits+14
                end

                while numBits > 7 do
                    output[c] = string.char(counter%256)
                    c = c+1
                    counter = bit32.rshift(counter, 8)
                    numBits = numBits-8
                end
                entry = -1
            end
        end
    end

    if entry ~= -1 then
        output[c] = string.char(bit32.bor(counter, bit32.lshift(entry, numBits))%256)
    end

    return table.concat(output)
end

if ASSERTIONS_ENABLED then
    if MAKE_JSON_SAFE then
        encode_CharSet[90] = '"'
        decode_CharSet["'"] = nil
        decode_CharSet['"'] = 90
    end

    -- local t = tick()

    assert(encodeBase91("Hello, World!") == ">OwJh>}AQ;r@@Y?F", "(Base91) Hello World failed to encode into >OwJh>}AQ;r@@Y?F")
    assert(encodeBase91("Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads") == 'riM=Q[yCd#}uq9:mu"I80oZBHeq@]0m$"u|WGmgP>vG:1p;RqSO9<mIEZ2Q[}AcHd,EIlT8&ZEkLUa^gp@((uS309M1oyqwJ,Wzv;R90{BHnoM_1:WzvLR4tJF8j44zgc,.688O;4^7jXBTKu)mCmU40!5Qn9o(gK:bT:HAww^"pxoIJE<S$;R2u_XUoQPYhcH?`6U)/ZQmLprzIO[}A%gv;UCS$ztf^rmWd]:/Wzv;R#(BQ{iKBnGB*(*1Tq3U?5jw5>vH:[pwSZ6axcLkre3@[+0lTr#x8Xii4G<d,=/;Ro4O98ju"L^apr5zg<W]{LRa.$LGmRBJg<WweW$`+[80oEUzIq/rN$F(&9.cj>W_1fHe0m$@+sjlLAEefZf1RrUEv4^7jXB&=/W9*7%ztsQ_o)z`"SiSggZ5=SC4!i.hQ6PhtGf7=!e7Ra&=E<oTPh+z;_6y6c.hQmLIENKg,J`ASr#8^;m+XZ2e,}A%gt)BZL%L)9M;m_k9KL,.e<ur&9.`o1,>vi>6YaUXtgQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.$LgLTP01:WmeKUM<NQ|i?ieZ7=TXi#ztz^VowaU=,W!{6U6tFF8j.IzIX<wCS$4O#D8j"yzIL:oCH%=#N.cjYBJg,WSk$y+@mBQnYP>vt)uCI!Gv<b?WqM=Cp@GkxSq3nuPn#o=Cq/UCH%CvlE%ZEU^I;WMC}!20BQ;mYdjHu)yC>M^,g^apoM=Cu)&e#F10},kLfrLg,W.eaU!0DyWiIjeZh,DZ<RYzwP!D`qe3@[N1$F(&ax0ou"gQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.TiLn9oW3l`|L3$PzHycLIE{f,Wwe#F!&G97DLr=Cq/UC%TBv58jL;"08Km3oJ2T9JTrULfMbikxo+fTf=/2$f%hQFlTBJg_<k6,7B9pEimKB9<|<(*8y7&9.`o1,>vi>6YaURcDm8j_k^IV/1;;RXtP^"pTBV<1]_YM%9t,^Xiy2`"UiWPgZe,%t2$60{BTj_%$J%*0emT}+eFMoDEf<c', "(Base91) Country Roads failed to encode properly")

    assert(encodeBase91("") == '', "(Base91) Empty string failed to encode properly")
    assert(encodeBase91("f") == 'LB', "(Base91) f failed to encode properly")
    assert(encodeBase91("fo") == 'drD', "(Base91) fo failed to encode properly")
    assert(encodeBase91("foo") == 'dr.J', "(Base91) foo failed to encode properly")
    assert(encodeBase91("foob") == 'dr/2Y', "(Base91) foob failed to encode properly")
    assert(encodeBase91("fooba") == 'dr/2s)A', "(Base91) fooba failed to encode properly")
    assert(encodeBase91("foobar") == 'dr/2s)uC', "(Base91) foobar failed to encode properly")

    assert(encodeBase91("A\0B") == '%A]C', "(Base91) A\\0B failed to encode into %A]C")
    assert(encodeBase91("A\n\t\v") == '=cc)C', "(Base91) A\\n\\t\\v failed to encode into =cc)C")
    assert(encodeBase91("☺☻") == 'A+l9tRLE', "(Base91) ☺☻ (smiley faces) failed to encode into A+l9tRLE")
    assert(encodeBase91("テスト") == '`Kf?CC|URX)', "(Base91) テスト (japanese characters) failed to encode into `Kf?CC|URX)")

    assert(decodeBase91('>OwJh>}AQ;r@@Y?F') == "Hello, World!", "(Base91) >OwJh>}AQ;r@@Y?F failed to decode into Hello, World!")
    assert(decodeBase91('riM=Q[yCd#}uq9:mu"I80oZBHeq@]0m$"u|WGmgP>vG:1p;RqSO9<mIEZ2Q[}AcHd,EIlT8&ZEkLUa^gp@((uS309M1oyqwJ,Wzv;R90{BHnoM_1:WzvLR4tJF8j44zgc,.688O;4^7jXBTKu)mCmU40!5Qn9o(gK:bT:HAww^"pxoIJE<S$;R2u_XUoQPYhcH?`6U)/ZQmLprzIO[}A%gv;UCS$ztf^rmWd]:/Wzv;R#(BQ{iKBnGB*(*1Tq3U?5jw5>vH:[pwSZ6axcLkre3@[+0lTr#x8Xii4G<d,=/;Ro4O98ju"L^apr5zg<W]{LRa.$LGmRBJg<WweW$`+[80oEUzIq/rN$F(&9.cj>W_1fHe0m$@+sjlLAEefZf1RrUEv4^7jXB&=/W9*7%ztsQ_o)z`"SiSggZ5=SC4!i.hQ6PhtGf7=!e7Ra&=E<oTPh+z;_6y6c.hQmLIENKg,J`ASr#8^;m+XZ2e,}A%gt)BZL%L)9M;m_k9KL,.e<ur&9.`o1,>vi>6YaUXtgQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.$LgLTP01:WmeKUM<NQ|i?ieZ7=TXi#ztz^VowaU=,W!{6U6tFF8j.IzIX<wCS$4O#D8j"yzIL:oCH%=#N.cjYBJg,WSk$y+@mBQnYP>vt)uCI!Gv<b?WqM=Cp@GkxSq3nuPn#o=Cq/UCH%CvlE%ZEU^I;WMC}!20BQ;mYdjHu)yC>M^,g^apoM=Cu)&e#F10},kLfrLg,W.eaU!0DyWiIjeZh,DZ<RYzwP!D`qe3@[N1$F(&ax0ou"gQ*lKBJg,W!{W$4Oq]kL,X^I>>AIs!ztTDui?i/2(.3n;!+/`)Dl{UZ2N:7*8y$&9.`oja$J)<Z;LRRcDm8j_k^IV/1;;RXtL^apr5zg<W]{LRa.TiLn9oW3l`|L3$PzHycLIE{f,Wwe#F!&G97DLr=Cq/UC%TBv58jL;"08Km3oJ2T9JTrULfMbikxo+fTf=/2$f%hQFlTBJg_<k6,7B9pEimKB9<|<(*8y7&9.`o1,>vi>6YaURcDm8j_k^IV/1;;RXtP^"pTBV<1]_YM%9t,^Xiy2`"UiWPgZe,%t2$60{BTj_%$J%*0emT}+eFMoDEf<c') == "Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads", "(Base91) Country Roads failed to decode properly")

    assert(decodeBase91('') == "", "(Base91) Empty string failed to encode properly")
    assert(decodeBase91('LB') == "f", "(Base91) LB failed to decode into f")
    assert(decodeBase91('drD') == "fo", "(Base91) drD failed to decode into fo")
    assert(decodeBase91('dr.J') == "foo", "(Base91) dr.J failed to decode into foo")
    assert(decodeBase91('dr/2Y') == "foob", "(Base91) dr/2Y failed to decode into foob")
    assert(decodeBase91('dr/2s)A') == "fooba", "(Base91) dr/2s)A failed to decode into fooba")
    assert(decodeBase91('dr/2s)uC') == "foobar", "(Base91) dr/2s)uC failed to decode into foobar")

    assert(decodeBase91('%A]C') == "A\0B", "(Base91) %A]C failed to decode into 0\\0")
    assert(decodeBase91('=cc)C') == "A\n\t\v", "(Base91) =cc)C failed to decode into A\\n\\t\\v")
    assert(decodeBase91('A+l9tRLE') == "☺☻", "(Base91) A+l9tRLE failed to to decode into ☺☻ (smiley faces)")
    assert(decodeBase91('`Kf?CC|URX)') == "テスト", "(Base91) `Kf?CC|URX) failed to encode into テスト (japanese characters)")

    -- print("Base91 tests completed. Took", tick()-t)

    if MAKE_JSON_SAFE then
        encode_CharSet[90] = "'"
        decode_CharSet['"'] = nil
        decode_CharSet["'"] = 90
    end
end

return {
    encode = encodeBase91,
    decode = decodeBase91,
}