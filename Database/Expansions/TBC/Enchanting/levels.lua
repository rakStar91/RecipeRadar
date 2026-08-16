-------------------------------------------------------
-- All levels (Enchanting) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Enchanting"] then RR_DATA["levels"]["Enchanting"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 28029,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "附魔 (大师级)",
			["English"] = "Enchanting (Master)",
			["French"] = "Enchantement (Maître)",
			["German"] = "Verzauberkunst (Meister)",
			["Korean"] = "마법부여 (대가)",
			["Mexican"] = "Encantamiento (Maestro)",
			["Portuguese"] = "Encantamento (Mestre)",
			["Russian"] = "Наложение чар (Мастер)",
			["Spanish"] = "Encantamiento (Maestro)",
			["Taiwanese"] = "附魔 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18753,
				18773,
				19252,
				19540,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Enchanting"], level)
end
