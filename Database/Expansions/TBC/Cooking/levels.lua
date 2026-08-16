-------------------------------------------------------
-- All levels (Cooking) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Cooking"] then RR_DATA["levels"]["Cooking"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 33359,
		["items"] = {
			27736,
		},
		["max_skill"] = 375,
		["min_skill"] = 300,
		["min_xp_level"] = 35,
		["name"] = {
			["Chinese"] = "烹饪 (大师级)",
			["English"] = "Cooking (Master)",
			["French"] = "Cuisine (Maître)",
			["German"] = "Kochkunst (Meister)",
			["Korean"] = "요리 (대가)",
			["Mexican"] = "Cocina (Maestro)",
			["Portuguese"] = "Culinária (Mestre)",
			["Russian"] = "Кулинария (Мастер)",
			["Spanish"] = "Cocina (Maestro)",
			["Taiwanese"] = "烹飪 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Cooking"], level)
end
