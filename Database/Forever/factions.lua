-------------------------------------------------------
-- Factions new in WoW Forever
-------------------------------------------------------
local forever_factions = {
	{
		["id"] = 2740,
		["name"] = {
			["Chinese"] = "肯瑞托",
			["English"] = "Kirin Tor",
			["French"] = "Kirin Tor",
			["German"] = "Kirin Tor",
			["Korean"] = "키린 토",
			["Mexican"] = "Kirin Tor",
			["Portuguese"] = "Kirin Tor",
			["Russian"] = "Кирин-Тор",
			["Spanish"] = "Kirin Tor",
			["Taiwanese"] = "祈倫托",
		},
	},
	{
		["id"] = 2758,
		["name"] = {
			["Chinese"] = "夜爪德鲁伊",
			["English"] = "Nightclaw Druids",
			["French"] = "Druides et druidesses de la Noctegriffe",
			["German"] = "Druiden der Nachtklaue",
			["Korean"] = "한밤발톱 드루이드",
			["Mexican"] = "Druidas Garra Nocturna",
			["Portuguese"] = "Druidas Noctigarra",
			["Russian"] = "Друиды-ночекогти",
			["Spanish"] = "Druidas Garranoche",
			["Taiwanese"] = "夜爪德魯伊",
		},
	},
	{
		["id"] = 2787,
		["name"] = {
			["Chinese"] = "大地之环",
			["English"] = "Earthen Ring",
			["French"] = "Cercle terrestre",
			["German"] = "Der Irdene Ring",
			["Korean"] = "대지 고리회",
			["Mexican"] = "Anillo de la Tierra",
			["Portuguese"] = "Harmonia Telúrica",
			["Russian"] = "Служители Земли",
			["Spanish"] = "Anillo de la Tierra",
			["Taiwanese"] = "陶土議會",
		},
	},
}

for _, faction in ipairs(forever_factions) do
	table.insert(RR_DATA["factions"], faction)
end

-- Shown in the reputation filter in addition to the curated Classic list.
RR_DATA["forever_reputation_factions"] = {
	2740,
	2758,
	2787,
}
