-------------------------------------------------------
-- All items (First Aid) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["items"]["First Aid"] then RR_DATA["items"]["First Aid"] = {} end
local tbc_items = 
{
	{
		["expansion"] = 2,
		["id"] = 21992,
		["name"] = {
			["Chinese"] = "手册：灵纹布绷带",
			["English"] = "Manual: Netherweave Bandage",
			["French"] = "Manuel : Bandage en tisse-néant",
			["German"] = "Handbuch: Netherstoffverband",
			["Korean"] = "처방전: 황천매듭 붕대",
			["Mexican"] = "Manual: venda de tejido abisal",
			["Portuguese"] = "Manual: Bandagem de Etertrama",
			["Russian"] = "Учебник: бинты из ткани Пустоты",
			["Spanish"] = "Manual: venda de tejido abisal",
			["Taiwanese"] = "手冊:幽紋繃帶",
		},
		["phase"] = 1,
		["quality"] = "common",
		["vendors"] = {
			["price"] = 20000,
			["sources"] = {
				18990,
				18991,
			},
		},
	},
	{
		["expansion"] = 2,
		["id"] = 21993,
		["name"] = {
			["Chinese"] = "手册：厚灵纹布绷带",
			["English"] = "Manual: Heavy Netherweave Bandage",
			["French"] = "Manuel : Bandage épais en tisse-néant",
			["German"] = "Handbuch: Schwerer Netherstoffverband",
			["Korean"] = "처방전: 두꺼운 황천매듭 붕대",
			["Mexican"] = "Manual: venda de tejido abisal gruesa",
			["Portuguese"] = "Manual: Bandagem Grossa de Etertrama",
			["Russian"] = "Учебник: плотные бинты из ткани Пустоты",
			["Spanish"] = "Manual: venda de tejido abisal grueso",
			["Taiwanese"] = "手冊:厚幽紋繃帶",
		},
		["phase"] = 1,
		["quality"] = "common",
		["vendors"] = {
			["price"] = 40000,
			["sources"] = {
				18990,
				18991,
			},
		},
	},
	{
		["expansion"] = 2,
		["id"] = 22012,
		["name"] = {
			["Chinese"] = "大师级急救手册 - 私人医生",
			["English"] = "Master First Aid - Doctor in the House",
			["French"] = "Maître en premiers soins - Un médecin à domicile",
			["German"] = "Erste Hilfe für Meister - Hilfe, der Doktor kommt!",
			["Korean"] = "대가의 응급치료서",
			["Mexican"] = "Maestro de primeros auxilios: doctor en casa",
			["Portuguese"] = "Mestre Socorrista - Doutor Presente",
			["Russian"] = "Мастерская первая помощь - домашний доктор",
			["Spanish"] = "Maestro de primeros auxilios: doctor en casa",
			["Taiwanese"] = "大師急救 - 屋中醫生",
		},
		["phase"] = 1,
		["quality"] = "common",
		["vendors"] = {
			["price"] = 50000,
			["sources"] = {
				18990,
				18991,
			},
		},
	},
}

for _, item in ipairs(tbc_items) do
	table.insert(RR_DATA["items"]["First Aid"], item)
end
