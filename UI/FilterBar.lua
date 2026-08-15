-- ============================================================================
-- RecipeRadar: UI/FilterBar.lua
-- 3-Row Filter Area: Search, Mode, Source, Faction, Spec, Phase & Quick Zones
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.FilterBar = {}

function RR.UI.FilterBar:Create(parent, onRefresh)
    local filterArea = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    filterArea:SetPoint("TOPLEFT", 8, -32)
    filterArea:SetPoint("TOPRIGHT", -8, -32)
    filterArea:SetHeight(98)
    RR.UI.Theme:SkinPanel(filterArea, 0.4)

    local instance = {
        frame = filterArea,
        onRefresh = onRefresh,
        modeBtns = {},
        zoneBtns = {},
        searchQuery = "",
    }

    -- 1. Mode Buttons (Missing, Learned, All) placed on the far right column
    local modeDefs = {
        { id = "missing", text = RR.L["MODE_MISSING"], top = -4 },
        { id = "known", text = RR.L["MODE_KNOWN"], top = -36 },
        { id = "all", text = RR.L["MODE_ALL"], top = -68 },
    }
    for _, md in ipairs(modeDefs) do
        local mBtn = RR.UI.Theme:CreateDarkButton(filterArea, md.text, 92, 24)
        mBtn:SetPoint("TOPRIGHT", -6, md.top)
        mBtn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("mode", md.id)
            instance:UpdateFilterButtons()
            if instance.onRefresh then instance.onRefresh() end
        end)
        if md.id == "missing" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_MISSING_TITLE"], RR.L["TOOLTIP_MODE_MISSING_DESC"])
        elseif md.id == "known" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_KNOWN_TITLE"], RR.L["TOOLTIP_MODE_KNOWN_DESC"])
        elseif md.id == "all" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_ALL_TITLE"], RR.L["TOOLTIP_MODE_ALL_DESC"])
        end
        instance.modeBtns[md.id] = mBtn
    end

    -- ROW 1: Name: [ Search EditBox ] [ Suche ]
    local nameLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", 8, -8)
    nameLabel:SetTextColor(1, 0.82, 0, 1)
    nameLabel:SetText(RR.L["LABEL_NAME_COLON"])

    local searchBox = CreateFrame("EditBox", nil, filterArea, BackdropTemplateMixin and "BackdropTemplate")
    searchBox:SetPoint("TOPLEFT", nameLabel, "TOPRIGHT", 14, 3)
    searchBox:SetSize(470, 24)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(6, 6, 0, 0)
    RR.UI.Theme:SkinPanel(searchBox, 0.9)

    searchBox:SetScript("OnTextChanged", function(selfBox)
        instance.searchQuery = selfBox:GetText()
        if instance.onRefresh then instance.onRefresh() end
    end)
    searchBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        if instance.onRefresh then instance.onRefresh() end
    end)
    searchBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:SetText("")
        selfBox:ClearFocus()
        if instance.onRefresh then instance.onRefresh() end
    end)
    instance.searchBox = searchBox

    local searchBtn = RR.UI.Theme:CreateDarkButton(filterArea, RR.L["SEARCH_BUTTON"], 80, 24)
    searchBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    searchBtn:SetScript("OnClick", function()
        instance.searchBox:ClearFocus()
        if instance.onRefresh then instance.onRefresh() end
    end)
    RR.UI.Theme:AddTooltip(searchBox, RR.L["TOOLTIP_SEARCH_TITLE"], RR.L["TOOLTIP_SEARCH_DESC"])
    RR.UI.Theme:AddTooltip(searchBtn, RR.L["TOOLTIP_SEARCH_BTN_TITLE"], RR.L["TOOLTIP_SEARCH_BTN_DESC"])

    -- ROW 2: Source: [ Source v ] [ Faction v ] [ Specialisation v ] [ Phase v ]
    local sourceLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", 8, -40)
    sourceLabel:SetTextColor(1, 0.82, 0, 1)
    sourceLabel:SetText(RR.L["LABEL_SOURCE_COLON"])

    local sourceMenu = {
        { text = RR.L["SOURCE_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
        { text = RR.L["SOURCE_TRAINER"], value = "trainer", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { text = RR.L["SOURCE_VENDOR"], value = "vendor", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { text = RR.L["SOURCE_QUEST"], value = "quest", icon = "Interface\\GossipFrame\\AvailableQuestIcon" },
        { text = RR.L["SOURCE_DROP"], value = "drop", icon = "Interface\\GossipFrame\\VendorGossipIcon" },
        { text = RR.L["SOURCE_HOLIDAY"], value = "holiday", icon = "Interface\\Icons\\INV_Misc_Gift_01" },
        { text = RR.L["SOURCE_REPUTATION"], value = "reputation", icon = "Interface\\Icons\\INV_BannerPVP_02" },
    }
    instance.sourceBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, RR.L["DROPDOWN_SOURCE"], function(selfF)
        local menu = {}
        for _, itm in ipairs(sourceMenu) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("sourceFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("sourceFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.sourceBtn:SetPoint("LEFT", sourceLabel, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(instance.sourceBtn, RR.L["TOOLTIP_SOURCE_FILTER_TITLE"], RR.L["TOOLTIP_SOURCE_FILTER_DESC"])

    local repFactionIds = { 529, 59, 576, 270, 749, 909, 609 }
    local function buildFactionMenu()
        local menu = {
            { text = RR.L["FACTION_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
            { text = RR.L["FACTION_ALLIANCE"], value = "Alliance", icon = RR.ADDON_PATH .. "\\images\\alliance.tga" },
            { text = RR.L["FACTION_HORDE"], value = "Horde", icon = RR.ADDON_PATH .. "\\images\\horde.tga" },
            { text = RR.L["FACTION_NEUTRAL"], value = "Neutral", icon = RR.ADDON_PATH .. "\\images\\neutral.tga" },
        }
        for _, fId in ipairs(repFactionIds) do
            local fName = RR.DB:GetFactionName(fId)
            if fName then
                table.insert(menu, {
                    text = fName,
                    value = fId,
                    icon = "Interface\\Icons\\INV_BannerPVP_02",
                })
            end
        end
        return menu
    end
    instance.factionBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, RR.L["DROPDOWN_FACTION"], function(selfF)
        local menu = {}
        for _, itm in ipairs(buildFactionMenu()) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("factionFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("factionFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.factionBtn:SetPoint("LEFT", instance.sourceBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(instance.factionBtn, RR.L["TOOLTIP_FACTION_FILTER_TITLE"], RR.L["TOOLTIP_FACTION_FILTER_DESC"])

    instance.specBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 135, RR.L["DROPDOWN_SPEC"], function(selfF)
        local menu = {
            { text = RR.L["FACTION_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
        }
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.specBtn:SetPoint("LEFT", instance.factionBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(instance.specBtn, RR.L["TOOLTIP_SPEC_FILTER_TITLE"], RR.L["TOOLTIP_SPEC_FILTER_DESC"])

    local phaseMenu = {
        { text = RR.L["PHASE_ALL"], value = 0, icon = "Interface\\Icons\\INV_Misc_Book_08" },
        { text = RR.L["PHASE_1"], value = 1, icon = "Interface\\Icons\\Spell_Fire_MoltenBlood" },
        { text = RR.L["PHASE_2"], value = 2, icon = "Interface\\Icons\\Spell_Nature_Earthquake" },
        { text = RR.L["PHASE_3"], value = 3, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
        { text = RR.L["PHASE_4"], value = 4, icon = "Interface\\Icons\\Ability_Hunter_Pet_Bat" },
        { text = RR.L["PHASE_5"], value = 5, icon = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_03" },
        { text = RR.L["PHASE_6"], value = 6, icon = "Interface\\Icons\\Spell_Shadow_Necromancy" },
    }
    instance.phaseBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 105, RR.L["DROPDOWN_PHASE"], function(selfF)
        local menu = {}
        for _, itm in ipairs(phaseMenu) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("phaseFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("phaseFilter") or 0) == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.phaseBtn:SetPoint("LEFT", instance.specBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(instance.phaseBtn, RR.L["TOOLTIP_PHASE_FILTER_TITLE"], RR.L["TOOLTIP_PHASE_FILTER_DESC"])

    -- ROW 3: Zone: [ Region v ] [ Zone v ] [ Any Zone ] [ Current Zone ] [ <Last Zone> ]
    local zoneLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("TOPLEFT", 8, -72)
    zoneLabel:SetTextColor(1, 0.82, 0, 1)
    zoneLabel:SetText(RR.L["LABEL_ZONE_COLON"])

    instance.continentBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, RR.L["REGION_ALL"], function(selfF)
        local contMenu = {
            { text = RR.L["REGION_ALL"], value = "any" },
            { text = RR.L["CONTINENT_KALIMDOR"], value = 1 },
            { text = RR.L["CONTINENT_EASTERN_KINGDOMS"], value = 2 },
            { text = RR.L["CONTINENT_BATTLEGROUNDS"], value = 3 },
            { text = RR.L["CONTINENT_DUNGEONS"], value = 4 },
            { text = RR.L["CONTINENT_RAIDS"], value = 5 },
        }
        local menu = {}
        for _, itm in ipairs(contMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("continentFilter", itm.value)
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText(itm.text)
                    if instance.zoneDropBtn and instance.zoneDropBtn.text then
                        instance.zoneDropBtn.text:SetText(RR.L["DROPDOWN_ZONE"])
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("continentFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.continentBtn:SetPoint("LEFT", zoneLabel, "RIGHT", 14, 0)
    RR.UI.Theme:AddTooltip(instance.continentBtn, RR.L["TOOLTIP_REGION_FILTER_TITLE"], RR.L["TOOLTIP_REGION_FILTER_DESC"])

    instance.zoneDropBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, RR.L["DROPDOWN_ZONE"], function(selfF)
        local curCont = RR.Config:GetFilterSetting("continentFilter") or "any"
        local zones = RR.DB:GetZonesInContinent(curCont)
        local curZone = RR.Config:GetFilterSetting("zoneFilter") or "any"

        local menu = {
            {
                text = RR.L["ZONE_ALL_DROPDOWN"],
                func = function()
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText(RR.L["DROPDOWN_ZONE"])
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (curZone == "any"),
            },
        }

        for _, z in ipairs(zones) do
            table.insert(menu, {
                text = z.name,
                func = function()
                    RR.Config:SetFilterSetting("zoneFilter", z.id)
                    selfF.text:SetText(z.name)
                    local contLabel = (instance.continentBtn and instance.continentBtn.text and instance.continentBtn.text:GetText()) or RR.L["REGION_ALL"]
                    local prof = RR.Scanner.currentProfession or "Tailoring"
                    local zoneData = { id = z.id, name = z.name, cont = curCont, contName = contLabel }
                    RR.Config:SaveLastZoneForProfession(prof, zoneData)
                    if instance.zoneBtns and instance.zoneBtns.last then
                        instance.zoneBtns.last:SetText(z.name)
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (curZone == z.id),
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.zoneDropBtn:SetPoint("LEFT", instance.continentBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(instance.zoneDropBtn, RR.L["TOOLTIP_ZONE_FILTER_TITLE"], RR.L["TOOLTIP_ZONE_FILTER_DESC"])

    -- Quick Zone Buttons (Any Zone, Current Zone, Last Zone)
    local zBtnAny = RR.UI.Theme:CreateDarkButton(filterArea, RR.L["QUICK_ANY_ZONE"], 80, 24)
    zBtnAny:SetPoint("LEFT", instance.zoneDropBtn, "RIGHT", 10, 0)
    zBtnAny:SetScript("OnClick", function()
        RR.Config:SetFilterSetting("continentFilter", "any")
        RR.Config:SetFilterSetting("zoneFilter", "any")
        if instance.continentBtn and instance.continentBtn.text then instance.continentBtn.text:SetText(RR.L["REGION_ALL"]) end
        if instance.zoneDropBtn and instance.zoneDropBtn.text then instance.zoneDropBtn.text:SetText(RR.L["DROPDOWN_ZONE"]) end
        instance:UpdateFilterButtons()
        if instance.onRefresh then instance.onRefresh() end
    end)
    RR.UI.Theme:AddTooltip(zBtnAny, RR.L["TOOLTIP_QUICK_ANY_TITLE"], RR.L["TOOLTIP_QUICK_ANY_DESC"])
    instance.zoneBtns.any = zBtnAny

    local zBtnCurrent = RR.UI.Theme:CreateDarkButton(filterArea, RR.L["QUICK_CURRENT_ZONE"], 95, 24)
    zBtnCurrent:SetPoint("LEFT", zBtnAny, "RIGHT", 5, 0)
    zBtnCurrent:SetScript("OnClick", function()
        local curRealZone = GetRealZoneText() or RR.L["QUICK_CURRENT_ZONE"]
        RR.Config:SetFilterSetting("zoneFilter", "current")
        if instance.zoneDropBtn and instance.zoneDropBtn.text then instance.zoneDropBtn.text:SetText(curRealZone) end
        instance:UpdateFilterButtons()
        if instance.onRefresh then instance.onRefresh() end
    end)
    RR.UI.Theme:AddTooltip(zBtnCurrent, RR.L["TOOLTIP_QUICK_CURRENT_TITLE"], RR.L["TOOLTIP_QUICK_CURRENT_DESC"])
    instance.zoneBtns.current = zBtnCurrent

    local zBtnLast = RR.UI.Theme:CreateDarkButton(filterArea, RR.L["QUICK_LAST_ZONE"], 110, 24)
    zBtnLast:SetPoint("LEFT", zBtnCurrent, "RIGHT", 5, 0)
    zBtnLast:SetScript("OnClick", function()
        local prof = RR.Scanner.currentProfession or "Tailoring"
        local lastZone = RR.Config:GetLastZoneForProfession(prof)
        if lastZone and lastZone.id then
            RR.Config:SetFilterSetting("continentFilter", lastZone.cont)
            RR.Config:SetFilterSetting("zoneFilter", lastZone.id)
            if instance.continentBtn and instance.continentBtn.text then instance.continentBtn.text:SetText(lastZone.contName or RR.L["REGION_ALL"]) end
            if instance.zoneDropBtn and instance.zoneDropBtn.text then instance.zoneDropBtn.text:SetText(lastZone.name) end
            instance:UpdateFilterButtons()
            if instance.onRefresh then instance.onRefresh() end
        end
    end)
    RR.UI.Theme:AddTooltip(zBtnLast, RR.L["TOOLTIP_QUICK_LAST_TITLE"], RR.L["TOOLTIP_QUICK_LAST_DESC"])
    instance.zoneBtns.last = zBtnLast

    function instance:UpdateFilterButtons()
        local curMode = RR.Config:GetFilterSetting("mode") or "missing"
        if self.modeBtns then
            for m, btn in pairs(self.modeBtns) do
                btn:SetActive(m == curMode)
            end
        end

        local curZone = RR.Config:GetFilterSetting("zoneFilter") or "any"
        if self.zoneBtns then
            for z, btn in pairs(self.zoneBtns) do
                btn:SetActive(z == curZone or (z == "current_name" and curZone == "current"))
            end
        end
    end

    function instance:UpdateLastZoneForCurrentProfession()
        local prof = RR.Scanner.currentProfession or "Tailoring"
        local saved = RR.Config:GetLastZoneForProfession(prof)
        if saved and saved.id and saved.name then
            if self.zoneBtns and self.zoneBtns.last then
                self.zoneBtns.last:SetText(saved.name)
            end
        else
            if self.zoneBtns and self.zoneBtns.last then
                self.zoneBtns.last:SetText(RR.L["QUICK_LAST_ZONE"])
            end
        end
    end

    return instance
end
