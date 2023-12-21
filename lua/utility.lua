--- @generic V
--- @generic K
--- @param tables {[K]: V}[]
--- @return {[K]: V}
local function mergeTables(tables)
	local res = {}
	for _, t in pairs(tables) do
		for k, v in pairs(t) do
			res[k] = v
		end
	end

	return res
end


return {mergeTables = mergeTables}
