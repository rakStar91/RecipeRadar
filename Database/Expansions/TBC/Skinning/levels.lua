-------------------------------------------------------
-- All levels (Skinning) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Skinning"] then RR_DATA["levels"]["Skinning"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 32678,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 35,
		["name"] = {
			["Chinese"] = "剥皮 (大师级)",
			["English"] = "Skinning (Master)",
			["French"] = "Dépeçage (Maître)",
			["German"] = "Kürschnerei (Meister)",
			["Korean"] = "무두질 (대가)",
			["Mexican"] = "Desuello (Maestro)",
			["Portuguese"] = "Esfolamento (Mestre)",
			["Russian"] = "Cнятие шкур (Мастер)",
			["Spanish"] = "Desuello (Maestro)",
			["Taiwanese"] = "剝皮 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18755,
				18777,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Skinning"], level)
end
