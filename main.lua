require "lfs"
local curDir = lfs.currentdir()
local b = [[\]]
local function checkValidDir(dir) return dir ~= "." and dir ~= ".." end
local checkFilters = { -- {"trigger", "pretty name"}
	{"function", 							"Functions:\t\t",			false},
	{"if",									"If Statements:\t\t", 		false},
	{"hook.Add", 							"Hooks:\t\t\t", 			false},
	{"net.Send", 							"Net Messages Sent:\t", 	false},
	{"umsg.End",							"UserMessages Sent:\t", 	true},
	{"ai.GetScheduleID", 					"Ai depricated:\t\t",		true},
	{"ai.GetTaskID", 						"Ai depricated:\t\t",		true},
	{"IsAscendingOrDescendingLadder",		"CLuaLocomotion:\t\t",		true},
	{"GetDrawBackground",					"DPanel Depricated\t",		true},
	{"SetDrawBackground",					"DPanel Depricated\t",		true},
	{"GetNetworked",						"Get Network Depricated\t",	true},
	{"SetNetworked",						"Get Network Depricated\t",	true}
}

local detailLog = "" -- For later printing

local depricatedFiles = {}
local lines 		= 0
local noteMode 		= false
local detailMode	= false
local checkForDeprication = false

local mostLines 	= 0
local LineFile 		= ""

local biggestSize = 0
local biggestFile = ""

