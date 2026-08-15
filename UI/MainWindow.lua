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

    -- 1. Header Bar
    local header = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(44)
    RR.UI.Theme:SkinPanel(header, 0.98)

    -- Emblem & Title
    local emblem = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    emblem:SetPoint("LEFT", 10, 0)
    emblem:SetText("📜")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", emblem, "RIGHT", 8, 0)
    title:SetText(RR.COLORS.TITLE .. "RecipeRadar")

    -- Navigation Tabs
    self.tabs = {}
    local tabNames = { { "RECIPES", "recipes" }, { "ALTS", "alts" }, { "NPCS", "npcs" }, { "OPTIONS", "options" } }
    local prevTab = nil
    for i, t in ipairs(tabNames) do
        local tabBtn = RR.UI.Theme:CreateButton(header, RR.L[t[1]], 85, 22)
        if prevTab then
            tabBtn:SetPoint("LEFT", prevTab, "RIGHT", 4, 0)
        else
            tabBtn:SetPoint("LEFT", title, "RIGHT", 24, 0)
        end
        tabBtn:SetScript("OnClick", function()
            self:SelectTab(t[2])
        end)
        self.tabs[t[2]] = tabBtn
        prevTab = tabBtn
    end
    self.activeTab = "recipes"
    self.tabs["recipes"]:SetActive(true)

    -- Search Box
    local search = CreateFrame("EditBox", nil, header, BackdropTemplateMixin and "BackdropTemplate")
    search:SetSize(140, 20)
    search:SetPoint("RIGHT", -32, 0)
    search:SetAutoFocus(false)
    search:SetFontObject("GameFontHighlightSmall")
    RR.UI.Theme:SkinPanel(search, 0.9)
    search:SetTextInsets(6, 6, 0, 0)
    search:SetScript("OnTextChanged", function(eb)
        self.searchQuery = eb:GetText()
        self:Refresh()
    end)
    search:SetScript("OnEscapePressed", function(eb) eb:ClearFocus() end)
    self.searchBox = search

    -- Close Button
    local close = CreateFrame("Button", nil, header)
    close:SetSize(20, 20)
    close:SetPoint("RIGHT", -6, 0)
    close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    close:SetScript("OnClick", function() f:Hide() end)

    -- 2. Sub-Filter Bar
    local filterBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    filterBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    filterBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    filterBar:SetHeight(34)
    RR.UI.Theme:SkinPanel(filterBar, 0.95)

    -- Mode Buttons
    self.modeBtns = {}
    local modes = { "missing", "known", "all" }
    local modeLabels = { missing = "MODE_MISSING", known = "MODE_KNOWN", all = "MODE_ALL" }
    local prevMode = nil
    for _, m in ipairs(modes) do
        local btn = RR.UI.Theme:CreateButton(filterBar, RR.L[modeLabels[m]], 80, 22)
        if prevMode then
            btn:SetPoint("LEFT", prevMode, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", 8, 0)
        end
        btn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("mode", m)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        self.modeBtns[m] = btn
        prevMode = btn
    end

    -- Quick Zone Buttons
    self.zoneBtns = {}
    local zones = { "any", "current", "last" }
    local zoneLabels = { any = "ZONE_ANY", current = "ZONE_CURRENT", last = "ZONE_LAST" }
    local prevZone = nil
    for _, z in ipairs(zones) do
        local btn = RR.UI.Theme:CreateButton(filterBar, RR.L[zoneLabels[z]], 85, 22)
        if prevZone then
            btn:SetPoint("LEFT", prevZone, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", prevMode, "RIGHT", 20, 0)
        end
        btn:SetScript("OnClick", function()
            RR.Config:SetFilterSetting("zoneMode", z)
            self:UpdateFilterButtons()
            self:Refresh()
        end)
        self.zoneBtns[z] = btn
        prevZone = btn
    end

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
        RR.UI.Theme:SkinPanel(row, 0.8)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 4, 0)
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetText("Recipe Name")

        row.skill = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.skill:SetPoint("RIGHT", -6, 0)
        row.skill:SetText("300")

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

    -- 4. Right Column: Details Pane
    local detailPane = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    detailPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 2, 0)
    detailPane:SetPoint("BOTTOMRIGHT", -4, 36)
    RR.UI.Theme:SkinPanel(detailPane, 0.95)
    self.detailPane = detailPane

    -- Detail Header (Big icon & title)
    self.detailIcon = detailPane:CreateTexture(nil, "ARTWORK")
    self.detailIcon:SetSize(36, 36)
    self.detailIcon:SetPoint("TOPLEFT", 12, -12)
    self.detailIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    self.detailTitle = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.detailTitle:SetPoint("TOPLEFT", self.detailIcon, "TOPRIGHT", 10, 0)
    self.detailTitle:SetText(RR.COLORS.GOLD .. RR.L["SELECT_A_RECIPE"])

    self.detailSub = detailPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.detailSub:SetPoint("TOPLEFT", self.detailTitle, "BOTTOMLEFT", 0, -4)
    self.detailSub:SetText(RR.COLORS.GREY .. RR.L["REQUIRES_PROFESSION"])

    -- Materials Section
    local matsBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    matsBox:SetPoint("TOPLEFT", self.detailIcon, "BOTTOMLEFT", 0, -14)
    matsBox:SetPoint("RIGHT", -12, 0)
    matsBox:SetHeight(75)
    RR.UI.Theme:SkinPanel(matsBox, 0.8)
    local matsTitle = matsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matsTitle:SetPoint("TOPLEFT", 6, -6)
    matsTitle:SetText(RR.COLORS.GOLD .. RR.L["REAGENTS"])
    self.matsText = matsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.matsText:SetPoint("TOPLEFT", matsTitle, "BOTTOMLEFT", 0, -4)
    self.matsText:SetPoint("BOTTOMRIGHT", -6, 6)
    self.matsText:SetJustifyH("LEFT")
    self.matsText:SetJustifyV("TOP")
    self.matsText:SetText(RR.COLORS.GREY .. RR.L["NO_MATERIALS"])

    -- Acquisition Source Section
    local sourceBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    sourceBox:SetPoint("TOPLEFT", matsBox, "BOTTOMLEFT", 0, -10)
    sourceBox:SetPoint("RIGHT", -12, 0)
    sourceBox:SetHeight(85)
    RR.UI.Theme:SkinPanel(sourceBox, 0.8)
    local sourceTitle = sourceBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceTitle:SetPoint("TOPLEFT", 6, -6)
    sourceTitle:SetText(RR.COLORS.GOLD .. RR.L["ACQUISITION"])
    self.sourceText = sourceBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.sourceText:SetPoint("TOPLEFT", sourceTitle, "BOTTOMLEFT", 0, -4)
    self.sourceText:SetPoint("RIGHT", -6, 0)
    self.sourceText:SetJustifyH("LEFT")
    self.sourceText:SetText(RR.COLORS.WHITE .. RR.L["SOURCE_DETAILS"])

    -- TomTom Button
    self.tomtomBtn = RR.UI.Theme:CreateButton(sourceBox, "📍 " .. RR.L["TOMTOM_WAYPOINT"], 140, 20)
    self.tomtomBtn:SetPoint("BOTTOMRIGHT", -6, 6)
    self.tomtomBtn:SetScript("OnClick", function()
        if self.selectedRecipe and self.selectedRecipe.waypoint then
            local wp = self.selectedRecipe.waypoint
            RR.Utils:AddTomTomWaypoint(wp.zone, wp.x, wp.y, wp.name)
        end
    end)

    -- Alt Character Knowledge Section
    local altsBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    altsBox:SetPoint("TOPLEFT", sourceBox, "BOTTOMLEFT", 0, -10)
    altsBox:SetPoint("BOTTOMRIGHT", -12, 10)
    RR.UI.Theme:SkinPanel(altsBox, 0.8)
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
    local curMode = RR.Config:GetFilterSetting("mode")
    for m, btn in pairs(self.modeBtns) do
        btn:SetActive(m == curMode)
    end
    local curZone = RR.Config:GetFilterSetting("zoneMode")
    for z, btn in pairs(self.zoneBtns) do
        btn:SetActive(z == curZone)
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

    local labels = "Name:\nPhase:\nBenötigter Skill:\nSpielerstufe:\nRuf:\nSpezialisierung:\nWeltereignis:\nPreis:\nErlernt von:\nFundort:"
    
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
            rLearnedFrom = nName .. " (Lehrer)"
            rObtainedFrom = string.format("%s (%.1f, %.1f)", zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif vendorSources and type(vendorSources) == "table" and #vendorSources > 0 then
        local nName, zName, nx, ny = resolveNPC(vendorSources[1])
        if nName then
            rLearnedFrom = nName .. " (Händler)"
            rObtainedFrom = string.format("%s (%.1f, %.1f)", zName, nx, ny)
            self.selectedRecipe.waypoint = { name = nName, zone = zName, x = nx, y = ny }
        end
    elseif questSources and type(questSources) == "table" and #questSources > 0 then
        local q = RR.DB:GetQuest(questSources[1])
        local qName = (q and type(q.name) == "table" and (q.name[locale] or q.name["German"] or q.name["English"])) or "Quest"
        local zName = q and RR.DB:GetZoneName(q.zone_id) or "World"
        rLearnedFrom = qName .. " (Quest)"
        rObtainedFrom = zName
    elseif dropSources and type(dropSources) == "table" and #dropSources > 0 then
        local nName, zName, nx, ny = resolveNPC(dropSources[1])
        if nName then
            rLearnedFrom = nName .. " (Beute)"
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
