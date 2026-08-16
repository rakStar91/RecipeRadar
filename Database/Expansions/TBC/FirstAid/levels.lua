-------------------------------------------------------
-- All levels (First Aid) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["First Aid"] then RR_DATA["levels"]["First Aid"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 27028,
		["items"] = {
			22012,
		},
		["max_skill"] = 375,
		["min_skill"] = 300,
		["min_xp_level"] = 35,
		["name"] = {
			["Chinese"] = "急救 (大师级)",
			["English"] = "First Aid (Master)",
			["French"] = "Secourisme (Maître)",
			["German"] = "Erste Hilfe (Meister)",
			["Korean"] = "응급치료 (대가)",
			["Mexican"] = "Primeros auxilios (Maestro)",
			["Portuguese"] = "Primeiros Socorros (Mestre)",
			["Russian"] = "Первая помощь (Мастер)",
			["Spanish"] = "Primeros auxilios (Maestro)",
			["Taiwanese"] = "急救 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["First Aid"], level)
end
