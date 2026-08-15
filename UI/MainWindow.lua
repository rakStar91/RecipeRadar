-- ============================================================================
-- RecipeRadar: UI/MainWindow.lua
-- Main interface matching the authentic dark WoW prototype
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.MainWindow = {}

local NUM_VISIBLE_ROWS = 14
local ROW_HEIGHT = 28

function RR.UI.MainWindow:Initialize()
    if self.frame then return end

    local f = CreateFrame("Frame", "RecipeRadarFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(840, 560)
    f:SetPoint("CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:Hide()

    RR.UI.Theme:SkinWindow(f)
    self.frame = f

    -- 1. Header Bar with Authentic Title Plaque Banner
    local header = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(48)
    RR.UI.Theme:SkinPanel(header, 0.8)

    -- Decorative Plaque Banner
    self.titlePlaque = RR.UI.Theme:CreateTitlePlaque(header, 320, 42, RR.NAME)
    self.titlePlaque:SetPoint("LEFT", 8, 0)

    -- Navigation Tabs
    self.tabs = {}
    local tabDefs = {
        { id = "recipes", label = "RECIPES" },
        { id = "alts", label = "ALTS" },
        { id = "npcs", label = "NPCS" },
        { id = "options", label = "OPTIONS" },
    }
    local prevTab = nil
    for _, tabDef in ipairs(tabDefs) do
        local tabBtn = RR.UI.Theme:CreateButton(header, RR.L[tabDef.label], 85, 24)
        if prevTab then
            tabBtn:SetPoint("LEFT", prevTab, "RIGHT", 4, 0)
        else
            tabBtn:SetPoint("LEFT", self.titlePlaque, "RIGHT", 14, 0)
        end
        tabBtn:SetScript("OnClick", function()
            self:SelectTab(tabDef.id)
        end)
        self.tabs[tabDef.id] = tabBtn
        prevTab = tabBtn
    end
    self.tabs["recipes"]:SetActive(true)

    -- Search Box
    local search = CreateFrame("EditBox", nil, header, BackdropTemplateMixin and "BackdropTemplate")
    search:SetSize(130, 22)
    search:SetPoint("RIGHT", -32, 0)
    search:SetAutoFocus(false)
    search:SetFontObject("GameFontHighlightSmall")
    search:SetTextInsets(6, 6, 0, 0)
    RR.UI.Theme:SkinPanel(search, 0.9)

    search:SetScript("OnTextChanged", function(selfBox)
        self.searchQuery = selfBox:GetText()
        self:Refresh()
    end)
    search:SetScript("OnEscapePressed", function(selfBox)
        selfBox:SetText("")
        selfBox:ClearFocus()
    end)
    self.searchBox = search

    -- Close Button
    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- 2. Sub-Filter Bar: Mode + Quick Zone + Authentic WoW Dropdown Frames
    local filterBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    filterBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    filterBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    filterBar:SetHeight(36)
    RR.UI.Theme:SkinPanel(filterBar, 0.8)

    -- A) Mode Buttons (Fehlend / Gelernt / Alle)
    self.modeBtns = {}
    local modes = { "missing", "known", "all" }
    local modeLabels = { missing = "MODE_MISSING", known = "MODE_KNOWN", all = "MODE_ALL" }
    local prevMode = nil
    for _, m in ipairs(modes) do
        local btn = RR.UI.Theme:CreateButton(filterBar, RR.L[modeLabels[m]], 58, 22)
        if prevMode then
            btn:SetPoint("LEFT", prevMode, "RIGHT", 3, 0)
        else
            btn:SetPoint("LEFT", 6, 0)
        end
        btn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("mode", m)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        self.modeBtns[m] = btn
        prevMode = btn
    end

    -- B) Quick Zone Buttons (Alle Zonen / Aktuelle Zone / Letzte Zone)
    self.zoneBtns = {}
    local quickZones = {
        { key = "any", label = "ZONE_ALL" },
        { key = "current", label = "ZONE_CURRENT" },
        { key = "last", label = "ZONE_LAST" },
    }
    local prevZone = nil
    for _, z in ipairs(quickZones) do
        local btn = RR.UI.Theme:CreateButton(filterBar, RR.L[z.label], 80, 22)
        if prevZone then
            btn:SetPoint("LEFT", prevZone, "RIGHT", 3, 0)
        else
            btn:SetPoint("LEFT", prevMode, "RIGHT", 8, 0)
        end
        btn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("zoneFilter", z.key)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        self.zoneBtns[z.key] = btn
        prevZone = btn
    end

    -- C) Authentic Source DropDown Frame
    local sourceMenu = {
        { text = RR.L["SOURCE_ALL"], value = "any" },
        { text = RR.L["SOURCE_TRAINER"], value = "trainer" },
        { text = RR.L["SOURCE_VENDOR"], value = "vendor" },
        { text = RR.L["SOURCE_QUEST"], value = "quest" },
        { text = RR.L["SOURCE_DROP"], value = "drop" },
        { text = RR.L["SOURCE_HOLIDAY"], value = "holiday" },
        { text = RR.L["SOURCE_REPUTATION"], value = "reputation" },
    }
    self.sourceBtn = RR.UI.Theme:CreateDropDownFrame(filterBar, 90, "Quelle", function(selfF)
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
    self.sourceBtn:SetPoint("LEFT", prevZone, "RIGHT", 14, 0)

    -- D) Authentic Faction & Reputation DropDown Frame
    local factionMenu = {
        { text = RR.L["FACTION_ALL"], value = "any" },
        { text = RR.L["FACTION_ALLIANCE"], value = "Alliance" },
        { text = RR.L["FACTION_HORDE"], value = "Horde" },
        { text = RR.L["FACTION_NEUTRAL"], value = "Neutral" },
        { text = "Argentumdämmerung", value = 529 },
        { text = "Thoriumbruderschaft", value = 59 },
        { text = "Holzschlundfeste", value = 576 },
        { text = "Stamm der Zandalari", value = 270 },
        { text = "Hydraxianer", value = 749 },
        { text = "Dunkelmond-Jahrmarkt", value = 909 },
        { text = "Cenarischer Zirkel", value = 609 },
    }
    self.factionBtn = RR.UI.Theme:CreateDropDownFrame(filterBar, 100, "Fraktion", function(selfF)
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
    self.factionBtn:SetPoint("LEFT", self.sourceBtn, "RIGHT", 14, 0)

    -- E) Authentic Phase DropDown Frame
    local phaseMenu = {
        { text = RR.L["PHASE_ALL"], value = 0 },
        { text = RR.L["PHASE_1"], value = 1 },
        { text = RR.L["PHASE_2"], value = 2 },
        { text = RR.L["PHASE_3"], value = 3 },
        { text = RR.L["PHASE_4"], value = 4 },
        { text = RR.L["PHASE_5"], value = 5 },
        { text = RR.L["PHASE_6"], value = 6 },
    }
    self.phaseBtn = RR.UI.Theme:CreateDropDownFrame(filterBar, 80, "Phase", function(selfF)
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
    self.phaseBtn:SetPoint("LEFT", self.factionBtn, "RIGHT", 14, 0)
    -- 3. Left Column: Recipe List Pane
    local listPane = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    listPane:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -2)
    listPane:SetPoint("BOTTOMLEFT", 4, 36)
    listPane:SetWidth(460)
    RR.UI.Theme:SkinPanel(listPane, 0.95)
    self.listPane = listPane

    self.rows = {}
    for i = 1, NUM_VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, listPane, BackdropTemplateMixin and "BackdropTemplate")
        row:SetPoint("TOPLEFT", 4, -((i - 1) * ROW_HEIGHT + 4))
        row:SetPoint("TOPRIGHT", -22, -((i - 1) * ROW_HEIGHT + 4))
        row:SetHeight(ROW_HEIGHT - 2)
        RR.UI.Theme:SkinPanel(row, 0.4)

        -- Clean list item without icon (MTSL style)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", 8, 0)
        row.name:SetPoint("RIGHT", -40, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetText("Recipe Name")

        row.skill = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.skill:SetPoint("RIGHT", -8, 0)
        row.skill:SetTextColor(1, 0.82, 0, 1)

        row:SetScript("OnClick", function(selfRow)
            if selfRow.recipeData then
                RR.UI.MainWindow:SelectRecipe(selfRow.recipeData)
            end
        end)

        self.rows[i] = row
    end

    -- Scrollbar for list
    listPane.SetVerticalScroll = function() end -- Dummy to prevent Blizzard template errors
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

    -- 4. Right Column: Details Pane (Authentic Structured Attribute Grid)
    local detailPane = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    detailPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 2, 0)
    detailPane:SetPoint("BOTTOMRIGHT", -4, 36)
    RR.UI.Theme:SkinPanel(detailPane, 0.95)
    self.detailPane = detailPane

    -- Key-Value Attribute Grid Box
    local attrBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    attrBox:SetPoint("TOPLEFT", 8, -8)
    attrBox:SetPoint("TOPRIGHT", -8, -8)
    attrBox:SetHeight(230)
    RR.UI.Theme:SkinPanel(attrBox, 0.7)

    self.detailLabels = attrBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.detailLabels:SetPoint("TOPLEFT", 10, -10)
    self.detailLabels:SetJustifyH("LEFT")
    self.detailLabels:SetJustifyV("TOP")
    self.detailLabels:SetTextColor(1, 0.82, 0, 1) -- Gold labels
    self.detailLabels:SetText(RR.L["LABEL_NAME"] .. "\n" .. RR.L["LABEL_PHASE"] .. "\n" .. RR.L["LABEL_NEEDS_SKILL"] .. "\n" .. RR.L["LABEL_NEEDS_XP"] .. "\n" .. RR.L["LABEL_NEEDS_REP"] .. "\n" .. RR.L["LABEL_SPECIALISATION"] .. "\n" .. RR.L["LABEL_HOLIDAY"] .. "\n" .. RR.L["LABEL_PRICE"] .. "\n" .. RR.L["LABEL_LEARNED_FROM"] .. "\n" .. RR.L["LABEL_OBTAINED_FROM"])

    self.detailValues = attrBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailValues:SetPoint("TOPLEFT", 130, -10)
    self.detailValues:SetPoint("RIGHT", -10, 0)
    self.detailValues:SetJustifyH("LEFT")
    self.detailValues:SetJustifyV("TOP")
    self.detailValues:SetTextColor(1, 1, 1, 1) -- White values
    self.detailValues:SetText("-\n-\n-\n-\n-\n-\n-\n-\n-\n-")

    local tomtomBtn = RR.UI.Theme:CreateButton(attrBox, "📌 " .. RR.L["TOMTOM_WAYPOINT"], 150, 22)
    tomtomBtn:SetPoint("BOTTOMRIGHT", -8, 8)
    tomtomBtn:SetScript("OnClick", function()
        if self.selectedRecipe and self.selectedRecipe.waypoint then
            local wp = self.selectedRecipe.waypoint
            RR.Utils:AddTomTomWaypoint(wp.name, wp.zone, wp.x, wp.y)
        end
    end)

    -- Alt Character Knowledge Section
    local altsBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    altsBox:SetPoint("TOPLEFT", attrBox, "BOTTOMLEFT", 0, -8)
    altsBox:SetPoint("BOTTOMRIGHT", -8, 8)
    RR.UI.Theme:SkinPanel(altsBox, 0.7)
    local altsTitle = altsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    altsTitle:SetPoint("TOPLEFT", 8, -8)
    altsTitle:SetText(RR.COLORS.GOLD .. RR.L["ALTS_STATUS"])
    self.altsText = altsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.altsText:SetPoint("TOPLEFT", altsTitle, "BOTTOMLEFT", 0, -4)
    self.altsText:SetPoint("BOTTOMRIGHT", -8, 8)
    self.altsText:SetJustifyH("LEFT")
    self.altsText:SetJustifyV("TOP")

    -- 5. Footer Progress Bar
    local footer = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", 4, 4)
    footer:SetPoint("BOTTOMRIGHT", -4, 4)
    footer:SetHeight(30)
    RR.UI.Theme:SkinPanel(footer, 0.98)

    self.progressBar = CreateFrame("StatusBar", nil, footer, BackdropTemplateMixin and "BackdropTemplate")
    self.progressBar:SetPoint("LEFT", 12, 0)
    self.progressBar:SetSize(350, 14)
    self.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.progressBar:SetStatusBarColor(0.15, 0.75, 0.35, 1)
    RR.UI.Theme:SkinPanel(self.progressBar, 0.9)

    self.progressText = self.progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.progressText:SetPoint("CENTER", 0, 0)
    self.progressText:SetText("0 / 0 (0%)")

    self.footerStatus = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.footerStatus:SetPoint("RIGHT", -12, 0)
    self.footerStatus:SetText("RecipeRadar v" .. RR.VERSION)

    self:UpdateFilterButtons()
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

