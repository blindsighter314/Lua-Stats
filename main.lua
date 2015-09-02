require "lfs"
local curDir = lfs.currentdir()
local b = [[\]]
local function checkValidDir(dir) return dir ~= "." and dir ~= ".." and dir ~= "main.lua" end
local checkFilters = { -- {"trigger", "pretty name"}
	{"function", 	"Functions:\t\t"},
	{"if",			"If Statements:\t\t"},
	{"hook.Add", 	"Hooks:\t\t\t"},
	{"net.Send", 	"Net Messages Sent\t"}
}
local lines 		= 0
local noteMode 		= false
local detailMode	= false

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
				local f = io.open(dir..b..fl, "rb")
				local unprocessed = f:read("*all")
				local b,k = processBytes(string.len(unprocessed), 0)
				local content = explode("\n", unprocessed)
				f:close()

				if detailMode == true then
					print(fl..":\t\t\t"..k..b.."        "..#content)

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
							if #r == 2 then
								table.insert(r, 1)
							else
								local count = r[3]
								table.remove(r, 3)
								table.insert(r, (count + 1))
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

print("Processing...\n")
if detailMode == true then
	print("File Name\t\tKb  Mb\t\tLines")	
end
scanDir(curDir)

for k,v in pairs(checkFilters) do
	if #v == 2 then
		table.insert(v, 0)
	end
end

local dirToTable = explode([[\]], curDir)
print("\nStats for the folder "..dirToTable[#dirToTable]..":\n")
print("lines of code:\t\t"..lines)

for k,v in pairs(checkFilters) do
	print(v[2]..v[3])
end

if detailMode == true then
	print("\nFile with most lines:\t"..LineFile.."\t("..mostLines..")")
	print("File with biggest size:\t"..biggestFile.."\t("..biggestSize..")")
end