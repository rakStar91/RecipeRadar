-------------------------------------------------------
-- Zones added in WoW Forever (appended to Base zones)
-------------------------------------------------------
local forever_zones = {
	{
		["cont_id"] = 1,
		["id"] = 616,
		["levels"] = {
			["max"] = 60,
			["min"] = 58,
		},
		["name"] = {
			["Chinese"] = "海加尔山",
			["English"] = "Mount Hyjal",
			["French"] = "Mont Hyjal",
			["German"] = "Hyjal",
			["Korean"] = "하이잘 산",
			["Mexican"] = "Monte Hyjal",
			["Portuguese"] = "Monte Hyjal",
			["Russian"] = "Гора Хиджал",
			["Spanish"] = "Monte Hyjal",
			["Taiwanese"] = "海加爾山",
		},
	},
	{
		["cont_id"] = 2,
		["id"] = 16591,
		["levels"] = {
			["max"] = 45,
			["min"] = 35,
		},
		["name"] = {
			["Chinese"] = "河林",
			["English"] = "Riverglades",
			["French"] = "Rives Claires",
			["German"] = "Flusslande",
			["Korean"] = "강물터",
			["Mexican"] = "Claros del Río",
			["Portuguese"] = "Sendas do Rio",
			["Russian"] = "Лесоречье",
			["Spanish"] = "Clarofluvial",
			["Taiwanese"] = "大河林地",
		},
	},
	{
		["cont_id"] = 2,
		["id"] = 16593,
		["levels"] = {
			["max"] = 12,
			["min"] = 1,
		},
		["name"] = {
			["Chinese"] = "泽风岛",
			["English"] = "Zephras Isle",
			["French"] = "Île de Zéphras",
			["German"] = "Insel Zephras",
			["Korean"] = "제프라스 섬",
			["Mexican"] = "Isla Zephras",
			["Portuguese"] = "Ilha de Zefras",
			["Russian"] = "Остров Зефрис",
			["Spanish"] = "Isla de Zephras",
			["Taiwanese"] = "微風島",
		},
	},
	{
		["cont_id"] = 1,
		["id"] = 16651,
		["levels"] = {
			["max"] = 48,
			["min"] = 35,
		},
		["name"] = {
			["Chinese"] = "辛德拉",
			["English"] = "Shen'dralas",
			["French"] = "Shen’dralas",
			["German"] = "Shen'dralas",
			["Korean"] = "셴드랄라스",
			["Mexican"] = "Shen'dralas",
			["Portuguese"] = "Shen'dralas",
			["Russian"] = "Шен'дралас",
			["Spanish"] = "Shen'dralas",
			["Taiwanese"] = "申德拉斯",
		},
	},
	{
		["cont_id"] = 2,
		["id"] = 16560,
		["levels"] = {
			["max"] = 60,
			["min"] = 45,
		},
		["name"] = {
			["Chinese"] = "达拉然城",
			["English"] = "City of Dalaran",
			["French"] = "Cité de Dalaran",
			["German"] = "Dalaran",
			["Korean"] = "달라란",
			["Mexican"] = "Ciudad de Dalaran",
			["Portuguese"] = "Dalaran",
			["Russian"] = "Даларан",
			["Spanish"] = "Ciudad de Dalaran",
			["Taiwanese"] = "達拉然城",
		},
	},
	{
		["cont_id"] = 1,
		["id"] = 16606,
		["levels"] = {
			["max"] = 12,
			["min"] = 1,
		},
		["name"] = {
			["Chinese"] = "暗矛群岛",
			["English"] = "Darkspear Islands",
			["French"] = "Îles des Sombrelances",
			["German"] = "Darkspear-Inseln",
			["Korean"] = "검은창 군도",
			["Mexican"] = "Islas Lanza Negra",
			["Portuguese"] = "Ilhas Lançanegra",
			["Russian"] = "Острова Черного Копья",
			["Spanish"] = "Islas Lanza Negra",
			["Taiwanese"] = "暗矛島嶼",
		},
	},
	{
		["cont_id"] = 2,
		["id"] = 17065,
		["levels"] = {
			["max"] = 20,
			["min"] = 1,
		},
		["name"] = {
			["Chinese"] = "吉尔尼斯",
			["English"] = "Gilneas",
			["French"] = "Gilnéas",
			["German"] = "Gilneas",
			["Korean"] = "길니아스",
			["Mexican"] = "Gilneas",
			["Portuguese"] = "Guilnéas",
			["Russian"] = "Гилнеас",
			["Spanish"] = "Gilneas",
			["Taiwanese"] = "吉爾尼斯",
		},
	},
}

for _, entry in ipairs(forever_zones) do
	table.insert(RR_DATA["zones"], entry)
end
