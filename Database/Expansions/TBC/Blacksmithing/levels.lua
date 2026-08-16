-------------------------------------------------------
-- All levels (Blacksmithing) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Blacksmithing"] then RR_DATA["levels"]["Blacksmithing"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 29844,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "锻造 (大师级)",
			["English"] = "Blacksmithing (Master)",
			["French"] = "Forge (Maître)",
			["German"] = "Schmiedekunst (Meister)",
			["Korean"] = "대장기술 (대가)",
			["Mexican"] = "Herrería (Maestro)",
			["Portuguese"] = "Ferraria (Mestre)",
			["Russian"] = "Кузнечное дело (Мастер)",
			["Spanish"] = "Herrería (Maestro)",
			["Taiwanese"] = "鍛造 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				16583,
				16823,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Blacksmithing"], level)
end
