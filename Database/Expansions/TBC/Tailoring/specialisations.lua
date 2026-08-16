-------------------------------------------------------
-- Specialisations (Tailoring) - The Burning Crusade Delta
-------------------------------------------------------
if not RR_DATA["specialisations"]["Tailoring"] then RR_DATA["specialisations"]["Tailoring"] = {} end
local tbc_specs = 
{
	{
        ["expansion"] = 2,
        ["id"] = 26797,
        ["min_skill"] = 1,
        ["name"] = {
            ["Chinese"] = "魔焰裁缝",
            ["English"] = "Spellfire Tailoring",
            ["French"] = "Couture du feu-sorcier",
            ["German"] = "Zauberfeuerschneiderei",
            ["Korean"] = "마법불꽃 재봉술",
            ["Mexican"] = "Sastrería con fuego de hechizo",
            ["Portuguese"] = "Alfaiataria de Fogo Místico",
            ["Russian"] = "Шитье из огненной чароткани",
            ["Spanish"] = "Sastrería con fuego de hechizo",
            ["Taiwanese"] = "魔焰裁縫",
        },
        ["phase"] = 1,
        ["quests"] = {
            10832
        },
    },
	{
        ["expansion"] = 2,
        ["id"] = 26798,
        ["min_skill"] = 1,
        ["name"] = {
            ["Chinese"] = "月布裁缝",
            ["English"] = "Mooncloth Tailoring",
            ["French"] = "Couture d'étoffe lunaire",
            ["German"] = "Mondstoffschneiderei",
            ["Korean"] = "달빛매듭 재봉술",
            ["Mexican"] = "Sastrería con tela lunar",
            ["Portuguese"] = "Alfaiataria de Lunatrama",
            ["Russian"] = "Шитье из луноткани",
            ["Spanish"] = "Sastrería con tela lunar",
            ["Taiwanese"] = "月布裁縫",
        },
        ["phase"] = 1,
        ["quests"] = {
            10831
        },
    },
	{
        ["expansion"] = 2,
        ["id"] = 26801,
        ["min_skill"] = 1,
        ["name"] = {
            ["Chinese"] = "暗纹裁缝",
            ["English"] = "Shadoweave Tailoring",
            ["French"] = "Couture de tisse-ombre",
            ["German"] = "Schattenzwirnschneiderei",
            ["Korean"] = "그림자매듭 재봉술",
            ["Mexican"] = "Sastrería con tejido de sombra",
            ["Portuguese"] = "Alfaiataria de Umbratrama",
            ["Russian"] = "Шитье из тенеткани",
            ["Spanish"] = "Sastrería con tejido de sombra",
            ["Taiwanese"] = "影紋裁縫",
        },
        ["phase"] = 1,
        ["quests"] = {
            10833
        },
    },
}

for _, spec in ipairs(tbc_specs) do
	table.insert(RR_DATA["specialisations"]["Tailoring"], spec)
end
