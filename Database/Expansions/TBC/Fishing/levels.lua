-------------------------------------------------------
-- All levels (Fishing) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Fishing"] then RR_DATA["levels"]["Fishing"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 33095,
		["items"] = {
			27532,
		},
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 45,
		["name"] = {
			["Chinese"] = "钓鱼 (大师级)",
			["English"] = "Fishing (Master)",
			["French"] = "Pêche (Maître)",
			["German"] = "Angeln (Meister)",
			["Korean"] = "낚시 (대가)",
			["Mexican"] = "Pesca (Maestro)",
			["Portuguese"] = "Pesca (Mestre)",
			["Russian"] = "Рыбная ловля (Мастер)",
			["Spanish"] = "Pesca (Maestro)",
			["Taiwanese"] = "釣魚 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Fishing"], level)
end
