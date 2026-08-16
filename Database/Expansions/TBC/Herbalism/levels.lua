-------------------------------------------------------
-- All levels (Herbalism) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Herbalism"] then RR_DATA["levels"]["Herbalism"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 28695,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 35,
		["name"] = {
			["Chinese"] = "草药学 (大师级)",
			["English"] = "Herbalism (Master)",
			["French"] = "Herboristerie (Maître)",
			["German"] = "Kräuterkunde (Meister)",
			["Korean"] = "약초 채집 (대가)",
			["Mexican"] = "Herboristería (Maestro)",
			["Portuguese"] = "Herborismo (Mestre)",
			["Russian"] = "Травничество (Мастер)",
			["Spanish"] = "Herboristería (Maestro)",
			["Taiwanese"] = "草藥學 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18748,
				18776,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Herbalism"], level)
end
