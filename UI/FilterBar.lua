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

    local sourceMenuData = {
        { text = RR.L["SOURCE_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
        { text = RR.L["SOURCE_TRAINER"], value = "trainer", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { text = RR.L["SOURCE_VENDOR"], value = "vendor", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { text = RR.L["SOURCE_QUEST"], value = "quest", icon = "Interface\\GossipFrame\\AvailableQuestIcon" },
        { text = RR.L["SOURCE_DROP"], value = "drop", icon = "Interface\\GossipFrame\\VendorGossipIcon" },
        { text = RR.L["SOURCE_HOLIDAY"], value = "holiday", icon = "Interface\\Icons\\INV_Misc_Gift_01" },
        { text = RR.L["SOURCE_REPUTATION"], value = "reputation", icon = "Interface\\Icons\\INV_BannerPVP_02" },
    }

    local function buildSourceMenu()
        local curSource = RR.Config:GetFilterSetting("sourceFilter") or "any"
        local menu = {}
        for _, itm in ipairs(sourceMenuData) do
            local isChecked = false
            if itm.value == "any" then
                isChecked = (curSource == "any")
            elseif type(curSource) == "table" then
                isChecked = (curSource[itm.value] == true)
            elseif type(curSource) == "string" then
                isChecked = (curSource == itm.value)
            end

            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                checked = isChecked,
                func = function()
                    if itm.value == "any" then
                        RR.Config:SetFilterSetting("sourceFilter", "any")
                    else
                        local newSet = {}
                        if type(curSource) == "table" then
                            for k, v in pairs(curSource) do newSet[k] = v end
                        elseif type(curSource) == "string" and curSource ~= "any" then
                            newSet[curSource] = true
                        end
                        if newSet[itm.value] then
                            newSet[itm.value] = nil
                        else
                            newSet[itm.value] = true
                        end
                        local count = 0
                        for _, opt in ipairs(sourceMenuData) do
                            if opt.value ~= "any" and newSet[opt.value] then
                                count = count + 1
                            end
                        end
                        if count == 0 or count >= (#sourceMenuData - 1) then
                            RR.Config:SetFilterSetting("sourceFilter", "any")
                        else
                            RR.Config:SetFilterSetting("sourceFilter", newSet)
                        end
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            })
        end
        return menu
    end

    instance.sourceBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 95, RR.L["DROPDOWN_SOURCE"], function(selfF)
        RR.UI.Dropdown:Show(selfF, buildSourceMenu, true)
    end)
    instance.sourceBtn:SetPoint("LEFT", sourceLabel, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.sourceBtn, RR.L["TOOLTIP_SOURCE_FILTER_TITLE"], RR.L["TOOLTIP_SOURCE_FILTER_DESC"])

    -- Dropdown 1: Faction (Alliance / Horde / Neutral / All)
    local factionMenuData = {
        { text = RR.L["FACTION_ALL"], value = "any", icon = RR.ADDON_PATH .. "\\images\\neutral.tga" },
        { text = RR.L["FACTION_ALLIANCE"], value = "Alliance", icon = RR.ADDON_PATH .. "\\images\\alliance.tga" },
        { text = RR.L["FACTION_HORDE"], value = "Horde", icon = RR.ADDON_PATH .. "\\images\\horde.tga" },
        { text = RR.L["FACTION_NEUTRAL"], value = "Neutral", icon = RR.ADDON_PATH .. "\\images\\neutral.tga" },
    }

    local function buildFactionMenu()
        local curFaction = RR.Config:GetFilterSetting("factionFilter") or "any"
        local menu = {}
        for _, itm in ipairs(factionMenuData) do
            local isChecked = false
            if itm.value == "any" then
                isChecked = (curFaction == "any")
            elseif type(curFaction) == "table" then
                isChecked = (curFaction[itm.value] == true)
            elseif type(curFaction) == "string" then
                isChecked = (curFaction == itm.value)
            end

            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                checked = isChecked,
                func = function()
                    if itm.value == "any" then
                        RR.Config:SetFilterSetting("factionFilter", "any")
                    else
                        local newSet = {}
                        if type(curFaction) == "table" then
                            for k, v in pairs(curFaction) do newSet[k] = v end
                        elseif type(curFaction) == "string" and curFaction ~= "any" then
                            newSet[curFaction] = true
                        end
                        if newSet[itm.value] then
                            newSet[itm.value] = nil
                        else
                            newSet[itm.value] = true
                        end
                        local count = 0
                        for _, opt in ipairs(factionMenuData) do
                            if opt.value ~= "any" and newSet[opt.value] then
                                count = count + 1
                            end
                        end
                        if count == 0 or count >= (#factionMenuData - 1) then
                            RR.Config:SetFilterSetting("factionFilter", "any")
                        else
                            RR.Config:SetFilterSetting("factionFilter", newSet)
                        end
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            })
        end
        return menu
    end

    instance.factionBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 90, RR.L["DROPDOWN_FACTION"], function(selfF)
        RR.UI.Dropdown:Show(selfF, buildFactionMenu, true)
    end)
    instance.factionBtn:SetPoint("LEFT", instance.sourceBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.factionBtn, RR.L["TOOLTIP_FACTION_FILTER_TITLE"], RR.L["TOOLTIP_FACTION_FILTER_DESC"])

    -- Dropdown 2: Reputation (Ruf-Fraktionen filtered dynamically by current factionFilter)
    local function buildReputationMenu()
        local curFaction = RR.Config:GetFilterSetting("factionFilter") or "any"
        local curRep = RR.Config:GetFilterSetting("repFilter") or "any"
        local defaultRepIcon = (curFaction == "Alliance" and (RR.ADDON_PATH .. "\\images\\alliance.tga")) or
                               (curFaction == "Horde" and (RR.ADDON_PATH .. "\\images\\horde.tga")) or
                               (RR.ADDON_PATH .. "\\images\\neutral.tga")

        local isAllChecked = (curRep == "any")

        local menu = {
            {
                text = RR.L["REP_ALL"],
                value = "any",
                icon = defaultRepIcon,
                checked = isAllChecked,
                func = function()
                    RR.Config:SetFilterSetting("repFilter", "any")
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            },
        }

        local classicFactions, tbcFactions = RR.DB:GetReputationFactions(curFaction)

        local function getRepFactionIcon(allegiance)
            if allegiance == "Alliance" then
                return RR.ADDON_PATH .. "\\images\\alliance.tga"
            elseif allegiance == "Horde" then
                return RR.ADDON_PATH .. "\\images\\horde.tga"
            else
                return RR.ADDON_PATH .. "\\images\\neutral.tga"
            end
        end

        local function addFactionEntry(fObj)
            local isChecked = false
            if type(curRep) == "table" then
                isChecked = (curRep[fObj.id] == true)
            elseif type(curRep) == "number" then
                isChecked = (curRep == fObj.id)
            end

            table.insert(menu, {
                text = fObj.name,
                value = fObj.id,
                icon = getRepFactionIcon(fObj.allegiance),
                checked = isChecked,
                func = function()
                    local newSet = {}
                    if type(curRep) == "table" then
                        for k, v in pairs(curRep) do newSet[k] = v end
                    elseif type(curRep) == "number" and curRep > 0 then
                        newSet[curRep] = true
                    end
                    if newSet[fObj.id] then
                        newSet[fObj.id] = nil
                    else
                        newSet[fObj.id] = true
                    end
                    local count = 0
                    for k, v in pairs(newSet) do
                        if v then count = count + 1 end
                    end
                    if count == 0 then
                        RR.Config:SetFilterSetting("repFilter", "any")
                    else
                        RR.Config:SetFilterSetting("repFilter", newSet)
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            })
        end

        if RR.DB:IsTBC() and #tbcFactions > 0 then
            table.insert(menu, {
                text = "--- The Burning Crusade ---",
                isHeader = true,
            })
            for _, fObj in ipairs(tbcFactions) do
                addFactionEntry(fObj)
            end

            table.insert(menu, {
                text = "--- Classic Era ---",
                isHeader = true,
            })
            for _, fObj in ipairs(classicFactions) do
                addFactionEntry(fObj)
            end
        else
            for _, fObj in ipairs(classicFactions) do
                addFactionEntry(fObj)
            end
        end

        return menu
    end

    instance.repBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 115, RR.L["DROPDOWN_REPUTATION"], function(selfF)
        RR.UI.Dropdown:Show(selfF, buildReputationMenu, true)
    end)
    instance.repBtn:SetPoint("LEFT", instance.factionBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.repBtn, RR.L["TOOLTIP_REP_FILTER_TITLE"], RR.L["TOOLTIP_REP_FILTER_DESC"])

    local function buildSpecMenu()
        local currentProf = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
        local curSpec = RR.Config:GetFilterSetting("specFilter") or "any"
        local specs = RR.DB:GetSpecialisations(currentProf)
        local isAllChecked = (curSpec == "any")

        local menu = {
            {
                text = RR.L["SPEC_ALL"],
                value = "any",
                icon = "Interface\\Icons\\INV_Misc_Book_08",
                checked = isAllChecked,
                func = function()
                    RR.Config:SetFilterSetting("specFilter", "any")
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            }
        }
        for _, sp in ipairs(specs) do
            local sName = RR.DB:GetLocalizedText(sp.name)
            if sName and sName ~= "" then
                local isChecked = false
                if type(curSpec) == "table" then
                    isChecked = (curSpec[sp.id] == true)
                elseif type(curSpec) == "number" then
                    isChecked = (curSpec == sp.id)
                end

                table.insert(menu, {
                    text = sName,
                    value = sp.id,
                    icon = "Interface\\Icons\\INV_Misc_Wrench_01",
                    checked = isChecked,
                    func = function()
                        local newSet = {}
                        if type(curSpec) == "table" then
                            for k, v in pairs(curSpec) do newSet[k] = v end
                        elseif type(curSpec) == "number" and curSpec > 0 then
                            newSet[curSpec] = true
                        end
                        if newSet[sp.id] then
                            newSet[sp.id] = nil
                        else
                            newSet[sp.id] = true
                        end
                        local count = 0
                        for k, v in pairs(newSet) do
                            if v then count = count + 1 end
                        end
                        if count == 0 or count >= #specs then
                            RR.Config:SetFilterSetting("specFilter", "any")
                        else
                            RR.Config:SetFilterSetting("specFilter", newSet)
                        end
                        instance:UpdateFilterButtons()
                        if instance.onRefresh then instance.onRefresh() end
                    end,
                })
            end
        end
        return menu
    end
    instance.specBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 110, RR.L["DROPDOWN_SPEC"], function(selfF)
        RR.UI.Dropdown:Show(selfF, buildSpecMenu, true)
    end)
    instance.specBtn:SetPoint("LEFT", instance.repBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.specBtn, RR.L["TOOLTIP_SPEC_FILTER_TITLE"], RR.L["TOOLTIP_SPEC_FILTER_DESC"])

    local function buildPhaseMenu()
        local isTBC = RR.DB:IsTBC()
        local curPhase = RR.Config:GetFilterSetting("phaseFilter") or 0
        local isAllChecked = (curPhase == 0 or curPhase == "any")

        local maxPhases = isTBC and 5 or 6
        local icons = isTBC and {
            "Interface\\Icons\\Spell_Fire_MoltenBlood",
            "Interface\\Icons\\Spell_Nature_Earthquake",
            "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
            "Interface\\Icons\\Ability_Hunter_Pet_Bat",
            "Interface\\Icons\\Spell_Holy_InnerFire",
        } or {
            "Interface\\Icons\\Spell_Fire_MoltenBlood",
            "Interface\\Icons\\Spell_Nature_Earthquake",
            "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
            "Interface\\Icons\\Ability_Hunter_Pet_Bat",
            "Interface\\Icons\\INV_Misc_AhnQirajTrinket_03",
            "Interface\\Icons\\Spell_Shadow_DeathPact",
        }

        local list = {
            {
                text = RR.L["PHASE_ALL"],
                value = 0,
                icon = "Interface\\Icons\\INV_Misc_Book_08",
                checked = isAllChecked,
                func = function()
                    RR.Config:SetFilterSetting("phaseFilter", 0)
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            },
        }

        for p = 1, maxPhases do
            local isChecked = false
            if type(curPhase) == "table" then
                isChecked = (curPhase[p] == true)
            elseif type(curPhase) == "number" then
                isChecked = (curPhase == p)
            end

            table.insert(list, {
                text = RR.DB:GetPhaseName(p),
                value = p,
                icon = icons[p] or "Interface\\Icons\\INV_Misc_Book_08",
                checked = isChecked,
                func = function()
                    local newSet = {}
                    if type(curPhase) == "table" then
                        for k, v in pairs(curPhase) do newSet[k] = v end
                    elseif type(curPhase) == "number" and curPhase > 0 then
                        newSet[curPhase] = true
                    end
                    if newSet[p] then
                        newSet[p] = nil
                    else
                        newSet[p] = true
                    end
                    local count = 0
                    for checkP = 1, maxPhases do
                        if newSet[checkP] then count = count + 1 end
                    end
                    if count == 0 or count >= maxPhases then
                        RR.Config:SetFilterSetting("phaseFilter", 0)
                    else
                        RR.Config:SetFilterSetting("phaseFilter", newSet)
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
            })
        end
        return list
    end
    instance.phaseBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 90, RR.L["DROPDOWN_PHASE"], function(selfF)
        RR.UI.Dropdown:Show(selfF, buildPhaseMenu, true)
    end)
    instance.phaseBtn:SetPoint("LEFT", instance.specBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.phaseBtn, RR.L["TOOLTIP_PHASE_FILTER_TITLE"], RR.L["TOOLTIP_PHASE_FILTER_DESC"])

    -- ROW 3: Zone: [ Region v ] [ Zone v ] [ Any Zone ] [ Current Zone ] [ <Last Zone> ]
    local zoneLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("TOPLEFT", 8, -72)
    zoneLabel:SetTextColor(1, 0.82, 0, 1)
    zoneLabel:SetText(RR.L["LABEL_ZONE_COLON"])

    instance.continentBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, RR.L["REGION_ALL"], function(selfF)
        local menu = {
            {
                text = RR.L["REGION_ALL"],
                func = function()
                    RR.Config:SetFilterSetting("continentFilter", "any")
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText(RR.L["REGION_ALL"])
                    if instance.zoneDropBtn and instance.zoneDropBtn.text then
                        instance.zoneDropBtn.text:SetText(RR.L["DROPDOWN_ZONE"])
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("continentFilter") or "any") == "any",
            }
        }
        local continents = RR.DB:GetContinents()
        for _, cont in ipairs(continents) do
            local contId = cont.id
            local contName = cont.name
            table.insert(menu, {
                text = contName,
                func = function()
                    RR.Config:SetFilterSetting("continentFilter", contId)
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText(contName)
                    if instance.zoneDropBtn and instance.zoneDropBtn.text then
                        instance.zoneDropBtn.text:SetText(RR.L["DROPDOWN_ZONE"])
                    end
                    instance:UpdateFilterButtons()
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("continentFilter") or "any") == contId,
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
                    local prof = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
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
        local prof = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
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

        local curSource = RR.Config:GetFilterSetting("sourceFilter") or "any"
        if self.sourceBtn and self.sourceBtn.text then
            if type(curSource) == "table" then
                local keys = {}
                for k, v in pairs(curSource) do if v then table.insert(keys, k) end end
                if #keys == 0 then
                    self.sourceBtn.text:SetText(RR.L["DROPDOWN_SOURCE"])
                elseif #keys == 1 then
                    self.sourceBtn.text:SetText(RR.L["SOURCE_" .. string.upper(keys[1])] or keys[1])
                else
                    self.sourceBtn.text:SetText(string.format("%s (%d)", RR.L["DROPDOWN_SOURCE"], #keys))
                end
            elseif curSource == "any" then
                self.sourceBtn.text:SetText(RR.L["DROPDOWN_SOURCE"])
            else
                self.sourceBtn.text:SetText(RR.L["SOURCE_" .. string.upper(curSource)] or curSource)
            end
        end

        local curFaction = RR.Config:GetFilterSetting("factionFilter") or "any"
        if self.factionBtn and self.factionBtn.text then
            if type(curFaction) == "table" then
                local keys = {}
                for k, v in pairs(curFaction) do if v then table.insert(keys, k) end end
                if #keys == 0 then
                    self.factionBtn.text:SetText(RR.L["DROPDOWN_FACTION"])
                elseif #keys == 1 then
                    self.factionBtn.text:SetText(RR.L["FACTION_" .. string.upper(keys[1])] or keys[1])
                else
                    self.factionBtn.text:SetText(string.format("%s (%d)", RR.L["DROPDOWN_FACTION"], #keys))
                end
            elseif curFaction == "any" then
                self.factionBtn.text:SetText(RR.L["DROPDOWN_FACTION"])
            else
                self.factionBtn.text:SetText(RR.L["FACTION_" .. string.upper(curFaction)] or curFaction)
            end
        end

        local curRep = RR.Config:GetFilterSetting("repFilter") or "any"
        if self.repBtn and self.repBtn.text then
            if type(curRep) == "table" then
                local keys = {}
                for k, v in pairs(curRep) do if v then table.insert(keys, k) end end
                if #keys == 0 then
                    self.repBtn.text:SetText(RR.L["DROPDOWN_REPUTATION"])
                elseif #keys == 1 then
                    local fName = RR.DB:GetFactionName(keys[1])
                    self.repBtn.text:SetText(fName or RR.L["DROPDOWN_REPUTATION"])
                else
                    self.repBtn.text:SetText(string.format("%s (%d)", RR.L["DROPDOWN_REPUTATION"], #keys))
                end
            elseif curRep == "any" or type(curRep) ~= "number" then
                self.repBtn.text:SetText(RR.L["DROPDOWN_REPUTATION"])
            else
                local fName = RR.DB:GetFactionName(curRep)
                self.repBtn.text:SetText(fName or RR.L["DROPDOWN_REPUTATION"])
            end
        end

        local curSpec = RR.Config:GetFilterSetting("specFilter") or "any"
        if self.specBtn and self.specBtn.text then
            if type(curSpec) == "table" then
                local keys = {}
                for k, v in pairs(curSpec) do if v then table.insert(keys, k) end end
                if #keys == 0 then
                    self.specBtn.text:SetText(RR.L["DROPDOWN_SPEC"])
                elseif #keys == 1 then
                    local sName = RR.DB:GetSpecialisationName(keys[1])
                    self.specBtn.text:SetText(sName or RR.L["DROPDOWN_SPEC"])
                else
                    self.specBtn.text:SetText(string.format("%s (%d)", RR.L["DROPDOWN_SPEC"], #keys))
                end
            elseif curSpec == "any" then
                self.specBtn.text:SetText(RR.L["DROPDOWN_SPEC"])
            else
                local sName = RR.DB:GetSpecialisationName(curSpec)
                self.specBtn.text:SetText(sName or RR.L["DROPDOWN_SPEC"])
            end
        end

        local curPhase = RR.Config:GetFilterSetting("phaseFilter") or 0
        if self.phaseBtn and self.phaseBtn.text then
            if type(curPhase) == "table" then
                local phases = {}
                for p, v in pairs(curPhase) do if v then table.insert(phases, p) end end
                table.sort(phases)
                if #phases == 0 then
                    self.phaseBtn.text:SetText(RR.L["DROPDOWN_PHASE"])
                elseif #phases == 1 then
                    self.phaseBtn.text:SetText(RR.DB:GetPhaseName(phases[1]))
                else
                    self.phaseBtn.text:SetText(string.format("%s (%s)", RR.L["DROPDOWN_PHASE"], table.concat(phases, ", ")))
                end
            elseif curPhase == 0 or curPhase == "any" then
                self.phaseBtn.text:SetText(RR.L["DROPDOWN_PHASE"])
            else
                self.phaseBtn.text:SetText(RR.DB:GetPhaseName(curPhase))
            end
        end
    end

    function instance:UpdateLastZoneForCurrentProfession()
        local prof = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
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
