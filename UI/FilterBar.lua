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
    instance.sourceBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 95, RR.L["DROPDOWN_SOURCE"], function(selfF)
        local menu = {}
        for _, itm in ipairs(sourceMenu) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("sourceFilter", itm.value)
                    selfF.text:SetText(itm.value == "any" and RR.L["DROPDOWN_SOURCE"] or itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("sourceFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.sourceBtn:SetPoint("LEFT", sourceLabel, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.sourceBtn, RR.L["TOOLTIP_SOURCE_FILTER_TITLE"], RR.L["TOOLTIP_SOURCE_FILTER_DESC"])

    -- Dropdown 1: Faction (Alliance / Horde / Neutral / All)
    local factionMenu = {
        { text = RR.L["FACTION_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
        { text = RR.L["FACTION_ALLIANCE"], value = "Alliance", icon = RR.ADDON_PATH .. "\\images\\alliance.tga" },
        { text = RR.L["FACTION_HORDE"], value = "Horde", icon = RR.ADDON_PATH .. "\\images\\horde.tga" },
        { text = RR.L["FACTION_NEUTRAL"], value = "Neutral", icon = RR.ADDON_PATH .. "\\images\\neutral.tga" },
    }
    instance.factionBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 90, RR.L["DROPDOWN_FACTION"], function(selfF)
        local menu = {}
        for _, itm in ipairs(factionMenu) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("factionFilter", itm.value)
                    selfF.text:SetText(itm.value == "any" and RR.L["DROPDOWN_FACTION"] or itm.text)

                    -- Check if current reputation filter is still valid under new faction filter
                    local curRep = RR.Config:GetFilterSetting("repFilter")
                    if curRep and curRep ~= "any" and type(curRep) == "number" then
                        local cList, tList = RR.DB:GetReputationFactions(itm.value)
                        local isValid = false
                        for _, f in ipairs(cList) do if f.id == curRep then isValid = true break end end
                        if not isValid then
                            for _, f in ipairs(tList) do if f.id == curRep then isValid = true break end end
                        end
                        if not isValid then
                            RR.Config:SetFilterSetting("repFilter", "any")
                            if instance.repBtn and instance.repBtn.text then
                                instance.repBtn.text:SetText(RR.L["DROPDOWN_REPUTATION"])
                            end
                        end
                    end

                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("factionFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.factionBtn:SetPoint("LEFT", instance.sourceBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.factionBtn, RR.L["TOOLTIP_FACTION_FILTER_TITLE"], RR.L["TOOLTIP_FACTION_FILTER_DESC"])

    -- Dropdown 2: Reputation (Ruf-Fraktionen filtered dynamically by current factionFilter)
    local function buildReputationMenu()
        local curFaction = RR.Config:GetFilterSetting("factionFilter") or "any"
        local menu = {
            { text = RR.L["REP_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" },
        }

        local classicFactions, tbcFactions = RR.DB:GetReputationFactions(curFaction)

        if RR.DB:IsTBC() and #tbcFactions > 0 then
            table.insert(menu, {
                text = "--- The Burning Crusade ---",
                isHeader = true,
            })
            for _, fObj in ipairs(tbcFactions) do
                table.insert(menu, {
                    text = fObj.name,
                    value = fObj.id,
                    icon = (fObj.allegiance == "Alliance" and (RR.ADDON_PATH .. "\\images\\alliance.tga")) or
                           (fObj.allegiance == "Horde" and (RR.ADDON_PATH .. "\\images\\horde.tga")) or
                           (RR.ADDON_PATH .. "\\images\\neutral.tga"),
                })
            end

            table.insert(menu, {
                text = "--- Classic Era ---",
                isHeader = true,
            })
            for _, fObj in ipairs(classicFactions) do
                table.insert(menu, {
                    text = fObj.name,
                    value = fObj.id,
                    icon = (fObj.allegiance == "Alliance" and (RR.ADDON_PATH .. "\\images\\alliance.tga")) or
                           (fObj.allegiance == "Horde" and (RR.ADDON_PATH .. "\\images\\horde.tga")) or
                           (RR.ADDON_PATH .. "\\images\\neutral.tga"),
                })
            end
        else
            table.insert(menu, {
                text = "--- " .. (RR.L["SOURCE_REPUTATION"] or "Ruf") .. " ---",
                isHeader = true,
            })
            for _, fObj in ipairs(classicFactions) do
                table.insert(menu, {
                    text = fObj.name,
                    value = fObj.id,
                    icon = (fObj.allegiance == "Alliance" and (RR.ADDON_PATH .. "\\images\\alliance.tga")) or
                           (fObj.allegiance == "Horde" and (RR.ADDON_PATH .. "\\images\\horde.tga")) or
                           (RR.ADDON_PATH .. "\\images\\neutral.tga"),
                })
            end
        end

        return menu
    end

    instance.repBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 115, RR.L["DROPDOWN_REPUTATION"], function(selfF)
        local menu = {}
        for _, itm in ipairs(buildReputationMenu()) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                isHeader = itm.isHeader,
                func = function()
                    RR.Config:SetFilterSetting("repFilter", itm.value)
                    selfF.text:SetText(itm.value == "any" and RR.L["DROPDOWN_REPUTATION"] or itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("repFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.repBtn:SetPoint("LEFT", instance.factionBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.repBtn, RR.L["TOOLTIP_REP_FILTER_TITLE"], RR.L["TOOLTIP_REP_FILTER_DESC"])

    local function buildSpecMenu()
        local currentProf = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
        local specs = RR.DB:GetSpecialisations(currentProf)
        local menu = {
            { text = RR.L["SPEC_ALL"], value = "any", icon = "Interface\\Icons\\INV_Misc_Book_08" }
        }
        for _, sp in ipairs(specs) do
            local sName = RR.DB:GetLocalizedText(sp.name)
            if sName and sName ~= "" then
                table.insert(menu, {
                    text = sName,
                    value = sp.id,
                    icon = "Interface\\Icons\\INV_Misc_Wrench_01",
                })
            end
        end
        return menu
    end
    instance.specBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 110, RR.L["DROPDOWN_SPEC"], function(selfF)
        local menu = {}
        for _, itm in ipairs(buildSpecMenu()) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("specFilter", itm.value)
                    selfF.text:SetText(itm.value == "any" and RR.L["DROPDOWN_SPEC"] or itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("specFilter") or "any") == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
    end)
    instance.specBtn:SetPoint("LEFT", instance.repBtn, "RIGHT", 6, 0)
    RR.UI.Theme:AddTooltip(instance.specBtn, RR.L["TOOLTIP_SPEC_FILTER_TITLE"], RR.L["TOOLTIP_SPEC_FILTER_DESC"])

    local function buildPhaseMenu()
        local isTBC = RR.DB:IsTBC()
        local list = {
            { text = RR.L["PHASE_ALL"], value = 0, icon = "Interface\\Icons\\INV_Misc_Book_08" },
        }
        local maxPhases = isTBC and 5 or 6
        for p = 1, maxPhases do
            table.insert(list, {
                text = RR.DB:GetPhaseName(p),
                value = p,
                icon = "Interface\\Icons\\INV_Misc_Book_09",
            })
        end
        return list
    end
    instance.phaseBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 90, RR.L["DROPDOWN_PHASE"], function(selfF)
        local menu = {}
        for _, itm in ipairs(buildPhaseMenu()) do
            table.insert(menu, {
                text = itm.text,
                icon = itm.icon,
                func = function()
                    RR.Config:SetFilterSetting("phaseFilter", itm.value)
                    selfF.text:SetText(itm.value == 0 and RR.L["DROPDOWN_PHASE"] or itm.text)
                    if instance.onRefresh then instance.onRefresh() end
                end,
                checked = (RR.Config:GetFilterSetting("phaseFilter") or 0) == itm.value,
            })
        end
        RR.UI.Dropdown:Show(selfF, menu)
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

        local curSpec = RR.Config:GetFilterSetting("specFilter") or "any"
        if self.specBtn and self.specBtn.text then
            if curSpec == "any" then
                self.specBtn.text:SetText(RR.L["DROPDOWN_SPEC"])
            else
                local sName = RR.DB:GetSpecialisationName(curSpec)
                self.specBtn.text:SetText(sName or RR.L["DROPDOWN_SPEC"])
            end
        end

        local curFaction = RR.Config:GetFilterSetting("factionFilter") or "any"
        if self.factionBtn and self.factionBtn.text then
            if curFaction == "any" then
                self.factionBtn.text:SetText(RR.L["DROPDOWN_FACTION"])
            else
                self.factionBtn.text:SetText(RR.L["FACTION_" .. string.upper(curFaction)] or curFaction)
            end
        end

        local curRep = RR.Config:GetFilterSetting("repFilter") or "any"
        if self.repBtn and self.repBtn.text then
            if curRep == "any" then
                self.repBtn.text:SetText(RR.L["DROPDOWN_REPUTATION"])
            else
                local fName = RR.DB:GetFactionName(curRep)
                self.repBtn.text:SetText(fName or RR.L["DROPDOWN_REPUTATION"])
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
