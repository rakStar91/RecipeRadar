-------------------------------------------------------
-- All levels (Alchemy) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Alchemy"] then RR_DATA["levels"]["Alchemy"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 28596,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "炼金术 (大师级)",
			["English"] = "Alchemy (Master)",
			["French"] = "Alchimie (Maître)",
			["German"] = "Alchimie (Meister)",
			["Korean"] = "연금술 (대가)",
			["Mexican"] = "Alquimia (Maestro)",
			["Portuguese"] = "Alquimia (Mestre)",
			["Russian"] = "Алхимия (Мастер)",
			["Spanish"] = "Alquimia (Maestro)",
			["Taiwanese"] = "鍊金術 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				16588,
				18802,
				19052,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Alchemy"], level)
end