function RR.UI.MainWindow:SelectTab(tabKey)
    self.activeTab = tabKey
    for k, btn in pairs(self.tabs) do
        btn:SetActive(k == tabKey)
    end
    self:Refresh()
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
            btn:SetActive(z == curZone)
        end
    end
end

function RR.UI.MainWindow:Refresh()
    if not self.frame or not self.frame:IsShown() then return end

    local prof = RR.Scanner.currentProfession or "Tailoring"
    local rawRecipes = RR.DB:GetRecipesForProfession(prof)
    
    local filtered, counts = RR.Filter:ApplyFilters(rawRecipes, prof, self.searchQuery)
    self.currentList = filtered

    -- Update Progress Bar
    local pct = counts.total > 0 and math.floor((counts.known / counts.total) * 100) or 0
    self.progressBar:SetMinMaxValues(0, counts.total)
    self.progressBar:SetValue(counts.known)
    self.progressText:SetText(string.format("%d / %d (%d%%)", counts.known, counts.total, pct))

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

    for i = 1, NUM_VISIBLE_ROWS do
        local row = self.rows[i]
        local dataIndex = offset + i

        if dataIndex <= #filtered then
            local item = filtered[dataIndex]
            row.recipeData = item
            row.name:SetText(item.name)
            row.skill:SetText(tostring(item.skillReq))



            if item.isKnown then
                row.name:SetTextColor(0.18, 0.83, 0.75, 1) -- Teal highlight for known
            else
                row.name:SetTextColor(1, 0.82, 0, 1)
            end

            row:Show()
        else
            row.recipeData = nil
            row:Hide()
        end
    end
