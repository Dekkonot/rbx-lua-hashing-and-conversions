-- I had to include it. It's easy to implement, so why not.
--[[
local rot13 = function(msg)
    return (msg:gsub(".", function(c)
        local l = bit32.btest(c:byte(), 32) and 97 or 65
        return c:upper() == c:lower() and c or c.char((c:byte()-l+13)%26+l)
    end))
end
]]

local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

local CHARACTER_MAP = {
    ["A"] = "N", ["B"] = "O", ["C"] = "P", ["D"] = "Q", ["E"] = "R", ["F"] = "S", ["G"] = "T", ["H"] = "U",
    ["I"] = "V", ["J"] = "W", ["K"] = "X", ["L"] = "Y", ["M"] = "Z", ["N"] = "A", ["O"] = "B", ["P"] = "C",
    ["Q"] = "D", ["R"] = "E", ["S"] = "F", ["T"] = "G", ["U"] = "H", ["V"] = "I", ["W"] = "J", ["X"] = "K",
    ["Y"] = "L", ["Z"] = "M", ["a"] = "n", ["b"] = "o", ["c"] = "p", ["d"] = "q", ["e"] = "r", ["f"] = "s",
    ["g"] = "t", ["h"] = "u", ["i"] = "v", ["j"] = "w", ["k"] = "x", ["l"] = "y", ["m"] = "z", ["n"] = "a",
    ["o"] = "b", ["p"] = "c", ["q"] = "d", ["r"] = "e", ["s"] = "f", ["t"] = "g", ["u"] = "h", ["v"] = "i",
    ["w"] = "j", ["x"] = "k", ["y"] = "l", ["z"] = "m",
}

local function rot13(msg)
    return (string.gsub(msg, "%a", CHARACTER_MAP))
end

if ASSERTIONS_ENABLED then
    assert(rot13("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") == "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm", "Full alphabet failed to shift properly")
    assert(rot13("NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm") == "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "Shifted full alphabet failed to shift properly")
    assert(rot13("I am running out of memes. Sorry! D:") == "V nz ehaavat bhg bs zrzrf. Fbeel! Q:", "Running out of memes message failed to shift properly")
end

return rot13