-- explode() function from the lua wiki http://lua-users.org/wiki/SplitJoin FunctionL PHP-like explode
local function explode(d,p)
  local t, ll
  t={}
  ll=0
  if(#p == 1) then return {p} end
    while true do
      l=string.find(p,d,ll,true)
      if l~=nil then
        table.insert(t, string.sub(p,ll,l-1))
        ll=l+1
      else
        table.insert(t, string.sub(p,ll))
        break
      end
    end
  return t
end

local function processBytes(bytes, kilobytes)
	while bytes >= 1024 do
		bytes = bytes - 1024
		kilobytes = kilobytes + 1
	end
	return bytes, kilobytes
end

local function noteCheck(line)
	local len = string.len(line)
	if (string.find(line, "--", 1, len) or string.find(line, "//", 1, len)) and string.find(line, "--[[", 1, len) == nil then
		if noteMode == true then return "" end
		local s,f

		if string.find(line, "--", 1, len) then
			s,f = string.find(line, "--", 1, len)
		else
			s,f = string.find(line, "//", 1, len)
		end

		if s > 1 then
			local nonNotedString = string.sub(line, 1, (s - 1))
			return nonNotedString
		else
			return ""
		end
	elseif string.find(line, "--[[", 1, len) or string.find(line, "/*", 1, len) then
		if noteMode == true then return "" end
		local s,f
		noteMode = true

		if string.find(line, "--[[", 1, len) then
			s,f = string.find(line, "--[[", 1, len)
		else
			s,f = string.find(line, "/*", 1, len)
		end

		if s > 1 then
			local nonNotedString = string.sub(line, 1, (s - 1))
			return nonNotedString
		else
			return ""
		end
	elseif (string.find(line, "]]", 1, len) or string.find (line, "*/", 1, len)) and noteMode == true then
		local s,f
		noteMode = false

		if string.find(line, "]]", 1, len) then
			s,f = string.find(line, "]]", 1, len)
		else
			s,f = string.find(line, "*/", 1, len)
		end

		if f == len then
			return ""
		else
			local nonNotedString = string.sub(line, f, len)
			return nonNotedString
		end
	else
		if noteMode == true then
			return ""
		else
			return line
		end
	end
end

local function scanDir(dir)	
	for fl in lfs.dir(dir) do
		if checkValidDir(fl) then
			if lfs.attributes(dir..b..fl, "mode") == "directory" then
				scanDir(dir..b..fl)
			elseif string.sub(fl, (string.len(fl) - 3), string.len(fl)) == ".lua" then
				if (dir..b..fl) == (curDir..b..fl) then return end
				local f = io.open(dir..b..fl, "rb")
				local unprocessed = f:read("*all")
				local b,k = processBytes(string.len(unprocessed), 0)
				local content = explode("\n", unprocessed)
				f:close()

				if detailMode == true then
					print(fl..":\t\t\t"..k..b.."        "..#content)
					detailLog = (detailLog..fl..":\t\t\t"..k..b.."        "..#content.."\n")

					if #content > mostLines then
						mostLines = #content
						LineFile = fl
					end

					if string.len(unprocessed) > biggestSize then
						biggestSize = string.len(unprocessed)
						biggestFile = fl
					end
				end
				
				for k,v in pairs(content) do
					for i,r in pairs(checkFilters) do
						if string.find(noteCheck(v), r[1]) ~= nil then
							if #r == 3 then
								table.insert(r, 1)
							else
								local count = r[4]
								table.remove(r, 4)
								table.insert(r, (count + 1))
							end

							if r[3] == true then
								table.insert(depricatedFiles, {(dir..b..fl), k, r[1]})
							end
						end
					end
				end
				lines = lines + #content
			end
		end
	end
end

print("Use Detail Mode? (y/n)")

if io.read() == "y" then -- No answer = No let me at that sweet sweet data
	detailMode = true
end

print("Check For Depricated Functions/Variables? (y/n)")

if io.read() == "y" then
	checkForDeprication = true
end

print("Processing...\n")
if detailMode == true then
	print("File Name\t\tKb  Mb\t\tLines")	
end
scanDir(curDir)

for k,v in pairs(checkFilters) do
	if #v == 3 then
		table.insert(v, 0)
	end
end

local dirToTable = explode([[\]], curDir)
print("\nStats for the folder "..dirToTable[#dirToTable]..":\n")
print("lines of code:\t\t"..lines)

for k,v in pairs(checkFilters) do
	if v[3] == true then
		if checkForDeprication == true then
			print(v[2]..v[4])
		end
	else
		print(v[2]..v[4])
	end
end

if checkForDeprication == true then
	if #depricatedFiles > 0 then
		print("\nDeprecated functions/variables detected (File path, Line, function)")
		for k,v in pairs(depricatedFiles) do
			print(v[1].."\t"..v[2].."\t"..v[3])
		end
	else
		print("No depricated functions or variables found! Yay!")
	end
end

if detailMode == true then
	local b,k = processBytes(biggestSize, 0)
	print("\nFile with most lines:\t"..LineFile.."\t("..mostLines..")")
	print("File with biggest size:\t"..biggestFile.."\t("..k.."KB   "..b.."b)")
end

print("Write results to a text file in the currect directory? (y/n)")

if io.read() == "y" then
	local textToPrint = ("Thank you for using luastats! :)\n")
	textToPrint = (textToPrint.."\nStats for the folder "..dirToTable[#dirToTable]..":\nlines of code:\t\t"..lines.."\n")
	textToPrint = (textToPrint..detailLog)

	for k,v in pairs(checkFilters) do
		if v[3] == true then
			if checkForDeprication == true then
				textToPrint = (textToPrint..v[2]..v[4].."\n")
			end
		else
			textToPrint = (textToPrint..v[2]..v[4].."\n")
		end
	end

	if checkForDeprication == true then
		if #depricatedFiles > 0 then
			textToPrint = (textToPrint.."\nDeprecated functions/variables detected (File path, Line, function)\n")
			for k,v in pairs(depricatedFiles) do
				textToPrint = (textToPrint..v[1].."\t"..v[2].."\t"..v[3].."\n")
			end
		else
			textToPrint = (textToPrint.."No depricated functions or variables found! Yay!\n")
		end
	end

	if detailMode == true then
		local b,k = processBytes(biggestSize, 0)
		textToPrint = (textToPrint.."\nFile with most lines:\t"..LineFile.."\t("..mostLines..")\n")
		textToPrint = (textToPrint.."File with biggest size:\t"..biggestFile.."\t("..k.."KB   "..b.."b)\n")
	end

	local fl = io.open("luaStats.log", "w")
	fl:write(textToPrint)
	fl:close()
end
