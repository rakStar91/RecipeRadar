-------------------------------------------------------
-- All levels (Engineering) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["levels"]["Engineering"] then RR_DATA["levels"]["Engineering"] = {} end
local tbc_levels = 
{
	{
		["expansion"] = 2,
		["id"] = 30350,
		["max_skill"] = 375,
		["min_skill"] = 275,
		["min_xp_level"] = 50,
		["name"] = {
			["Chinese"] = "工程学 (大师级)",
			["English"] = "Engineering (Master)",
			["French"] = "Ingénierie (Maître)",
			["German"] = "Ingenieurskunst (Meister)",
			["Korean"] = "기계공학 (대가)",
			["Mexican"] = "Ingeniería (Maestro)",
			["Portuguese"] = "Engenharia (Mestre)",
			["Russian"] = "Инженерное дело (Мастер)",
			["Spanish"] = "Ingeniería (Maestro)",
			["Taiwanese"] = "工程學 (大师级)",
		},
		["phase"] = 1,
		["rank"] = 5,
		["trainers"] = {
			["price"] = 100000,
			["sources"] = {
				17634,
				17637,
				18752,
				18775,
				19576,
			},
		},
	},
}

for _, level in ipairs(tbc_levels) do
	table.insert(RR_DATA["levels"]["Engineering"], level)
end
