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

    -- ROW 2: Quelle: [ Quelle (6/6) v ] [ Fraktion v ] [ Spezialisierung v ] [ Phase v ]
    local sourceLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", 8, -40)
    sourceLabel:SetTextColor(1, 0.82, 0, 1)
    sourceLabel:SetText("Quelle:")

    local sourceMenu = {
        { text = "Alle Quellen", value = "any" },
        { text = "Lehrer", value = "trainer" },
        { text = "Händler", value = "vendor" },
        { text = "Quest", value = "quest" },
        { text = "Gegner-Beute (Drop)", value = "drop" },
        { text = "Weltereignis", value = "holiday" },
        { text = "Ruf", value = "reputation" },
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

    local factionMenu = {
        { text = "Alle Fraktionen", value = "any" },
        { text = "Allianz", value = "Alliance" },
        { text = "Horde", value = "Horde" },
        { text = "Neutral", value = "Neutral" },
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

    self.specBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 135, "Spezialisierung", function(selfF)
        local menu = {
            { text = "Alle Spezialisierungen", value = "any" },
        }
        self:ShowDropdown(selfF, menu)
    end)
    self.specBtn:SetPoint("LEFT", self.factionBtn, "RIGHT", 8, 0)

    local phaseMenu = {
        { text = "Alle Phasen", value = 0 },
        { text = "Phase 1", value = 1 },
        { text = "Phase 2", value = 2 },
        { text = "Phase 3", value = 3 },
        { text = "Phase 4", value = 4 },
        { text = "Phase 5", value = 5 },
        { text = "Phase 6", value = 6 },
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

    -- ROW 3: Zone: [ Jede Zone v ] [ Zone v ] [ Jede Zone ] [ Aktuelle Zone ] [ <ZoneName> ]
    local zoneLabel = filterArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("TOPLEFT", 8, -72)
    zoneLabel:SetTextColor(1, 0.82, 0, 1)
    zoneLabel:SetText("Zone:")

    self.continentBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, "Jede Zone", function(selfF)
        local contMenu = {
            { text = "Jede Zone", value = "any" },
            { text = "Kalimdor", value = "kalimdor" },
            { text = "Östliche Königreiche", value = "eastern_kingdoms" },
            { text = "Instanzen & Schlachtzüge", value = "dungeons" },
        }
        local menu = {}
        for _, itm in ipairs(contMenu) do
            table.insert(menu, {
                text = itm.text,
                func = function()
                    RR.Config:SetFilterSetting("zoneFilter", itm.value)
                    selfF.text:SetText(itm.text)
                    self:Refresh()
                end,
                checked = (RR.Config:GetFilterSetting("zoneFilter") or "any") == itm.value,
            })
        end
        self:ShowDropdown(selfF, menu)
    end)
    self.continentBtn:SetPoint("LEFT", zoneLabel, "RIGHT", 14, 0)

    self.zoneDropBtn = RR.UI.Theme:CreateDropDownFrame(filterArea, 120, "Zone", function(selfF)
        local menu = {
            { text = "Alle Zonen", value = "any" },
        }
        self:ShowDropdown(selfF, menu)
    end)
    self.zoneDropBtn:SetPoint("LEFT", self.continentBtn, "RIGHT", 8, 0)

    -- Quick Zone Buttons
    self.zoneBtns = {}
    local curZName = GetRealZoneText() or "Aktuelle Zone"
    local quickZones = {
        { key = "any", label = "Jede Zone", width = 80 },
        { key = "current", label = "Aktuelle Zone", width = 95 },
        { key = "current_name", label = curZName, width = 110 },
    }
    local prevZBtn = nil
    for _, zDef in ipairs(quickZones) do
        local zBtn = RR.UI.Theme:CreateDarkButton(filterArea, zDef.label, zDef.width, 24)
        if prevZBtn then
            zBtn:SetPoint("LEFT", prevZBtn, "RIGHT", 5, 0)
        else
            zBtn:SetPoint("LEFT", self.zoneDropBtn, "RIGHT", 10, 0)
        end
        zBtn:SetScript("OnClick", function()
            local zKey = (zDef.key == "current_name") and "current" or zDef.key
            RR.Config:SetFilterSetting("zoneFilter", zKey)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        self.zoneBtns[zDef.key] = zBtn
        prevZBtn = zBtn
    end

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

        -- Up to 3 source icons on the right
        row.sourceIcons = {}
        for iconIdx = 1, 3 do
            local ic = row:CreateTexture(nil, "OVERLAY")
            ic:SetSize(14, 14)
            if iconIdx == 1 then
                ic:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            else
                ic:SetPoint("RIGHT", row.sourceIcons[iconIdx - 1], "LEFT", -2, 0)
            end
            ic:Hide()
            row.sourceIcons[iconIdx] = ic
        end

        -- Hover Tooltip for source types (e.g. "Verkäufer, Drop")
        row:SetScript("OnEnter", function(selfR)
            if selfR.sourceTooltipText and selfR.sourceTooltipText ~= "" then
                GameTooltip:SetOwner(selfR, "ANCHOR_RIGHT")
                GameTooltip:SetText(selfR.sourceTooltipText, 1, 1, 1)
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

    self.detailLabels = attrBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.detailLabels:SetPoint("TOPLEFT", 8, -8)
    self.detailLabels:SetJustifyH("LEFT")
    self.detailLabels:SetJustifyV("TOP")
    self.detailLabels:SetTextColor(1, 0.82, 0, 1)
    self.detailLabels:SetText("Name\nPhase\nMin. Fertigkeitsstufe\nBenötigt XP Level\nBenötigt Ruf\nSpezialisierung\nFeiertag\nSonderaktion\nKosten\nErlernbar durch")

    self.detailValues = attrBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailValues:SetPoint("TOPLEFT", 140, -8)
    self.detailValues:SetPoint("RIGHT", -8, 0)
    self.detailValues:SetJustifyH("LEFT")
    self.detailValues:SetJustifyV("TOP")
    self.detailValues:SetTextColor(1, 1, 1, 1)
    self.detailValues:SetText("-\n-\n-\n-\n-\n-\n-\n-\n-\n-")

    local tomtomBtn = RR.UI.Theme:CreateDarkButton(attrBox, "📌 TomTom Wegpunkt", 150, 22)
    tomtomBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    tomtomBtn:SetScript("OnClick", function()
        if self.selectedRecipe and self.selectedRecipe.waypoint then
            local wp = self.selectedRecipe.waypoint
            RR.Utils:AddTomTomWaypoint(wp.name, wp.zone, wp.x, wp.y)
        end
    end)

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

    if #filtered > 0 and not self.selectedRecipe then
        self:SelectRecipe(filtered[1])
    end
end

function RR.UI.MainWindow:RenderList()
    local filtered = self.currentList or {}
    local offset = self.scrollOffset or 0

    local iconMap = {
        trainer = "Interface\\Icons\\INV_Misc_Book_09",
        vendor  = "Interface\\Icons\\INV_Misc_Bag_08",
        drop    = "Interface\\Icons\\INV_Scroll_03",
        quest   = "Interface\\GossipFrame\\AvailableQuestIcon",
        holiday = "Interface\\Icons\\INV_Misc_Gift_01",
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

            -- Resolve source icons & tooltip
            local sources = {}
            local sourceLabels = {}
            if rData.trainers then
                table.insert(sources, "trainer")
                table.insert(sourceLabels, "Lehrer")
            end
            if rData.vendors then
                table.insert(sources, "vendor")
                table.insert(sourceLabels, "Verkäufer")
            end
            if rData.quests then
                table.insert(sources, "quest")
                table.insert(sourceLabels, "Quest")
            end
            if rData.drops then
                table.insert(sources, "drop")
                table.insert(sourceLabels, "Drop")
            end
            if rData.holiday then
                table.insert(sources, "holiday")
                table.insert(sourceLabels, "Weltereignis")
            end

            if #sources == 0 then
                table.insert(sources, "trainer")
                table.insert(sourceLabels, "Lehrer")
            end

            -- Display up to 3 icons
            for iconIdx = 1, 3 do
                local sKey = sources[iconIdx]
                if sKey and iconMap[sKey] then
                    row.sourceIcons[iconIdx]:SetTexture(iconMap[sKey])
                    row.sourceIcons[iconIdx]:Show()
                else
                    row.sourceIcons[iconIdx]:Hide()
                end
            end

            -- Adjust text padding based on visible icons
            local reserved = (#sources > 0) and ((#sources * 16) + 8) or 8
            row.text:SetPoint("RIGHT", row, "RIGHT", -reserved, 0)

            row.sourceTooltipText = table.concat(sourceLabels, ", ")

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
            for iconIdx = 1, 3 do row.sourceIcons[iconIdx]:Hide() end
            row:Hide()
        end
    end
end

function RR.UI.MainWindow:SelectRecipe(recipeItem)
    if not recipeItem then return end
    self.selectedRecipe = recipeItem
    local data = recipeItem.data or {}
    local locale = GetLocale()

    local labels = "Name\nPhase\nMin. Fertigkeitsstufe\nBenötigt XP Level\nBenötigt Ruf\nSpezialisierung\nFeiertag\nSonderaktion\nKosten\nErlernbar durch"
    
    local rName = recipeItem.name or "-"
    local rPhase = tostring(data.phase or 1)
    local rSkill = tostring(recipeItem.skillReq or 1)
    local rXp = tostring(data.min_xp_level or "-")
    local rRep = "-"
    if data.reputation then
        rRep = tostring(data.reputation.faction_id or "-")
    end
    local rSpec = data.specialisation and tostring(data.specialisation) or "-"
    local rHol = data.holiday and tostring(data.holiday) or "-"
    local rPrice = "-"
    local rLearnedFrom = "-"

    self.selectedRecipe.waypoint = nil

    local function resolveNPC(npcId)
        local npc = RR.DB:GetNPC(npcId)
        if not npc then return nil end
        local nName = (type(npc.name) == "table" and (npc.name[locale] or npc.name["German"] or npc.name["English"])) or npc.name or "NPC"
        local zId = (npc.location and npc.location.zone_id) or npc.zone_id
        local zName = RR.DB:GetZoneName(zId)
        local nx = tonumber(npc.location and npc.location.x or npc.x or 0)
        local ny = tonumber(npc.location and npc.location.y or npc.y or 0)
        return nName, zName, nx, ny
    end

    local trainerSources = data.trainers and (data.trainers.sources or (type(data.trainers) == "table" and data.trainers))
    local vendorSources = data.vendors and (data.vendors.sources or (type(data.vendors) == "table" and data.vendors))
    local questSources = data.quests and (data.quests.sources or (type(data.quests) == "table" and data.quests))
    local dropSources = data.drops and (data.drops.sources or (type(data.drops) == "table" and data.drops))

    if data.trainers and data.trainers.price then
        rPrice = RR.Utils:FormatMoney(data.trainers.price)
    elseif data.vendors and data.vendors.price then
        rPrice = RR.Utils:FormatMoney(data.vendors.price)
    end

    if trainerSources and type(trainerSources) == "table" and #trainerSources > 0 then
        local nName, zName, nx, ny = resolveNPC(trainerSources[1])
        if nName then
            rLearnedFrom = string.format("%s (Lehrer) - %s (%.1f, %.1f)", nName, zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif vendorSources and type(vendorSources) == "table" and #vendorSources > 0 then
        local nName, zName, nx, ny = resolveNPC(vendorSources[1])
        if nName then
            rLearnedFrom = string.format("%s (Händler) - %s (%.1f, %.1f)", nName, zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif questSources and type(questSources) == "table" and #questSources > 0 then
        local q = RR.DB:GetQuest(questSources[1])
        local qName = (q and type(q.name) == "table" and (q.name[locale] or q.name["German"] or q.name["English"])) or "Quest"
        local zName = q and RR.DB:GetZoneName(q.zone_id) or "World"
        rLearnedFrom = string.format("%s (Quest) - %s", qName, zName)
    elseif dropSources and type(dropSources) == "table" and #dropSources > 0 then
        local nName, zName, nx, ny = resolveNPC(dropSources[1])
        if nName then
            rLearnedFrom = string.format("%s (Beute) - %s (%.1f, %.1f)", nName, zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    end

    local values = string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s",
        rName, rPhase, rSkill, rXp, rRep, rSpec, rHol, rPrice, rLearnedFrom, "-")

    self.detailLabels:SetText(labels)
    self.detailValues:SetText(values)

    -- Alt knowledge status
    local alts = RR.AltTracker:GetAltStatusForRecipe(RR.Scanner.currentProfession, recipeItem.id, recipeItem.name)
    local altsStr = ""
    for _, alt in ipairs(alts) do
        local statusStr = alt.isKnown and (RR.COLORS.GREEN .. "✓ " .. RR.L["LEARNED"]) or (RR.COLORS.RED .. "✗ " .. RR.L["MODE_MISSING"])
        altsStr = altsStr .. string.format("%s (%s): %s\n", alt.name, alt.class, statusStr)
    end
    self.altsText:SetText(altsStr ~= "" and altsStr or (RR.COLORS.GREY .. RR.L["NO_ALTS_REALM"]))

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

    local maxWidth = anchorBtn:GetWidth() or 120
    local itemHeight = 22
    local count = #items

    for i, itm in ipairs(items) do
        local btn = dropdownPopup.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dropdownPopup, BackdropTemplateMixin and "BackdropTemplate")
            btn:SetHeight(itemHeight)
            RR.UI.Theme:SkinPanel(btn, 0.6)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("LEFT", 8, 0)

            btn.check = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.check:SetPoint("RIGHT", -8, 0)
            btn.check:SetText(RR.COLORS.TEAL .. "✓")

            btn:SetScript("OnEnter", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.25, 0.28, 0.35, 1) end
            end)
            btn:SetScript("OnLeave", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.04, 0.05, 0.06, 0.6) end
            end)

            dropdownPopup.buttons[i] = btn
        end

        btn:SetPoint("TOPLEFT", 4, -((i - 1) * itemHeight + 4))
        btn:SetPoint("TOPRIGHT", -4, -((i - 1) * itemHeight + 4))
        btn.text:SetText(itm.text)

        local strWidth = (btn.text:GetStringWidth() or 80) + 36
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

    dropdownPopup:SetSize(maxWidth + 8, count * itemHeight + 8)
    dropdownPopup:Show()
end
