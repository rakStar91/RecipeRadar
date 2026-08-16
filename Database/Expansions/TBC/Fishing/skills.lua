-------------------------------------------------------
-- All skills (Fishing) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["skills"]["Fishing"] then RR_DATA["skills"]["Fishing"] = {} end
local tbc_skills = 
{
	{
		["expansion"] = 2,
		["id"] = 43308,
		["items"] = {
			34109,
		},
		["min_skill"] = 100,
		["name"] = {
			["Chinese"] = "寻找渔点",
			["English"] = "Find Fish",
			["French"] = "Découverte de poisson",
			["German"] = "Fischsuche",
			["Korean"] = "물고기 찾기",
			["Mexican"] = "Buscar pescado",
			["Portuguese"] = "Localizar Peixes",
			["Russian"] = "Поиск рыбы",
			["Spanish"] = "Buscar pescado",
			["Taiwanese"] = "尋找漁點",
		},
		["phase"] = 1,
		["spellbook"] = 1,
	},
}

for _, skill in ipairs(tbc_skills) do
	table.insert(RR_DATA["skills"]["Fishing"], skill)
end
