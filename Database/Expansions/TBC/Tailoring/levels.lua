-------------------------------------------------------
-- All levels (Tailoring) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Tailoring"] then RR_DATA["levels"]["Tailoring"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 26790,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "裁缝 (大师级)",
			["English"] = "Tailoring (Master)",
			["French"] = "Couture (Maître)",
			["German"] = "Schneiderei (Meister)",
			["Korean"] = "재봉술 (대가)",
			["Mexican"] = "Sastrería (Maestro)",
			["Portuguese"] = "Alfaiataria (Mestre)",
			["Russian"] = "Портняжное дело (Мастер)",
			["Spanish"] = "Sastrería (Maestro)",
			["Taiwanese"] = "裁縫 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				18749,
				18772,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Tailoring"], level)
end
