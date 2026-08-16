-------------------------------------------------------
-- All levels (Leatherworking) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Leatherworking"] then RR_DATA["levels"]["Leatherworking"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 32549,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "制皮 (大师级)",
			["English"] = "Leatherworking (Master)",
			["French"] = "Travail du cuir (Maître)",
			["German"] = "Lederverarbeitung (Meister)",
			["Korean"] = "가죽세공 (대가)",
			["Mexican"] = "Peletería (Maestro)",
			["Portuguese"] = "Couraria (Mestre)",
			["Russian"] = "Кожевничество (Мастер)",
			["Spanish"] = "Peletería (Maestro)",
			["Taiwanese"] = "製皮 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18754,
				18771,
				19187,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Leatherworking"], level)
end
