-------------------------------------------------------
-- All levels (Mining) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Mining"] then RR_DATA["levels"]["Mining"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 29354,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 35,
		["name"] = {
			["Chinese"] = "采矿 (大师级)",
			["English"] = "Mining (Master)",
			["French"] = "Minage (Maître)",
			["German"] = "Bergbau (Meister)",
			["Korean"] = "채광 (대가)",
			["Mexican"] = "Minería (Maestro)",
			["Portuguese"] = "Mineração (Mestre)",
			["Russian"] = "Горное дело (Мастер)",
			["Spanish"] = "Minería (Maestro)",
			["Taiwanese"] = "採礦 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18747,
				18779,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Mining"], level)
end