end

function RR.UI.MainWindow:SelectRecipe(recipeItem)
    if not recipeItem then return end
    self.selectedRecipe = recipeItem
    local data = recipeItem.data or {}
    local locale = GetLocale()

    local labels = RR.L["LABEL_NAME"] .. "\n" .. RR.L["LABEL_PHASE"] .. "\n" .. RR.L["LABEL_NEEDS_SKILL"] .. "\n" .. RR.L["LABEL_NEEDS_XP"] .. "\n" .. RR.L["LABEL_NEEDS_REP"] .. "\n" .. RR.L["LABEL_SPECIALISATION"] .. "\n" .. RR.L["LABEL_HOLIDAY"] .. "\n" .. RR.L["LABEL_PRICE"] .. "\n" .. RR.L["LABEL_LEARNED_FROM"] .. "\n" .. RR.L["LABEL_OBTAINED_FROM"]
    
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
    local rObtainedFrom = "-"

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
            rLearnedFrom = nName .. " " .. RR.L["TAG_TRAINER"]
            rObtainedFrom = string.format("%s (%.1f, %.1f)", zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif vendorSources and type(vendorSources) == "table" and #vendorSources > 0 then
        local nName, zName, nx, ny = resolveNPC(vendorSources[1])
        if nName then
            rLearnedFrom = nName .. " " .. RR.L["TAG_VENDOR"]
            rObtainedFrom = string.format("%s (%.1f, %.1f)", zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif questSources and type(questSources) == "table" and #questSources > 0 then
        local q = RR.DB:GetQuest(questSources[1])
        local qName = (q and type(q.name) == "table" and (q.name[locale] or q.name["German"] or q.name["English"])) or "Quest"
        local zName = q and RR.DB:GetZoneName(q.zone_id) or "World"
        rLearnedFrom = qName .. " " .. RR.L["TAG_QUEST"]
        rObtainedFrom = zName
    elseif dropSources and type(dropSources) == "table" and #dropSources > 0 then
        local nName, zName, nx, ny = resolveNPC(dropSources[1])
        if nName then
            rLearnedFrom = nName .. " " .. RR.L["TAG_DROP"]
            rObtainedFrom = string.format("%s (%.1f, %.1f)", zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    end

    local values = string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s",
        rName, rPhase, rSkill, rXp, rRep, rSpec, rHol, rPrice, rLearnedFrom, rObtainedFrom)

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
end


-- Custom Dark Theme Dropdown Popup Frame
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
