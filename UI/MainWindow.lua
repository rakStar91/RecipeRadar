-- ============================================================================
-- RecipeRadar: UI/MainWindow.lua
-- Main tracker interface matching the exact custom 3-row layout and artwork
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.MainWindow = {}

local NUM_VISIBLE_ROWS = 19
local ROW_HEIGHT = 20

function RR.UI.MainWindow:Initialize()
    if self.frame then return end

    local f = CreateFrame("Frame", "RecipeRadarFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(840, 560)
    f:SetPoint("CENTER", 0, 0)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(selfF) selfF:StartMoving() end)
    f:SetScript("OnDragStop", function(selfF) selfF:StopMovingOrSizing() end)
    f:SetFrameStrata("HIGH")

    RR.UI.Theme:SkinWindow(f)
    self.frame = f

    -- 1. Centered Title Plaque Banner
    self.titlePlaque = RR.UI.Theme:CreateTitlePlaque(f, 420, 38, RR.NAME)
    self.titlePlaque:SetPoint("TOP", f, "TOP", 0, 12)

    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)
    RR.UI.Theme:AddTooltip(close, RR.L["TOOLTIP_CLOSE_TITLE"], RR.L["TOOLTIP_CLOSE_DESC"])

    -- 2. Compact Spacious 3-Row Filter Area
    local filterArea = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    filterArea:SetPoint("TOPLEFT", 8, -32)
    filterArea:SetPoint("TOPRIGHT", -8, -32)
    filterArea:SetHeight(98)
    RR.UI.Theme:SkinPanel(filterArea, 0.4)
    self.filterArea = filterArea

    -- Mode Buttons (Fehlend, Bekannt, Alle) placed on the far right column
    self.modeBtns = {}
    local modeDefs = {
        { id = "missing", text = "Fehlend", top = -4 },
        { id = "known", text = "Bekannt", top = -36 },
        { id = "all", text = "Alle", top = -68 },
    }
    for _, md in ipairs(modeDefs) do
        local mBtn = RR.UI.Theme:CreateDarkButton(filterArea, md.text, 92, 24)
        mBtn:SetPoint("TOPRIGHT", -6, md.top)
        mBtn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("mode", md.id)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        if md.id == "missing" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_MISSING_TITLE"], RR.L["TOOLTIP_MODE_MISSING_DESC"])
        elseif md.id == "known" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_KNOWN_TITLE"], RR.L["TOOLTIP_MODE_KNOWN_DESC"])
        elseif md.id == "all" then
            RR.UI.Theme:AddTooltip(mBtn, RR.L["TOOLTIP_MODE_ALL_TITLE"], RR.L["TOOLTIP_MODE_ALL_DESC"])
        end
        self.modeBtns[md.id] = mBtn
    end

    -- ROW 1: Name: [ Search EditBox ] [ Suche ]
    local nameLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", 8, -8)
    nameLabel:SetTextColor(1, 0.82, 0, 1)
    nameLabel:SetText("Name:")

    local searchBox = CreateFrame("EditBox", nil, filterArea, BackdropTemplateMixin and "BackdropTemplate")
    searchBox:SetPoint("TOPLEFT", nameLabel, "TOPRIGHT", 14, 3)
    searchBox:SetSize(470, 24)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(6, 6, 0, 0)
    RR.UI.Theme:SkinPanel(searchBox, 0.9)

    searchBox:SetScript("OnTextChanged", function(selfBox)
        self.searchQuery = selfBox:GetText()
        self:Refresh()
    end)
    searchBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        self:Refresh()
    end)
    searchBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:SetText("")
        selfBox:ClearFocus()
        self:Refresh()
    end)
    self.searchBox = searchBox

    local searchBtn = RR.UI.Theme:CreateDarkButton(filterArea, "Suche", 80, 24)
    searchBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    searchBtn:SetScript("OnClick", function()
        self.searchBox:ClearFocus()
        self:Refresh()
    end)
    RR.UI.Theme:AddTooltip(searchBox, RR.L["TOOLTIP_SEARCH_TITLE"], RR.L["TOOLTIP_SEARCH_DESC"])
    RR.UI.Theme:AddTooltip(searchBtn, RR.L["TOOLTIP_SEARCH_BTN_TITLE"], RR.L["TOOLTIP_SEARCH_BTN_DESC"])

    -- ROW 2: Quelle: [ Quelle (6/6) v ] [ Fraktion v ] [ Spezialisierung v ] [ Phase v ]
    local sourceLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", 8, -40)
    sourceLabel:SetTextColor(1, 0.82, 0, 1)
    sourceLabel:SetText("Quelle:")

    local sourceMenu = {
        { text = "Alle Quellen", value = "any" },
        { text = "Lehrer", value = "trainer", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { text = "Händler", value = "vendor", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { text = "Quest", value = "quest", icon = "Interface\\GossipFrame\\AvailableQuestIcon" },
        { text = "Gegner-Beute (Drop)", value = "drop", icon = "Interface\\GossipFrame\\VendorGossipIcon" },
        { text = "Weltereignis", value = "holiday", icon = "Interface\\Icons\\INV_Misc_Gift_01" },
        { text = "Ruf", value = "reputation", icon = "Interface\\Icons\\Achievement_Reputation_01" },
    }
    self.sourceBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, "Quelle", function(selfF)
        local menu = {}
        for _, itm in ipairs(sourceMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("sourceFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    self:Refresh()
                end,
                checked = (RR.Config:GetFilterSetting("sourceFilter") or "any") == itm.value,
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.sourceBtn:SetPoint("LEFT", sourceLabel, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(self.sourceBtn, RR.L["TOOLTIP_SOURCE_FILTER_TITLE"], RR.L["TOOLTIP_SOURCE_FILTER_DESC"])

    local factionMenu = {
        { text = "Alle Fraktionen", value = "any" },
        { text = "Allianz", value = "Alliance", icon = RR.ADDON_PATH .. "\\images\\alliance.tga" },
        { text = "Horde", value = "Horde", icon = RR.ADDON_PATH .. "\\images\\horde.tga" },
        { text = "Neutral", value = "Neutral", icon = RR.ADDON_PATH .. "\\images\\neutral.tga" },
        { text = "Argentumdämmerung", value = 529 },
        { text = "Thoriumbruderschaft", value = 59 },
        { text = "Holzschlundfeste", value = 576 },
        { text = "Stamm der Zandalari", value = 270 },
        { text = "Hydraxianer", value = 749 },
        { text = "Dunkelmond-Jahrmarkt", value = 909 },
        { text = "Cenarischer Zirkel", value = 609 },
    }
    self.factionBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, "Fraktion", function(selfF)
        local menu = {}
        for _, itm in ipairs(factionMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("factionFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    self:Refresh()
                end,
                checked = (RR.Config:GetFilterSetting("factionFilter") or "any") == itm.value,
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.factionBtn:SetPoint("LEFT", self.sourceBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(self.factionBtn, RR.L["TOOLTIP_FACTION_FILTER_TITLE"], RR.L["TOOLTIP_FACTION_FILTER_DESC"])

    self.specBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 135, "Spezialisierung", function(selfF)
        local menu = {
            { text = "Alle Spezialisierungen", value = "any" },
        }
        self:ShowDropdown(selfF, menu)
    end)
    self.specBtn:SetPoint("LEFT", self.factionBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(self.specBtn, RR.L["TOOLTIP_SPEC_FILTER_TITLE"], RR.L["TOOLTIP_SPEC_FILTER_DESC"])

    local phaseMenu = {
        { text = RR.L["PHASE_ALL"], value = 0 },
        { text = RR.L["PHASE_1"], value = 1 },
        { text = RR.L["PHASE_2"], value = 2 },
        { text = RR.L["PHASE_3"], value = 3 },
        { text = RR.L["PHASE_4"], value = 4 },
        { text = RR.L["PHASE_5"], value = 5 },
        { text = RR.L["PHASE_6"], value = 6 },
    }
    self.phaseBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 105, "Phase", function(selfF)
        local menu = {}
        for _, itm in ipairs(phaseMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("phaseFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    self:Refresh()
                end,
                checked = (RR.Config:GetFilterSetting("phaseFilter") or 0) == itm.value,
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.phaseBtn:SetPoint("LEFT", self.specBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(self.phaseBtn, RR.L["TOOLTIP_PHASE_FILTER_TITLE"], RR.L["TOOLTIP_PHASE_FILTER_DESC"])

    -- ROW 3: Zone: [ Jede Zone v ] [ Zone v ] [ Jede Zone ] [ Aktuelle Zone ] [ <ZoneName> ]
    local zoneLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("TOPLEFT", 8, -72)
    zoneLabel:SetTextColor(1, 0.82, 0, 1)
    zoneLabel:SetText("Zone:")

    -- Restore saved Last Zone or default
    local savedLastZoneName = RR.Config:GetFilterSetting("lastZoneName")
    local savedLastZoneId = RR.Config:GetFilterSetting("lastZoneId")
    local savedLastZoneCont = RR.Config:GetFilterSetting("lastZoneCont") or "any"
    local savedLastZoneContName = RR.Config:GetFilterSetting("lastZoneContName") or "Jede Region"

    if savedLastZoneId and savedLastZoneName then
        self.lastCustomZone = { id = savedLastZoneId, name = savedLastZoneName, cont = savedLastZoneCont, contName = savedLastZoneContName }
    else
        self.lastCustomZone = { id = nil, name = "Letzte Zone", cont = "any", contName = "Jede Region" }
    end

    local initialContText = savedLastZoneContName or "Jede Region"
    self.continentBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, initialContText, function(selfF)
        local contMenu = {
            { text = "Jede Region", value = "any" },
            { text = "Kalimdor", value = 1 },
            { text = "Östliche Königreiche", value = 2 },
            { text = "Schlachtfelder", value = 3 },
            { text = "Dungeons", value = 4 },
            { text = "Schlachtzüge", value = 5 },
        }
        local menu = {}
        for _, itm in ipairs(contMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("continentFilter", itm.value)
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText(itm.text)
                    if self.zoneDropBtn and self.zoneDropBtn.text then
                        self.zoneDropBtn.text:SetText("Zone")
                    end
                    self:UpdateFilterButtons()
                    self:Refresh()
                end,
                checked = (RR.Config:GetFilterSetting("continentFilter") or "any") == itm.value,
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.continentBtn:SetPoint("LEFT", zoneLabel, "RIGHT", 14, 0)
    RR.UI.Theme:AddTooltip(self.continentBtn, RR.L["TOOLTIP_REGION_FILTER_TITLE"], RR.L["TOOLTIP_REGION_FILTER_DESC"])

    self.zoneDropBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, "Zone", function(selfF)
        local curCont = RR.Config:GetFilterSetting("continentFilter") or "any"
        local zones = RR.DB:GetZonesInContinent(curCont)
        local curZone = RR.Config:GetFilterSetting("zoneFilter") or "any"

        local menu = {
            {
                text = "Alle Zonen",
                func = function()
                    RR.Config:SetFilterSetting("zoneFilter", "any")
                    selfF.text:SetText("Zone")
                    self:UpdateFilterButtons()
                    self:Refresh()
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
                    local contLabel = (self.continentBtn and self.continentBtn.text and self.continentBtn.text:GetText()) or "Jede Region"
                    self.lastCustomZone = { id = z.id, name = z.name, cont = curCont, contName = contLabel }
                    RR.Config:SetFilterSetting("lastZoneId", z.id)
                    RR.Config:SetFilterSetting("lastZoneName", z.name)
                    RR.Config:SetFilterSetting("lastZoneCont", curCont)
                    RR.Config:SetFilterSetting("lastZoneContName", contLabel)
                    if self.zoneBtns and self.zoneBtns.last then
                        self.zoneBtns.last:SetText(z.name)
                    end
                    self:UpdateFilterButtons()
                    self:Refresh()
                end,
                checked = (curZone == z.id),
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.zoneDropBtn:SetPoint("LEFT", self.continentBtn, "RIGHT", 8, 0)
    RR.UI.Theme:AddTooltip(self.zoneDropBtn, RR.L["TOOLTIP_ZONE_FILTER_TITLE"], RR.L["TOOLTIP_ZONE_FILTER_DESC"])

    -- Quick Zone Buttons (Jede Zone, Aktuelle Zone, Letzte Zone)
    self.zoneBtns = {}
    local zBtnAny = RR.UI.Theme:CreateDarkButton(filterArea, "Jede Zone", 80, 24)
    zBtnAny:SetPoint("LEFT", self.zoneDropBtn, "RIGHT", 10, 0)
    zBtnAny:SetScript("OnClick", function()
        RR.Config:SetFilterSetting("continentFilter", "any")
        RR.Config:SetFilterSetting("zoneFilter", "any")
        if self.continentBtn and self.continentBtn.text then self.continentBtn.text:SetText("Jede Region") end
        if self.zoneDropBtn and self.zoneDropBtn.text then self.zoneDropBtn.text:SetText("Zone") end
        self:UpdateFilterButtons()
        self:Refresh()
    end)
    RR.UI.Theme:AddTooltip(zBtnAny, RR.L["TOOLTIP_QUICK_ANY_TITLE"], RR.L["TOOLTIP_QUICK_ANY_DESC"])
    self.zoneBtns.any = zBtnAny

    local zBtnCurrent = RR.UI.Theme:CreateDarkButton(filterArea, "Aktuelle Zone", 95, 24)
    zBtnCurrent:SetPoint("LEFT", zBtnAny, "RIGHT", 5, 0)
    zBtnCurrent:SetScript("OnClick", function()
        local curRealZone = GetRealZoneText() or "Aktuelle Zone"
        RR.Config:SetFilterSetting("zoneFilter", "current")
        if self.zoneDropBtn and self.zoneDropBtn.text then self.zoneDropBtn.text:SetText(curRealZone) end
        self:UpdateFilterButtons()
        self:Refresh()
    end)
    RR.UI.Theme:AddTooltip(zBtnCurrent, RR.L["TOOLTIP_QUICK_CURRENT_TITLE"], RR.L["TOOLTIP_QUICK_CURRENT_DESC"])
    self.zoneBtns.current = zBtnCurrent

    local lastLabel = self.lastCustomZone.name or "Letzte Zone"
    local zBtnLast = RR.UI.Theme:CreateDarkButton(filterArea, lastLabel, 110, 24)
    zBtnLast:SetPoint("LEFT", zBtnCurrent, "RIGHT", 5, 0)
    zBtnLast:SetScript("OnClick", function()
        if self.lastCustomZone and self.lastCustomZone.id then
            RR.Config:SetFilterSetting("continentFilter", self.lastCustomZone.cont)
            RR.Config:SetFilterSetting("zoneFilter", self.lastCustomZone.id)
            if self.continentBtn and self.continentBtn.text then self.continentBtn.text:SetText(self.lastCustomZone.contName or "Jede Region") end
            if self.zoneDropBtn and self.zoneDropBtn.text then self.zoneDropBtn.text:SetText(self.lastCustomZone.name) end
        end
        self:UpdateFilterButtons()
        self:Refresh()
    end)
    RR.UI.Theme:AddTooltip(zBtnLast, RR.L["TOOLTIP_QUICK_LAST_TITLE"], RR.L["TOOLTIP_QUICK_LAST_DESC"])
    self.zoneBtns.last = zBtnLast

    -- 3. Left Column: Recipe List Pane (Authentic Alternating Rows, Icons & Tooltips)
    local listPane = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    listPane:SetPoint("TOPLEFT", filterArea, "BOTTOMLEFT", 0, -4)
    listPane:SetPoint("BOTTOMLEFT", 8, 32)
    listPane:SetWidth(420)
    RR.UI.Theme:SkinPanel(listPane, 0.95)
    self.listPane = listPane

    self.rows = {}
    for i = 1, NUM_VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, listPane, BackdropTemplateMixin and "BackdropTemplate")
        row:SetPoint("TOPLEFT", 4, -((i - 1) * ROW_HEIGHT + 4))
        row:SetPoint("TOPRIGHT", -22, -((i - 1) * ROW_HEIGHT + 4))
        row:SetHeight(ROW_HEIGHT)

        -- Alternating zebra background
        row.row_bg = row:CreateTexture(nil, "BACKGROUND")
        row.row_bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.row_bg:SetAllPoints(row)
        if i % 2 == 0 then
            row.row_bg:SetVertexColor(1, 1, 1, 0.055)
        else
            row.row_bg:SetVertexColor(1, 1, 1, 0)
        end

        -- Selected highlight texture
        row.selected_bg = row:CreateTexture(nil, "BORDER")
        row.selected_bg:SetTexture(RR.ADDON_PATH .. "\\images\\fill_row_selected.tga")
        row.selected_bg:SetAllPoints(row)
        row.selected_bg:Hide()

        -- Hover highlight
        row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        local hl = row:GetHighlightTexture()
        if hl then hl:SetVertexColor(1, 1, 1, 0.10) end

        -- Text: [Skill] Recipe Name
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetPoint("RIGHT", -56, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)

        -- Dedicated fixed column slots for Sources and Faction
        row.iconSource1 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource1:SetSize(14, 14)
        row.iconSource1:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.iconSource1:Hide()

        row.iconSource2 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource2:SetSize(14, 14)
        row.iconSource2:SetPoint("RIGHT", row.iconSource1, "LEFT", -2, 0)
        row.iconSource2:Hide()

        row.iconSource3 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource3:SetSize(14, 14)
        row.iconSource3:SetPoint("RIGHT", row.iconSource2, "LEFT", -2, 0)
        row.iconSource3:Hide()

        -- Faction Icon ALWAYS to the left of source icons
        row.iconFaction = row:CreateTexture(nil, "OVERLAY")
        row.iconFaction:SetSize(14, 14)
        row.iconFaction:SetPoint("RIGHT", row.iconSource3, "LEFT", -4, 0)
        row.iconFaction:Hide()

        -- Hover Tooltip showing Source and Faction restriction
        row:SetScript("OnEnter", function(selfR)
            if selfR.recipeData then
                GameTooltip:SetOwner(selfR, "ANCHOR_RIGHT")
                GameTooltip:AddLine(selfR.recipeData.name or "Rezept", 1, 0.82, 0)
                if selfR.sourceTooltipSources and selfR.sourceTooltipSources ~= "" then
                    GameTooltip:AddLine("Quelle: " .. selfR.sourceTooltipSources, 1, 1, 1)
                end
                if selfR.sourceTooltipFaction and selfR.sourceTooltipFaction ~= "" then
                    GameTooltip:AddLine("Fraktion: " .. selfR.sourceTooltipFaction, 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(selfRow)
            if selfRow.recipeData then
                RR.UI.MainWindow:SelectRecipe(selfRow.recipeData)
            end
        end)

        self.rows[i] = row
    end

    -- Scrollbar for list
    listPane.SetVerticalScroll = function() end
    local scrollbar = CreateFrame("Slider", "RecipeRadarScroll", listPane, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPRIGHT", -4, -18)
    scrollbar:SetPoint("BOTTOMRIGHT", -4, 18)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(_, val)
        self.scrollOffset = math.floor(val or 0)
        self:RenderList()
    end)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    scrollbar:SetValueStep(1)
    self.scrollbar = scrollbar
    self.scrollOffset = 0

    listPane:EnableMouseWheel(true)
    listPane:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollbar:GetValue()
        scrollbar:SetValue(cur - (delta * 2))
    end)

    -- 4. Right Column: Details Pane (Authentic Key-Value Grid)
    local detailPane = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    detailPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 4, 0)
    detailPane:SetPoint("BOTTOMRIGHT", -8, 32)
    RR.UI.Theme:SkinPanel(detailPane, 0.95)
    self.detailPane = detailPane

    local attrBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    attrBox:SetPoint("TOPLEFT", 6, -6)
    attrBox:SetPoint("TOPRIGHT", -6, -6)
    attrBox:SetHeight(270)
    RR.UI.Theme:SkinPanel(attrBox, 0.7)
    self.attrBox = attrBox

    self.detailFactionIcon = attrBox:CreateTexture(nil, "OVERLAY")
    self.detailFactionIcon:SetSize(28, 28)
    self.detailFactionIcon:SetPoint("TOPRIGHT", -8, -8)

    self.attrRows = {}
    local attrKeys = {
        "Name",
        "Phase",
        "Min. Fertigkeitsstufe",
        "Benötigt Ruf",
        "Spezialisierung",
        "Feiertag",
        "Kosten",
    }
    local attrY = -6
    for i, labelText in ipairs(attrKeys) do
        local rowF = CreateFrame("Frame", nil, attrBox)
        rowF:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 8, attrY)
        rowF:SetPoint("TOPRIGHT", attrBox, "TOPRIGHT", -8, attrY)
        rowF:SetHeight(13)

        local lbl = rowF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 0, 0)
        lbl:SetTextColor(1, 0.82, 0, 1)
        lbl:SetText(labelText)

        local val = rowF:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("TOPLEFT", 135, 0)
        val:SetPoint("TOPRIGHT", 0, 0)
        val:SetJustifyH("LEFT")
        val:SetTextColor(1, 1, 1, 1)
        val:SetWordWrap(false)
        val:SetText("-")

        rowF.label = lbl
        rowF.value = val
        table.insert(self.attrRows, rowF)
        attrY = attrY - 14
    end

    -- "Erlernbar durch:" Header
    local srcHeader = attrBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    srcHeader:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 8, attrY - 4)
    srcHeader:SetTextColor(1, 0.82, 0, 1)
    srcHeader:SetText("Erlernbar durch:")
    self.srcHeader = srcHeader

    -- Scrollable frame for sources to prevent overflow into Twink status
    local srcScrollFrame = CreateFrame("ScrollFrame", "RecipeRadarSourceScroll", attrBox)
    srcScrollFrame:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 6, attrY - 20)
    srcScrollFrame:SetPoint("BOTTOMRIGHT", attrBox, "BOTTOMRIGHT", -6, 6)
    srcScrollFrame:EnableMouse(true)
    srcScrollFrame:EnableMouseWheel(true)

    local srcScrollChild = CreateFrame("Frame", nil, srcScrollFrame)
    srcScrollChild:SetPoint("TOPLEFT", 0, 0)
    srcScrollChild:SetWidth(290)
    srcScrollChild:SetHeight(100)
    srcScrollFrame:SetScrollChild(srcScrollChild)
    self.srcScrollFrame = srcScrollFrame
    self.srcScrollChild = srcScrollChild

    local srcScrollBar = CreateFrame("Slider", "RecipeRadarSourceScrollBar", srcScrollFrame, "UIPanelScrollBarTemplate")
    srcScrollBar:SetPoint("TOPRIGHT", srcScrollFrame, "TOPRIGHT", -2, -16)
    srcScrollBar:SetPoint("BOTTOMRIGHT", srcScrollFrame, "BOTTOMRIGHT", -2, 16)
    srcScrollBar:SetWidth(14)
    srcScrollBar:SetMinMaxValues(0, 0)
    srcScrollBar:SetValue(0)
    srcScrollBar:SetValueStep(14)
    srcScrollBar:SetScript("OnValueChanged", function(sb, val)
        srcScrollFrame:SetVerticalScroll(val)
    end)
    srcScrollBar:Hide()
    self.srcScrollBar = srcScrollBar

    srcScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = srcScrollBar:GetValue()
        local minVal, maxVal = srcScrollBar:GetMinMaxValues()
        local target = cur - (delta * 24)
        if target < minVal then target = minVal end
        if target > maxVal then target = maxVal end
        srcScrollBar:SetValue(target)
    end)

    -- Interactive source rows pool inside srcScrollChild
    self.sourceRows = {}
    for i = 1, 30 do
        local row = CreateFrame("Button", nil, srcScrollChild)
        row:SetPoint("TOPLEFT", srcScrollChild, "TOPLEFT", 4, -(i - 1) * 16)
        row:SetPoint("RIGHT", srcScrollChild, "RIGHT", -18, 0)
        row:SetHeight(14)
        row:EnableMouse(true)

        local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetPoint("RIGHT", 0, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
        row.text = text

        row:SetScript("OnEnter", function(btn)
            if btn.waypoint then
                GameTooltip:SetOwner(btn, "ANCHOR_TOP")
                GameTooltip:AddLine(btn.waypoint.name or "Wegpunkt", 1, 0.82, 0)
                if btn.waypoint.zone and btn.waypoint.x and btn.waypoint.y then
                    GameTooltip:AddLine(string.format("%s (%.1f, %.1f)", btn.waypoint.zone, btn.waypoint.x, btn.waypoint.y), 1, 1, 1)
                end
                GameTooltip:AddLine("Klicken, um TomTom-Wegpunkt zu setzen", 0.2, 1, 0.2)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(btn)
            if btn.waypoint and RR.Utils and RR.Utils.AddTomTomWaypoint then
                local wp = btn.waypoint
                RR.Utils:AddTomTomWaypoint(wp.name, wp.zone, wp.x, wp.y)
            end
        end)

        row:Hide()
        table.insert(self.sourceRows, row)
    end

    -- Alt Character Knowledge Section
    local altsBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    altsBox:SetPoint("TOPLEFT", attrBox, "BOTTOMLEFT", 0, -6)
    altsBox:SetPoint("BOTTOMRIGHT", -6, 6)
    RR.UI.Theme:SkinPanel(altsBox, 0.7)
    local altsTitle = altsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    altsTitle:SetPoint("TOPLEFT", 6, -6)
    altsTitle:SetText(RR.COLORS.GOLD .. RR.L["ALTS_STATUS"])
    self.altsText = altsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.altsText:SetPoint("TOPLEFT", altsTitle, "BOTTOMLEFT", 0, -4)
    self.altsText:SetPoint("BOTTOMRIGHT", -6, 6)
    self.altsText:SetJustifyH("LEFT")
    self.altsText:SetJustifyV("TOP")

    -- 5. Footer Progress Bar
    local footer = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", 8, 6)
    footer:SetPoint("BOTTOMRIGHT", -8, 6)
    footer:SetHeight(24)
    RR.UI.Theme:SkinPanel(footer, 0.98)

    self.progressBar = CreateFrame("StatusBar", nil, footer, BackdropTemplateMixin and "BackdropTemplate")
    self.progressBar:SetAllPoints(footer)
    self.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.progressBar:SetStatusBarColor(0.12, 0.45, 0.20, 1)

    self.progressText = self.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.progressText:SetPoint("CENTER", 0, 0)
    self.progressText:SetText("Fehlend: 0 / 0")

    self:UpdateFilterButtons()
end

function RR.UI.MainWindow:IsShown()
    return (self.frame ~= nil and self.frame:IsShown() == true)
end

function RR.UI.MainWindow:Hide()
    if self.frame then self.frame:Hide() end
end

function RR.UI.MainWindow:Show()
    if not self.frame then self:Initialize() end
    self.frame:Show()
    self:Refresh()
end

function RR.UI.MainWindow:Toggle()
    if not self.frame then self:Initialize() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:Refresh()
    end
end

function RR.UI.MainWindow:UpdateFilterButtons()
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

function RR.UI.MainWindow:Refresh()
    if not self.frame or not self.frame:IsShown() then return end

    local prof = RR.Scanner.currentProfession or "Tailoring"
    local rawRecipes = RR.DB:GetRecipesForProfession(prof)
    
    -- Update Title Banner Plaque with profession name
    local locProfName = prof
    local spellId = RR.DB:GetEnglishProfessionName(prof)
    if self.titlePlaque and self.titlePlaque.SetTitle then
        self.titlePlaque:SetTitle(RR.NAME .. " - " .. locProfName)
    end

    local filtered, counts = RR.Filter:ApplyFilters(rawRecipes, prof, self.searchQuery)
    self.currentList = filtered

    -- Update Progress Bar (Matching MTSL: Fehlend: X / Y)
    local curMode = RR.Config:GetFilterSetting("mode") or "missing"
    self.progressBar:SetMinMaxValues(0, counts.total)
    if curMode == "known" then
        self.progressBar:SetValue(counts.known)
        self.progressText:SetText(string.format("Gelernt: %d / %d", counts.known, counts.total))
    else
        self.progressBar:SetValue(counts.missing)
        self.progressText:SetText(string.format("Fehlend: %d / %d", counts.missing, counts.total))
    end

    -- Update Scrollbar
    local maxScroll = math.max(0, #filtered - NUM_VISIBLE_ROWS)
    self.scrollbar:SetMinMaxValues(0, maxScroll)
    if self.scrollOffset > maxScroll then self.scrollOffset = maxScroll end

    self:RenderList()

    if #filtered > 0 then
        local needReselect = true
        if self.selectedRecipe then
            for _, item in ipairs(filtered) do
                if item.id == self.selectedRecipe.id then
                    needReselect = false
                    break
                end
            end
        end
        if needReselect then
            self:SelectRecipe(filtered[1])
        end
    end
end

function RR.UI.MainWindow:RenderList()
    local filtered = self.currentList or {}
    local offset = self.scrollOffset or 0

    local iconMap = {
        trainer = "Interface\\Icons\\INV_Misc_Book_09",
        vendor  = "Interface\\Icons\\INV_Misc_Coin_01",
        drop    = "Interface\\GossipFrame\\VendorGossipIcon",
        quest   = "Interface\\GossipFrame\\AvailableQuestIcon",
        holiday = "Interface\\Icons\\INV_Misc_Gift_01",
        object  = "Interface\\Icons\\INV_Box_01",
    }

    for i = 1, NUM_VISIBLE_ROWS do
        local row = self.rows[i]
        local dataIndex = offset + i

        if dataIndex <= #filtered then
            local item = filtered[dataIndex]
            row.recipeData = item
            local rData = item.data or {}

            -- Skill bracket colored + Name
            local skillColor = "|cff00ff00" -- Green
            if not item.isKnown then skillColor = "|cff44ff44" end
            row.text:SetText(string.format("%s[%d]|r %s", skillColor, item.skillReq or 1, item.name))

            if item.isKnown then
                row.text:SetTextColor(0.18, 0.83, 0.75, 1) -- Cyan / Turquoise
            else
                row.text:SetTextColor(0.95, 0.95, 0.95, 1)
            end

            -- Get comprehensive acquisition metadata
            local meta = RR.DB:GetRecipeAcquisitionMetadata(rData)

            local sources = {}
            local sourceLabels = {}
            if meta.sourceTypes["vendor"] then
                table.insert(sources, "vendor")
                table.insert(sourceLabels, "Verkäufer")
            end
            if meta.sourceTypes["drop"] then
                table.insert(sources, "drop")
                table.insert(sourceLabels, "Drop")
            end
            if meta.sourceTypes["quest"] then
                table.insert(sources, "quest")
                table.insert(sourceLabels, "Quest")
            end
            if meta.sourceTypes["trainer"] then
                table.insert(sources, "trainer")
                table.insert(sourceLabels, "Lehrer")
            end
            if meta.sourceTypes["holiday"] then
                table.insert(sources, "holiday")
                table.insert(sourceLabels, "Weltereignis")
            end
            if meta.sourceTypes["object"] then
                table.insert(sources, "object")
                table.insert(sourceLabels, "Objekt")
            end

            if #sources == 0 then
                table.insert(sources, "trainer")
                table.insert(sourceLabels, "Lehrer")
            end

            -- Faction restriction & placement
            local hasAlliance = meta.factions["Alliance"]
            local hasHorde = meta.factions["Horde"]
            local factionText = "Alle Fraktionen"
            local factionColor = "|cffffff00"

            if hasAlliance and not hasHorde then
                factionText = "Nur Allianz"
                factionColor = "|cff0070dd"
                row.iconFaction:SetTexture(RR.ADDON_PATH .. "\\images\\alliance.tga")
                row.iconFaction:Show()
            elseif hasHorde and not hasAlliance then
                factionText = "Nur Horde"
                factionColor = "|cffff2020"
                row.iconFaction:SetTexture(RR.ADDON_PATH .. "\\images\\horde.tga")
                row.iconFaction:Show()
            else
                row.iconFaction:Hide()
            end

            -- Render Source Icons flush on the right
            if sources[1] and iconMap[sources[1]] then
                row.iconSource1:SetTexture(iconMap[sources[1]])
                row.iconSource1:Show()
            else
                row.iconSource1:Hide()
            end

            if sources[2] and iconMap[sources[2]] then
                row.iconSource2:SetTexture(iconMap[sources[2]])
                row.iconSource2:Show()
            else
                row.iconSource2:Hide()
            end

            if sources[3] and iconMap[sources[3]] then
                row.iconSource3:SetTexture(iconMap[sources[3]])
                row.iconSource3:Show()
            else
                row.iconSource3:Hide()
            end

            -- Text padding
            row.text:SetPoint("RIGHT", row, "RIGHT", -68, 0)

            row.sourceTooltipSources = table.concat(sourceLabels, ", ")
            row.sourceTooltipFaction = factionColor .. factionText .. "|r"

            -- Selected highlight
            if self.selectedRecipe and self.selectedRecipe.id == item.id then
                row.selected_bg:Show()
            else
                row.selected_bg:Hide()
            end

            row:Show()
        else
            row.recipeData = nil
            row.selected_bg:Hide()
            row.iconSource1:Hide(); row.iconSource2:Hide(); row.iconSource3:Hide(); row.iconFaction:Hide()
            row:Hide()
        end
    end
end

function RR.UI.MainWindow:SelectRecipe(recipeItem)
    if not recipeItem then return end
    self.selectedRecipe = recipeItem
    local data = recipeItem.data or {}
    local locale = GetLocale()
    local meta = RR.DB:GetRecipeAcquisitionMetadata(data)

    local labels = "Name\nPhase\nMin. Fertigkeitsstufe\nBenötigt XP Level\nBenötigt Ruf\nSpezialisierung\nFeiertag\nSonderaktion\nKosten\nErlernbar durch"
    
    local rName = recipeItem.name or "-"
    local phaseNum = tonumber(meta.phase or data.phase or 1)
    local rPhase = RR.L["PHASE_" .. (phaseNum or 1)] or string.format("Phase %d", phaseNum or 1)
    local rSkill = tostring(recipeItem.skillReq or 1)
    
    local rRep = "-"
    local repFactionId = meta.reputationFactionId or (data.reputation and data.reputation.faction_id)
    local repLvlId = meta.reputationLevel or (data.reputation and data.reputation.level)
    if repFactionId then
        local fName = RR.DB:GetFactionName(repFactionId)
        local lvlName = repLvlId and RR.DB:GetReputationLevelName(repLvlId)
        if fName and lvlName then
            rRep = string.format("%s (%s)", fName, lvlName)
        elseif fName then
            rRep = fName
        else
            rRep = tostring(repFactionId)
        end
    end

    local prof = RR.Scanner.currentProfession or "Tailoring"
    local rSpec = "-"
    if data.specialisation then
        local specName = nil
        if RR_DATA and RR_DATA["specialisations"] and RR_DATA["specialisations"][prof] then
            for _, sp in ipairs(RR_DATA["specialisations"][prof]) do
                if sp.id == data.specialisation or sp.name == data.specialisation then
                    specName = RR.DB:GetLocalizedText(sp.name)
                    break
                end
            end
        end
        rSpec = specName or tostring(data.specialisation)
    end

    local rHol = "-"
    if data.holiday then
        local holName = nil
        if RR_DATA and RR_DATA["holidays"] then
            for _, h in ipairs(RR_DATA["holidays"]) do
                if h.id == data.holiday then
                    holName = RR.DB:GetLocalizedText(h.name)
                    break
                end
            end
        end
        rHol = holName or tostring(data.holiday)
    end

    local rPrice = "-"
    local priceVal = tonumber(meta.price or data.price)
    if priceVal and priceVal > 0 then
        rPrice = (RR.Utils and RR.Utils.FormatMoney and RR.Utils:FormatMoney(priceVal)) or tostring(priceVal)
    elseif priceVal == 0 then
        rPrice = RR.L["FREE"] or "Kostenlos"
    end
    local rLearnedFrom = "-"

    self.selectedRecipe.waypoint = nil

    local playerFaction = UnitFactionGroup("player") or "Alliance"

    local ALLIANCE_ZONES = {
        [1519] = true, -- Stormwind
        [1537] = true, -- Ironforge
        [1657] = true, -- Darnassus
        [12]   = true, -- Elwynn Forest
        [1]    = true, -- Dun Morogh
        [141]  = true, -- Teldrassil
        [40]   = true, -- Westfall
        [38]   = true, -- Loch Modan
        [148]  = true, -- Darkshore
        [44]   = true, -- Redridge Mountains
        [10]   = true, -- Duskwood
        [11]   = true, -- Wetlands
    }

    local HORDE_ZONES = {
        [1637] = true, -- Orgrimmar
        [1638] = true, -- Thunder Bluff
        [1497] = true, -- Undercity
        [14]   = true, -- Durotar
        [215]  = true, -- Mulgore
        [85]   = true, -- Tirisfal Glades
        [17]   = true, -- The Barrens
        [130]  = true, -- Silverpine Forest
    }

    local function resolveNPC(npcId)
        local npc = RR.DB:GetNPC(npcId)
        if not npc then return nil end
        local nName = (type(npc.name) == "table" and (npc.name[locale] or npc.name["German"] or npc.name["English"])) or npc.name or "NPC"
        local zId = (npc.location and npc.location.zone_id) or npc.zone_id
        local zName = RR.DB:GetZoneName(zId)
        local nx = tonumber(npc.location and npc.location.x or npc.x)
        local ny = tonumber(npc.location and npc.location.y or npc.y)

        local reacts = npc.reacts
        local effectiveFaction = "Neutral"

        if reacts then
            if type(reacts) == "table" then
                local hasA = false
                local hasH = false
                for _, r in ipairs(reacts) do
                    if r == "Alliance" then hasA = true end
                    if r == "Horde" then hasH = true end
                end
                if hasA and not hasH then effectiveFaction = "Alliance"
                elseif hasH and not hasA then effectiveFaction = "Horde"
                end
            elseif reacts == "Alliance" then
                effectiveFaction = "Alliance"
            elseif reacts == "Horde" then
                effectiveFaction = "Horde"
            end
        end

        -- If faction is neutral or multi-faction, resolve territory via city/zone!
        if effectiveFaction == "Neutral" and zId then
            if ALLIANCE_ZONES[zId] then
                effectiveFaction = "Alliance"
            elseif HORDE_ZONES[zId] then
                effectiveFaction = "Horde"
            end
        end

        local isFactionMatch = (effectiveFaction == playerFaction or effectiveFaction == "Neutral")
        local isOtherFaction = (effectiveFaction ~= playerFaction and effectiveFaction ~= "Neutral")

        return nName, zName, nx, ny, isFactionMatch, isOtherFaction, effectiveFaction
    end

    local function formatNPC(nName, zName, nx, ny, suffix)
        if nx and ny and nx > 0 and ny > 0 then
            return string.format("%s (%s) - %s (%.1f, %.1f)", nName, suffix, zName, nx, ny), { name = nName, zone = zName, x = nx, y = ny }
        else
            return string.format("%s (%s) - %s", nName, suffix, zName), (nx and ny and { name = nName, zone = zName, x = nx, y = ny } or nil)
        end
    end

    local trainerSources = data.trainers and (data.trainers.sources or (type(data.trainers) == "table" and data.trainers))
    local vendorSources = data.vendors and (data.vendors.sources or (type(data.vendors) == "table" and data.vendors))
    local questSources = data.quests and (data.quests.sources or (type(data.quests) == "table" and data.quests))
    local dropSources = data.drops and (data.drops.sources or (type(data.drops) == "table" and data.drops))

    if data.items and type(data.items) == "table" then
        for _, itemId in ipairs(data.items) do
            local itm = RR.DB:GetItem(itemId)
            if itm then
                if itm.vendors then vendorSources = itm.vendors.sources or itm.vendors end
                if itm.quests then questSources = itm.quests.sources or itm.quests end
                if itm.drops then dropSources = itm.drops.sources or itm.drops end
                if itm.price then rPrice = RR.Utils:FormatMoney(itm.price) end
            end
        end
    end

    if data.trainers and data.trainers.price then
        rPrice = RR.Utils:FormatMoney(data.trainers.price)
    elseif data.vendors and data.vendors.price then
        rPrice = RR.Utils:FormatMoney(data.vendors.price)
    end

    -- Collect ALL possible sources for detailed display
    local allSources = {}
    local seenSources = {}

    -- 1. Vendors
    if vendorSources and type(vendorSources) == "table" then
        for _, id in ipairs(vendorSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, "Händler")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction,
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    -- 2. Trainers
    if trainerSources and type(trainerSources) == "table" then
        for _, id in ipairs(trainerSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, "Lehrer")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction,
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    -- 3. Quests
    if questSources and type(questSources) == "table" then
        for _, qId in ipairs(questSources) do
            local q = RR.DB:GetQuest(qId)
            if q then
                local qName = (type(q.name) == "table" and (q.name[locale] or q.name["German"] or q.name["English"])) or "Quest"
                local qzId = q.zone_id
                local qx, qy, qNpcName
                local qNpcReacts = nil
                if q.npcs and q.npcs[1] then
                    local npc = RR.DB:GetNPC(q.npcs[1])
                    if npc then
                        if not qzId then qzId = (npc.location and npc.location.zone_id) or npc.zone_id end
                        if not qx then qx = tonumber(npc.location and npc.location.x or npc.x) end
                        if not qy then qy = tonumber(npc.location and npc.location.y or npc.y) end
                        if not qNpcName then qNpcName = (type(npc.name) == "table" and (npc.name[locale] or npc.name["German"] or npc.name["English"])) or npc.name end
                        qNpcReacts = npc.reacts or npc.faction
                    end
                end
                if q.givers and q.givers.npcs and q.givers.npcs[1] then
                    local npc = RR.DB:GetNPC(q.givers.npcs[1])
                    if npc then
                        if not qzId then qzId = (npc.location and npc.location.zone_id) or npc.zone_id end
                        if not qx then qx = tonumber(npc.location and npc.location.x or npc.x) end
                        if not qy then qy = tonumber(npc.location and npc.location.y or npc.y) end
                        if not qNpcName then qNpcName = (type(npc.name) == "table" and (npc.name[locale] or npc.name["German"] or npc.name["English"])) or npc.name end
                        if not qNpcReacts then qNpcReacts = npc.reacts or npc.faction end
                    end
                end

                local zName = qzId and RR.DB:GetZoneName(qzId)
                local lineText
                local wp = nil
                if zName and zName ~= "Unknown Zone" and zName ~= "" then
                    if qx and qy and qx > 0 and qy > 0 then
                        lineText = string.format("%s (Quest) - %s (%.1f, %.1f)", qName, zName, qx, qy)
                        wp = { name = qNpcName or qName, zone = zName, x = qx, y = qy }
                    else
                        lineText = string.format("%s (Quest) - %s", qName, zName)
                    end
                else
                    lineText = string.format("%s (Quest)", qName)
                end

                local qFaction = nil
                if q.reacts then
                    if type(q.reacts) == "table" then qFaction = q.reacts[1]
                    elseif type(q.reacts) == "string" then qFaction = q.reacts
                    end
                end
                if not qFaction and qNpcReacts then
                    if type(qNpcReacts) == "table" then qFaction = qNpcReacts[1]
                    elseif type(qNpcReacts) == "string" then qFaction = qNpcReacts
                    end
                end
                if not qFaction then qFaction = "Neutral" end
                local isMatch = (qFaction == playerFaction or qFaction == "Neutral")
                local isOther = (qFaction ~= playerFaction and qFaction ~= "Neutral")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = qFaction,
                    isPlayerFaction = isMatch,
                    isOtherFaction = isOther,
                })
            end
        end
    end

    -- 3b. Objects (z. B. Spektraler Kelch, Schrifttafel des Wahnsinns, Buch auf dem Boden)
    local objectSources = meta.objects or data.objects
    if objectSources and type(objectSources) == "table" then
        for _, objId in ipairs(objectSources) do
            local obj = RR.DB:GetObject(objId)
            if obj and not seenSources["obj_" .. objId] then
                seenSources["obj_" .. objId] = true
                local oName = (type(obj.name) == "table" and (obj.name[locale] or obj.name["German"] or obj.name["English"])) or obj.name or "Objekt"
                local zId = (obj.location and obj.location.zone_id) or obj.zone_id
                local zName = zId and RR.DB:GetZoneName(zId)
                local ox = tonumber(obj.location and obj.location.x or obj.x)
                local oy = tonumber(obj.location and obj.location.y or obj.y)
                local lineText, wp = formatNPC(oName, zName, ox, oy, "Objekt")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = "Neutral",
                    isPlayerFaction = true,
                })
            end
        end
    end

    -- 4. Drops
    if dropSources and type(dropSources) == "table" then
        for _, id in ipairs(dropSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, "Beute")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction or "Neutral",
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    if meta.dropRange then
        table.insert(allSources, {
            text = string.format("Gegner-Beute (Stufe %d-%d)", meta.dropRange.min_xp_level or 1, meta.dropRange.max_xp_level or 60),
            waypoint = nil,
            isPlayerFaction = true,
        })
    end

    -- 5. Special Actions (z. B. Buch auf dem Boden in Scholomance, Schrifttafel in ZG, Gedankenkontrolle in BWL)
    local specActionKey = data.special_action or meta.special_action
    if specActionKey then
        local saText = RR.DB:GetSpecialActionText(specActionKey)
        if saText then
            table.insert(allSources, {
                text = string.format("Hinweis: %s", saText),
                waypoint = nil,
                faction = "Neutral",
                isPlayerFaction = true,
            })
        end
    end

    -- Sort sources: player's faction first, then others!
    table.sort(allSources, function(a, b)
        if a.isPlayerFaction and not b.isPlayerFaction then return true end
        if not a.isPlayerFaction and b.isPlayerFaction then return false end
        return false
    end)

    local attrVals = {
        rName,
        rPhase,
        rSkill,
        rRep,
        rSpec,
        rHol,
        rPrice,
    }
    if self.attrRows then
        for i, rowF in ipairs(self.attrRows) do
            if attrVals[i] then
                rowF.value:SetText(attrVals[i])
            end
        end
    end

    -- Reset source scroll position to top
    if self.srcScrollBar then
        self.srcScrollBar:SetValue(0)
    end
    if self.srcScrollFrame then
        self.srcScrollFrame:SetVerticalScroll(0)
    end

    -- Populate interactive source rows inside srcScrollChild
    local curY = 0
    if self.sourceRows and self.srcScrollChild then
        local childWidth = (self.srcScrollFrame and self.srcScrollFrame:GetWidth() or 300) - 22
        if childWidth > 50 then
            self.srcScrollChild:SetWidth(childWidth)
        end

        for i, row in ipairs(self.sourceRows) do
            local src = allSources[i]
            if src then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.srcScrollChild, "TOPLEFT", 4, -curY)
                row:SetPoint("RIGHT", self.srcScrollChild, "RIGHT", -4, 0)

                local factionIcon = ""
                if src.faction == "Alliance" then
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\alliance.tga:13:13:0:0|t "
                elseif src.faction == "Horde" then
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\horde.tga:13:13:0:0|t "
                else
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\neutral.tga:13:13:0:0|t "
                end

                row.text:SetText("• " .. factionIcon .. src.text)
                if src.isOtherFaction then
                    row.text:SetTextColor(0.65, 0.65, 0.65)
                else
                    row.text:SetTextColor(1, 1, 1)
                end
                row.waypoint = src.waypoint
                row:Show()

                -- Calculate exact text height
                local textHeight = math.max(14, math.ceil(row.text:GetStringHeight()) + 2)
                row:SetHeight(textHeight)
                curY = curY + textHeight + 2
            else
                row:Hide()
            end
        end

        local frameHeight = self.srcScrollFrame and self.srcScrollFrame:GetHeight() or 110
        self.srcScrollChild:SetHeight(math.max(frameHeight, curY + 6))

        if curY > (frameHeight - 4) then
            local maxScroll = curY - frameHeight + 12
            self.srcScrollBar:SetMinMaxValues(0, maxScroll)
            self.srcScrollBar:Show()
        else
            self.srcScrollBar:SetMinMaxValues(0, 0)
            self.srcScrollBar:Hide()
        end
    end

    -- Alt knowledge status
    local alts = RR.AltTracker:GetAltStatusForRecipe(RR.Scanner.currentProfession, recipeItem.id, recipeItem.name)
    local altsStr = ""
    for _, alt in ipairs(alts) do
        local statusStr = alt.isKnown and (RR.COLORS.GREEN .. "✓ " .. RR.L["LEARNED"]) or (RR.COLORS.RED .. "✗ " .. RR.L["MODE_MISSING"])
        altsStr = altsStr .. string.format("%s (%s): %s\n", alt.name, alt.class, statusStr)
    end
    self.altsText:SetText(altsStr ~= "" and altsStr or (RR.COLORS.GREY .. RR.L["NO_ALTS_REALM"]))

    -- Update Detail Faction Crest
    if self.detailFactionIcon then
        local hasAlliance = meta.factions["Alliance"]
        local hasHorde = meta.factions["Horde"]
        if hasAlliance and not hasHorde then
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\alliance.tga")
            self.detailFactionIcon:Show()
        elseif hasHorde and not hasAlliance then
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\horde.tga")
            self.detailFactionIcon:Show()
        else
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\neutral.tga")
            self.detailFactionIcon:Show()
        end
    end

    -- Re-render list to highlight selected row
    self:RenderList()
end

-- Custom Dark Dropdown Popup Frame
local dropdownPopup = nil

function RR.UI.MainWindow:ShowDropdown(anchorBtn, items)
    if not dropdownPopup then
        dropdownPopup = CreateFrame("Frame", "RecipeRadarCustomDropdown", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        dropdownPopup:SetFrameStrata("TOOLTIP")
        dropdownPopup:SetClampedToScreen(true)
        RR.UI.Theme:SkinWindow(dropdownPopup)
        dropdownPopup.buttons = {}

        -- ScrollFrame container
        local scrollFrame = CreateFrame("ScrollFrame", "RecipeRadarDropdownScroll", dropdownPopup)
        scrollFrame:SetPoint("TOPLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        dropdownPopup.scrollFrame = scrollFrame

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(100, 100)
        scrollFrame:SetScrollChild(scrollChild)
        dropdownPopup.scrollChild = scrollChild

        -- ScrollBar slider
        local scrollBar = CreateFrame("Slider", "RecipeRadarDropdownScrollBar", dropdownPopup, BackdropTemplateMixin and "BackdropTemplate")
        scrollBar:SetWidth(10)
        scrollBar:SetPoint("TOPRIGHT", -4, -4)
        scrollBar:SetPoint("BOTTOMRIGHT", -4, 4)
        RR.UI.Theme:SkinPanel(scrollBar, 0.8)
        scrollBar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
        scrollBar:SetOrientation("VERTICAL")
        scrollBar:SetMinMaxValues(0, 100)
        scrollBar:SetValue(0)
        scrollBar:SetValueStep(22)
        scrollBar:SetScript("OnValueChanged", function(selfSB, val)
            scrollFrame:SetVerticalScroll(val)
        end)
        dropdownPopup.scrollBar = scrollBar

        local function onMouseWheel(selfF, delta)
        dropdownPopup.onMouseWheel = onMouseWheel
            local current = scrollBar:GetValue() or 0
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            local step = 22 * 2
            if delta < 0 then
                scrollBar:SetValue(math.min(maxVal, current + step))
            else
                scrollBar:SetValue(math.max(minVal, current - step))
            end
        end

        dropdownPopup:EnableMouseWheel(true)
        dropdownPopup:SetScript("OnMouseWheel", onMouseWheel)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", onMouseWheel)

        local clickWatcher = CreateFrame("Frame", nil, dropdownPopup)
        clickWatcher:SetScript("OnUpdate", function()
            if dropdownPopup:IsShown() and not dropdownPopup:IsMouseOver() and (not dropdownPopup.currentAnchor or not dropdownPopup.currentAnchor:IsMouseOver()) then
                if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                    dropdownPopup:Hide()
                end
            end
        end)
    end

    if dropdownPopup:IsShown() and dropdownPopup.currentAnchor == anchorBtn then
        dropdownPopup:Hide()
        return
    end

    dropdownPopup.currentAnchor = anchorBtn
    dropdownPopup:ClearAllPoints()
    dropdownPopup:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)

    local maxWidth = (anchorBtn:GetWidth() or 120) + 20
    local itemHeight = 22
    local count = #items
    local maxVisible = 14
    local visibleCount = math.min(count, maxVisible)
    local totalContentHeight = count * itemHeight
    local viewHeight = visibleCount * itemHeight
    local needsScroll = count > maxVisible

    for i, itm in ipairs(items) do
        local btn = dropdownPopup.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dropdownPopup.scrollChild, BackdropTemplateMixin and "BackdropTemplate")
            btn:SetHeight(itemHeight)
            RR.UI.Theme:SkinPanel(btn, 0.6)

            btn.icon = btn:CreateTexture(nil, "OVERLAY")
            btn.icon:SetSize(16, 16)
            btn.icon:SetPoint("LEFT", 6, 0)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("LEFT", 26, 0)

            btn.check = btn:CreateTexture(nil, "OVERLAY")
            btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            btn.check:SetSize(16, 16)
            btn.check:SetPoint("RIGHT", -4, 0)

            btn:SetScript("OnEnter", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.25, 0.28, 0.35, 1) end
            end)
            btn:SetScript("OnLeave", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.04, 0.05, 0.06, 0.6) end
            end)
            btn:EnableMouseWheel(true)
            btn:SetScript("OnMouseWheel", function(selfB, delta)
                if dropdownPopup and dropdownPopup.onMouseWheel then
                    dropdownPopup.onMouseWheel(selfB, delta)
                end
            end)

            dropdownPopup.buttons[i] = btn
        end

        btn.text:SetText(itm.text)

        if itm.icon then
            btn.icon:SetTexture(itm.icon)
            btn.icon:Show()
            btn.text:SetPoint("LEFT", 26, 0)
        else
            btn.icon:Hide()
            btn.text:SetPoint("LEFT", 8, 0)
        end

        local strWidth = (btn.text:GetStringWidth() or 80) + 50
        if strWidth > maxWidth then maxWidth = strWidth end

        if itm.checked then
            btn.check:Show()
            btn.text:SetTextColor(1, 0.82, 0, 1)
        else
            btn.check:Hide()
            btn.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end

        btn:SetScript("OnClick", function()
            dropdownPopup:Hide()
            if itm.func then itm.func() end
        end)
        btn:Show()
    end

    for i = count + 1, #dropdownPopup.buttons do
        dropdownPopup.buttons[i]:Hide()
    end

    -- Update scroll child width and button widths
    local childWidth = maxWidth
    dropdownPopup.scrollChild:SetSize(childWidth, totalContentHeight)
    for i = 1, count do
        local btn = dropdownPopup.buttons[i]
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", dropdownPopup.scrollChild, "TOPLEFT", 0, -((i - 1) * itemHeight))
        btn:SetSize(childWidth, itemHeight)
    end

    dropdownPopup.scrollFrame:ClearAllPoints()
    if needsScroll then
        dropdownPopup.scrollFrame:SetPoint("TOPLEFT", 4, -4)
        dropdownPopup.scrollFrame:SetPoint("BOTTOMRIGHT", -16, 4)
        dropdownPopup.scrollBar:Show()
        local maxScroll = math.max(0, totalContentHeight - viewHeight)
        dropdownPopup.scrollBar:SetMinMaxValues(0, maxScroll)
        dropdownPopup.scrollBar:SetValue(0)
    else
        dropdownPopup.scrollFrame:SetPoint("TOPLEFT", 4, -4)
        dropdownPopup.scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        dropdownPopup.scrollBar:Hide()
        dropdownPopup.scrollFrame:SetVerticalScroll(0)
    end

    local finalPopupWidth = maxWidth + (needsScroll and 20 or 8)
    local finalPopupHeight = viewHeight + 8

    dropdownPopup:SetSize(finalPopupWidth, finalPopupHeight)
    dropdownPopup:Show()
end