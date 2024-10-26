local expect = require("cc.expect").expect
local wrap = require("cc.strings").wrap

function slowWrite(text, rate, punctuationRate)
    expect(2, rate, "number", "nil")
	expect(3, punctuationRate, "number", "nil")
    rate = rate or 20
	prate = prate or 5
    if rate < 0 then
        error("Rate must be positive", 2)
    end
	if rate < 0 then
        error("Punctuation Rate must be positive", 2)
    end

    local wrapped_lines = wrap(tostring(text), (term.getSize()))
    local wrapped_str = table.concat(wrapped_lines, "\n")

    for n = 1, #wrapped_str do
		local puncTable = {".", ",", ":", ";"}
		local isPunc = false
		for k, v in pairs(puncTable) do
			if wrapped_str:sub(n, n) == v then isPunc = true break end
		end
        write(wrapped_str:sub(n, n))
		if isPunc then sleep(1 / prate) else sleep(1 / rate) end
    end
end

function slowPrint(sText, nRate, nPuncRate)
    slowWrite(sText, nRate, nPuncRate)
    print()
end

if term.isColour() then
    term.setTextColour(colours.purple)
end

print("Rebooting...")
term.setTextColour(colours.white)
sleep(3)
os.reboot()
