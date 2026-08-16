-------------------------------------------------------
-- All skills (First Aid) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["skills"]["First Aid"] then RR_DATA["skills"]["First Aid"] = {} end
local tbc_skills = 
{
	{
		["expansion"] = 2,
		["id"] = 27032,
		["item_id"] = 21990,
		["items"] = {
			21992,
		},
		["min_skill"] = 330,
		["name"] = {
			["Chinese"] = "灵纹布绷带",
			["English"] = "Netherweave Bandage",
			["French"] = "Bandage en tisse-néant",
			["German"] = "Netherstoffverband",
			["Korean"] = "황천매듭 붕대",
			["Mexican"] = "Venda de tejido abisal",
			["Portuguese"] = "Bandagem de Etertrama",
			["Russian"] = "Бинты из ткани Пустоты",
			["Spanish"] = "Venda de tejido abisal",
			["Taiwanese"] = "幽紋繃帶",
		},
		["phase"] = 1,
	},
	{
		["expansion"] = 2,
		["id"] = 27033,
		["item_id"] = 21991,
		["items"] = {
			21993,
		},
		["min_skill"] = 360,
		["name"] = {
			["Chinese"] = "厚灵纹布绷带",
			["English"] = "Heavy Netherweave Bandage",
			["French"] = "Bandage épais en tisse-néant",
			["German"] = "Schwerer Netherstoffverband",
			["Korean"] = "두꺼운 황천매듭 붕대",
			["Mexican"] = "Venda de tejido abisal gruesa",
			["Portuguese"] = "Bandagem Grossa de Etertrama",
			["Russian"] = "Плотные бинты из ткани Пустоты",
			["Spanish"] = "Venda de tejido abisal grueso",
			["Taiwanese"] = "厚幽紋繃帶",
		},
		["phase"] = 1,
	},
}

for _, skill in ipairs(tbc_skills) do
	table.insert(RR_DATA["skills"]["First Aid"], skill)
end
