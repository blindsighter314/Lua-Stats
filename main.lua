require "lfs"
local curDir = lfs.currentdir()
local b = [[\]]
local function checkValidDir(dir) return dir ~= "." and dir ~= ".." and dir ~= "main.lua" end
local checkFilters = { -- {"trigger", "pretty name"}
	{"function(", 	"Functions:\t\t"},
	{"hook.Add", 	"Hooks:\t\t\t"},
	{"net.Send", 	"Net Messages Sent\t"}
}
local lines 	= 0

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

local function scanDir(dir)
	for fl in lfs.dir(dir) do
		if checkValidDir(fl) then
			if lfs.attributes(dir..b..fl, "mode") == "directory" then
				scanDir(dir..b..fl)
			elseif string.sub(fl, (string.len(fl) - 3), string.len(fl)) == ".lua" then
				local f = io.open(dir..b..fl, "rb")
				local content = explode("\n", f:read("*all"))
				f:close()
				for k,v in pairs(content) do
					for i,r in pairs(checkFilters) do
						if string.find(v, r[1]) ~= nil then
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
print("Processing...\n")
scanDir(curDir)

for k,v in pairs(checkFilters) do
	if #v == 2 then
		table.insert(v, 0)
	end
end

local dirToTable = explode([[\]], curDir)
print("Stats for the folder "..dirToTable[#dirToTable]..":\n")
print("lines of code:\t\t"..lines)

for k,v in pairs(checkFilters) do
	print(v[2]..v[3])
end
