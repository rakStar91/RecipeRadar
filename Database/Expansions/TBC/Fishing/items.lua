-------------------------------------------------------
-- All items (Fishing) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["items"]["Fishing"] then RR_DATA["items"]["Fishing"] = {} end
local tbc_items = 
{
	{
		["expansion"] = 1,
		["id"] = 27532,
		["name"] = {
			["Chinese"] = "顶级钓鱼教材 - 下钩的艺术",
			["English"] = "Master Fishing - The Art of Angling",
			["French"] = "Maître de pêche - L'art de la ligne",
			["German"] = "Anglermeister - Die hohe Kunst des Angelns",
			["Korean"] = "대가의 낚시정보",
			["Mexican"] = "Maestro de pesca - El arte de la cucharilla",
			["Portuguese"] = "Mestre pescador - A Arte do Molinete",
			["Russian"] = "Рыболов-мастер: искусство рыбалки",
			["Spanish"] = "Maestro de pesca - El arte de la cucharilla",
			["Taiwanese"] = "大師級釣魚 - 垂釣的藝術",
		},
		["phase"] = 1,
		["quality"] = "common",
		["vendors"] = {
			["price"] = 50000,
			["sources"] = {
				18911,
			},
		},
	},
	{
		["expansion"] = 2,
		["id"] = 34109,
		["name"] = {
			["Chinese"] = "饱经风霜的日记",
			["English"] = "Weather-Beaten Journal",
			["French"] = "Journal détrempé",
			["German"] = "Verwittertes Tagebuch",
			["Korean"] = "풍파에 낡은 일지",
			["Mexican"] = "Diario deteriorado",
			["Portuguese"] = "Diário Gasto pelo Tempo",
			["Russian"] = "Истрепанный журнал",
			["Spanish"] = "Diario deteriorado",
			["Taiwanese"] = "天候征服日誌",
		},
		["phase"] = 1,
		["quality"] = "common",
		["special_action"] = "looted from within containers found when fishing",
	},
}

for _, item in ipairs(tbc_items) do
	table.insert(RR_DATA["items"]["Fishing"], item)
end
