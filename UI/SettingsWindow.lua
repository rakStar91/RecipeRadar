-- ============================================================================
-- RecipeRadar: UI/SettingsWindow.lua
-- Blizzard-style Split-Window Settings & Alt Management
-- Left sidebar navigation tabs + right swappable content panels
-- ============================================================================

local RR = RecipeRadar
local L = RR.L
RR.UI = RR.UI or {}
RR.UI.SettingsWindow = {}

local ROW_HEIGHT = 58
local VISIBLE_ROWS = 6
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate"

function RR.UI.SettingsWindow:Initialize()
    if self.frame then return end

    -- 1. Register Blizzard Confirmation Popup Dialog for Alt Deletion
    if not StaticPopupDialogs["RECIPERADAR_CONFIRM_DELETE_CHAR"] then
        StaticPopupDialogs["RECIPERADAR_CONFIRM_DELETE_CHAR"] = {
            text = L["SETTINGS_CONFIRM_DELETE_DESC"],
            button1 = YES,
            button2 = NO,
            OnAccept = function(selfPopup, data)
                if data and data.charName and data.realm then
                    RR.Config:DeleteCharacter(data.charName, data.realm)
                    if RR.UI.SettingsWindow and RR.UI.SettingsWindow.RefreshCharacters then
                        RR.UI.SettingsWindow:RefreshCharacters()
                    end
                    print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. string.format(L["SETTINGS_CHAR_DELETED_NOTICE"], data.charName))
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    -- 2. Create Main Settings Frame
    local f = CreateFrame("Frame", "RecipeRadarSettingsFrame", UIParent, BACKDROP_TEMPLATE)
    f:SetSize(780, 560)
    f:SetPoint("CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    RR.UI.Theme:SkinWindow(f)

    -- ESC key support via UISpecialFrames
    tinsert(UISpecialFrames, "RecipeRadarSettingsFrame")

    -- 3. Header Plaque Banner
    self.titlePlaque = RR.UI.Theme:CreateTitlePlaque(f, 450, 36, RR.NAME .. " - " .. L["OPTIONS"])
    self.titlePlaque:SetPoint("TOP", f, "TOP", 0, 10)

    -- 4. Close Button ("X") in Top Right
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        self:Hide()
    end)
    self.closeBtn = closeBtn

    -- 5. Left Sidebar Navigation Container
    local sidebar = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    sidebar:SetPoint("TOPLEFT", 16, -46)
    sidebar:SetPoint("BOTTOMLEFT", 16, 44)
    sidebar:SetWidth(156)
    RR.UI.Theme:SkinPanel(sidebar, 0.90)
    self.sidebar = sidebar

    local sidebarLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sidebarLabel:SetPoint("TOPLEFT", 12, -10)
    sidebarLabel:SetTextColor(1, 0.82, 0, 1)
    sidebarLabel:SetText(L["OPTIONS"])

    -- 6. Right Content Container Area
    local contentArea = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    contentArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 44)
    RR.UI.Theme:SkinPanel(contentArea, 0.85)
    self.contentArea = contentArea

    -- Helper to create formatted checkboxes
    local function CreateSettingCheckbox(parent, x, y, labelText, descText, onClick)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", x, y)

        local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        label:SetTextColor(1, 0.82, 0, 1)
        label:SetText(labelText)
        cb.label = label

        local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, -2)
        desc:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
        desc:SetJustifyH("LEFT")
        desc:SetTextColor(0.75, 0.75, 0.75, 1)
        desc:SetText(descText)
        cb.desc = desc

        cb:SetScript("OnClick", function(selfCB)
            local isChecked = (selfCB:GetChecked() == true) or (selfCB:GetChecked() == 1)
            if onClick then onClick(selfCB, isChecked) end
        end)

        return cb
    end

    -- ========================================================================
    -- PANEL 1: Characters & Alts
    -- ========================================================================
    local panelChars = CreateFrame("Frame", nil, contentArea)
    panelChars:SetAllPoints(contentArea)
    panelChars:SetScript("OnShow", function() self:RefreshCharacters() end)
    self.panelChars = panelChars

    local charTitle = panelChars:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    charTitle:SetPoint("TOPLEFT", 14, -12)
    charTitle:SetTextColor(1, 0.82, 0, 1)
    charTitle:SetText(L["SETTINGS_TAB_CHARACTERS"])

    local charDesc = panelChars:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charDesc:SetPoint("TOPLEFT", 14, -34)
    charDesc:SetPoint("TOPRIGHT", -14, -34)
    charDesc:SetJustifyH("LEFT")
    charDesc:SetTextColor(0.85, 0.85, 0.85, 1)
    charDesc:SetText(L["SETTINGS_CHAR_DESC"])

    local realmHeader = panelChars:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    realmHeader:SetPoint("TOPLEFT", 14, -68)
    realmHeader:SetTextColor(1, 0.82, 0, 1)
    self.realmHeader = realmHeader

    local charCountLabel = panelChars:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charCountLabel:SetPoint("TOPRIGHT", -14, -68)
    charCountLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    self.charCountLabel = charCountLabel

    local listPanel = CreateFrame("Frame", nil, panelChars, BACKDROP_TEMPLATE)
    listPanel:SetPoint("TOPLEFT", 12, -90)
    listPanel:SetPoint("BOTTOMRIGHT", -12, 10)
    RR.UI.Theme:SkinPanel(listPanel, 0.70)
    self.listPanel = listPanel

    local emptyLabel = listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", 0, 0)
    emptyLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    emptyLabel:SetText(L["SETTINGS_NO_CHARS"])
    emptyLabel:Hide()
    self.emptyLabel = emptyLabel

    -- Character rows pool
    self.rows = {}
    self.scrollOffset = 0
    self.characterList = {}

    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, listPanel, BACKDROP_TEMPLATE)
        row:SetPoint("TOPLEFT", 6, -((i - 1) * ROW_HEIGHT + 6))
        row:SetPoint("TOPRIGHT", -26, -((i - 1) * ROW_HEIGHT + 6))
        row:SetHeight(ROW_HEIGHT - 2)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.bg:SetAllPoints(row)
        if i % 2 == 0 then
            row.bg:SetVertexColor(1, 1, 1, 0.04)
        else
            row.bg:SetVertexColor(0, 0, 0, 0.18)
        end

        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(34, 34)
        classIcon:SetPoint("LEFT", 10, 0)
        classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
        row.classIcon = classIcon

        -- Line 1: Character identity (anchored to top of row)
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 54, -9)
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        local badgeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgeText:SetPoint("LEFT", nameText, "RIGHT", 6, 0)
        row.badgeText = badgeText

        local factionIcon = row:CreateTexture(nil, "ARTWORK")
        factionIcon:SetSize(14, 14)
        factionIcon:SetPoint("LEFT", badgeText, "RIGHT", 6, 0)
        row.factionIcon = factionIcon

        -- Line 2: Profession Badges (anchored cleanly below Line 1 with 10px clear vertical gap!)
        local profsContainer = CreateFrame("Frame", nil, row)
        profsContainer:SetPoint("TOPLEFT", row, "TOPLEFT", 54, -32)
        profsContainer:SetPoint("RIGHT", row, "RIGHT", -230, 0)
        profsContainer:SetHeight(18)
        row.profsContainer = profsContainer

        local noProfsText = profsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        noProfsText:SetPoint("LEFT", 0, 0)
        noProfsText:SetText(L["SETTINGS_NO_PROFS"])
        row.noProfsText = noProfsText

        row.profBadges = {}
        for b = 1, 5 do
            local badge = CreateFrame("Button", nil, profsContainer)
            badge:SetHeight(18)
            badge:EnableMouse(true)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", 0, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            badge.icon = icon

            local text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
            text:SetTextColor(0.85, 0.85, 0.85, 1)
            badge.text = text

            badge:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

            badge:SetScript("OnEnter", function(selfB)
                if not selfB.profKey then return end
                GameTooltip:SetOwner(selfB, "ANCHOR_RIGHT")
                local locName = RR.DB and RR.DB:GetProfessionDisplayName(selfB.profKey) or selfB.profKey
                GameTooltip:SetText(locName, 1, 0.82, 0)
                if selfB.maxRank and selfB.maxRank > 0 then
                    GameTooltip:AddLine(string.format("%s: %d / %d", L["SETTINGS_SKILL_RANK"], selfB.curRank, selfB.maxRank), 1, 1, 1)
                else
                    GameTooltip:AddLine(string.format("%s: %d", L["SETTINGS_SKILL_RANK"], selfB.curRank), 1, 1, 1)
                end
                if selfB.totalCount and selfB.totalCount > 0 then
                    if selfB.missingCount and selfB.missingCount > 0 then
                        GameTooltip:AddLine(string.format(L["SETTINGS_PROF_RECIPES_STATS"], selfB.knownCount, selfB.missingCount), 0.4, 0.8, 1.0)
                    else
                        GameTooltip:AddLine(string.format(L["SETTINGS_PROF_RECIPES_ALL"], selfB.knownCount), 0.3, 1.0, 0.3)
                    end
                elseif selfB.knownCount and selfB.knownCount > 0 then
                    GameTooltip:AddLine(string.format(L["SETTINGS_PROF_RECIPES_COUNT"], selfB.knownCount), 0.4, 0.8, 1.0)
                end
                GameTooltip:Show()
            end)
            badge:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            row.profBadges[b] = badge
        end

        local deleteBtn = RR.UI.Theme:CreateDarkButton(row, L["SETTINGS_DELETE_CHAR"], 58, 22)
        deleteBtn:SetPoint("RIGHT", -8, 0)
        deleteBtn:SetScript("OnClick", function()
            local charName = row.charName
            if charName then
                StaticPopup_Show("RECIPERADAR_CONFIRM_DELETE_CHAR", charName, nil, {
                    charName = charName,
                    realm = GetRealmName() or "UnknownRealm",
                })
            end
        end)
        row.deleteBtn = deleteBtn

        local checkBtn = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkBtn:SetSize(20, 20)
        checkBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -10, 0)

        local checkLabel = checkBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        checkLabel:SetPoint("RIGHT", checkBtn, "LEFT", -4, 0)
        checkLabel:SetText(L["SETTINGS_SHOW_IN_TOOLTIP"])
        checkBtn.label = checkLabel

        checkBtn:SetScript("OnClick", function(selfCB)
            local isChecked = selfCB:GetChecked()
            local charName = row.charName
            if charName then
                RR.Config:SetCharacterMuted(charName, not isChecked)
                RR.UI.SettingsWindow:RefreshCharacters()
            end
        end)
        RR.UI.Theme:AddTooltip(checkBtn, L["SETTINGS_SHOW_IN_TOOLTIP"], L["SETTINGS_TOOLTIP_MUTED"])
        row.checkBtn = checkBtn

        self.rows[i] = row
    end

    listPanel.SetVerticalScroll = function() end
    local scrollbar = CreateFrame("Slider", "RecipeRadarSettingsScrollBar", listPanel, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPRIGHT", -4, -18)
    scrollbar:SetPoint("BOTTOMRIGHT", -4, 18)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(_, val)
        self.scrollOffset = math.floor((val or 0) + 0.5)
        self:RenderRows()
    end)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    scrollbar:SetValueStep(1)
    self.scrollbar = scrollbar

    local function onMouseWheel(_, delta)
        local cur = self.scrollbar:GetValue() or 0
        local minVal, maxVal = self.scrollbar:GetMinMaxValues()
        if delta < 0 then
            self.scrollbar:SetValue(math.min(maxVal, cur + 1))
        else
            self.scrollbar:SetValue(math.max(minVal, cur - 1))
        end
    end

    listPanel:EnableMouseWheel(true)
    listPanel:SetScript("OnMouseWheel", onMouseWheel)
    for _, row in ipairs(self.rows) do
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", onMouseWheel)
    end

    -- ========================================================================
    -- PANEL 2: Tooltips
    -- ========================================================================
    local panelTooltips = CreateFrame("Frame", nil, contentArea)
    panelTooltips:SetAllPoints(contentArea)
    panelTooltips:SetScript("OnShow", function() self:RefreshTooltips() end)
    self.panelTooltips = panelTooltips

    local ttTitle = panelTooltips:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ttTitle:SetPoint("TOPLEFT", 14, -12)
    ttTitle:SetTextColor(1, 0.82, 0, 1)
    ttTitle:SetText(L["SETTINGS_TOOLTIPS_TITLE"])

    local ttDesc = panelTooltips:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ttDesc:SetPoint("TOPLEFT", 14, -34)
    ttDesc:SetPoint("TOPRIGHT", -14, -34)
    ttDesc:SetJustifyH("LEFT")
    ttDesc:SetTextColor(0.85, 0.85, 0.85, 1)
    ttDesc:SetText(L["SETTINGS_TOOLTIPS_DESC"])

    local cbAlts = CreateSettingCheckbox(panelTooltips, 14, -70,
        L["SETTINGS_OPT_TOOLTIP_ALTS"],
        L["SETTINGS_OPT_TOOLTIP_ALTS_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetTooltipAltsEnabled(isChecked)
        end
    )
    self.cbAlts = cbAlts

    local cbSpells = CreateSettingCheckbox(panelTooltips, 14, -135,
        L["SETTINGS_OPT_TOOLTIP_SPELLS"],
        L["SETTINGS_OPT_TOOLTIP_SPELLS_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetTooltipSpellsEnabled(isChecked)
        end
    )
    self.cbSpells = cbSpells

    local cbCompact = CreateSettingCheckbox(panelTooltips, 14, -200,
        L["SETTINGS_OPT_TOOLTIP_COMPACT"],
        L["SETTINGS_OPT_TOOLTIP_COMPACT_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetTooltipCompactEnabled(isChecked)
        end
    )
    self.cbCompact = cbCompact

    -- Preview card
    local previewBox = CreateFrame("Frame", nil, panelTooltips, BACKDROP_TEMPLATE)
    previewBox:SetPoint("TOPLEFT", 14, -275)
    previewBox:SetPoint("BOTTOMRIGHT", -14, 14)
    RR.UI.Theme:SkinPanel(previewBox, 0.6)

    local prevLabel = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevLabel:SetPoint("TOPLEFT", 10, -8)
    prevLabel:SetTextColor(1, 0.82, 0, 1)
    prevLabel:SetText(L["TOOLTIP_SETTINGS"])

    local prevLine1 = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prevLine1:SetPoint("TOPLEFT", 10, -28)
    prevLine1:SetText(RR.COLORS.TITLE .. "RecipeRadar (" .. L["ALTS"] .. "):|r")

    local prevLine2 = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prevLine2:SetPoint("TOPLEFT", 14, -46)
    prevLine2:SetText("|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12:12:0:0|t |cff33ff33" .. L["LEARNED"] .. ":|r |cffff7d0aDruid|r, |cff0070deShaman|r")

    local prevLine3 = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prevLine3:SetPoint("TOPLEFT", 14, -64)
    prevLine3:SetText("|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12:12:0:0|t |cffff4444" .. L["MODE_MISSING"] .. ":|r |cffc79c6eWarrior|r")

    -- ========================================================================
    -- PANEL 3: Interface & Display
    -- ========================================================================
    local panelInterface = CreateFrame("Frame", nil, contentArea)
    panelInterface:SetAllPoints(contentArea)
    panelInterface:SetScript("OnShow", function() self:RefreshInterface() end)
    self.panelInterface = panelInterface

    local uiTitle = panelInterface:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    uiTitle:SetPoint("TOPLEFT", 14, -12)
    uiTitle:SetTextColor(1, 0.82, 0, 1)
    uiTitle:SetText(L["SETTINGS_INTERFACE_TITLE"])

    local uiDesc = panelInterface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    uiDesc:SetPoint("TOPLEFT", 14, -34)
    uiDesc:SetPoint("TOPRIGHT", -14, -34)
    uiDesc:SetJustifyH("LEFT")
    uiDesc:SetTextColor(0.85, 0.85, 0.85, 1)
    uiDesc:SetText(L["SETTINGS_INTERFACE_DESC"])

    local cbMinimap = CreateSettingCheckbox(panelInterface, 14, -68,
        L["SETTINGS_OPT_MINIMAP"],
        L["SETTINGS_OPT_MINIMAP_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetMinimapButtonShown(isChecked)
        end
    )
    self.cbMinimap = cbMinimap

    local cbAttach = CreateSettingCheckbox(panelInterface, 14, -130,
        L["SETTINGS_OPT_ATTACH_BUTTON"],
        L["SETTINGS_OPT_ATTACH_BUTTON_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetAttachButtonShown(isChecked)
        end
    )
    self.cbAttach = cbAttach

    local cbAutoShow = CreateSettingCheckbox(panelInterface, 14, -192,
        L["SETTINGS_OPT_AUTO_SHOW"],
        L["SETTINGS_OPT_AUTO_SHOW_DESC"],
        function(selfCB, isChecked)
            RR.Config:SetAutoShowEnabled(isChecked)
        end
    )
    self.cbAutoShow = cbAutoShow

    local posHeader = panelInterface:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    posHeader:SetPoint("TOPLEFT", 14, -260)
    posHeader:SetTextColor(1, 0.82, 0, 1)
    posHeader:SetText(L["SETTINGS_SECTION_POSITIONS"])

    local resetAttachBtn = RR.UI.Theme:CreateDarkButton(panelInterface, L["SETTINGS_RESET_ATTACH_POS"], 230, 26)
    resetAttachBtn:SetPoint("TOPLEFT", 14, -286)
    resetAttachBtn:SetScript("OnClick", function()
        RR.Config:ClearButtonOffset()
        if RR.UI.AttachButton then
            RR.UI.AttachButton:PositionButton()
        end
        print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. L["SETTINGS_RESET_ATTACH_POS_DESC"])
    end)

    local resetWindowBtn = RR.UI.Theme:CreateDarkButton(panelInterface, L["SETTINGS_RESET_WINDOW_POS"], 230, 26)
    resetWindowBtn:SetPoint("TOPLEFT", 254, -286)
    resetWindowBtn:SetScript("OnClick", function()
        RR.Config:ResetWindowPosition()
        if RR.UI.MainWindow and RR.UI.MainWindow.frame then
            RR.UI.MainWindow.frame:ClearAllPoints()
            RR.UI.MainWindow.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. L["SETTINGS_POS_RESET_NOTICE"])
    end)

    -- ========================================================================
    -- PANEL 4: About & Help
    -- ========================================================================
    local panelAbout = CreateFrame("Frame", nil, contentArea)
    panelAbout:SetAllPoints(contentArea)
    self.panelAbout = panelAbout

    local abTitle = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    abTitle:SetPoint("TOPLEFT", 14, -12)
    abTitle:SetTextColor(1, 0.82, 0, 1)
    abTitle:SetText(L["SETTINGS_ABOUT_TITLE"])

    local abDesc = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abDesc:SetPoint("TOPLEFT", 14, -34)
    abDesc:SetPoint("TOPRIGHT", -14, -34)
    abDesc:SetJustifyH("LEFT")
    abDesc:SetTextColor(0.85, 0.85, 0.85, 1)
    abDesc:SetText(L["SETTINGS_ABOUT_DESC"])

    local abVersion = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abVersion:SetPoint("TOPLEFT", 14, -68)
    abVersion:SetTextColor(1, 0.82, 0, 1)
    abVersion:SetText(string.format(L["SETTINGS_ABOUT_VERSION"], RR.VERSION or "1.0.0"))

    local abAuthor = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abAuthor:SetPoint("TOPLEFT", 14, -92)
    abAuthor:SetTextColor(0.85, 0.85, 0.85, 1)
    abAuthor:SetText(L["SETTINGS_ABOUT_AUTHORS"])

    local abHint = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abHint:SetPoint("TOPLEFT", 14, -116)
    abHint:SetTextColor(0.75, 0.75, 0.75, 1)
    abHint:SetText(L["SETTINGS_COPY_HINT"])

    local function createCopyRow(yOffset, iconPath, labelText, urlString, tooltipTitle)
        local icon = panelAbout:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 14, yOffset)
        icon:SetSize(18, 18)
        icon:SetTexture(iconPath)
        if iconPath:find("^Interface\\Icons\\") then
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            icon:SetTexCoord(0, 1, 0, 1)
        end

        local label = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetWidth(50)
        label:SetJustifyH("LEFT")
        label:SetTextColor(0.85, 0.85, 0.85, 1)
        label:SetText(labelText)

        local box = CreateFrame("EditBox", nil, panelAbout, BackdropTemplateMixin and "BackdropTemplate")
        box:SetPoint("LEFT", label, "RIGHT", 4, 0)
        box:SetSize(380, 22)
        box:SetAutoFocus(false)
        box:SetFontObject("GameFontHighlightSmall")
        box:SetTextInsets(6, 6, 0, 0)
        box:SetText(urlString)
        RR.UI.Theme:SkinPanel(box, 0.9)

        box:SetScript("OnEditFocusGained", function(selfBox)
            selfBox:HighlightText()
        end)
        box:SetScript("OnMouseUp", function(selfBox)
            selfBox:HighlightText()
        end)
        box:SetScript("OnEscapePressed", function(selfBox)
            selfBox:ClearFocus()
        end)
        box:SetScript("OnEditFocusLost", function(selfBox)
            selfBox:HighlightText(0, 0)
        end)
        box:SetScript("OnTextChanged", function(selfBox, isUserInput)
            if isUserInput then
                selfBox:SetText(urlString)
                selfBox:HighlightText()
            end
        end)

        RR.UI.Theme:AddTooltip(box, tooltipTitle, L["SETTINGS_COPY_URL_DESC"])

        return box
    end

    createCopyRow(-138, RR.ADDON_PATH .. "\\images\\icon_github.tga", "GitHub:", "https://github.com/rakStar91/RecipeRadar", L["SETTINGS_ABOUT_COMMUNITY_TITLE"])
    createCopyRow(-166, RR.ADDON_PATH .. "\\images\\icon_curseforge.tga", "Curse:", "https://www.curseforge.com/wow/addons/reciperadar", L["SETTINGS_ABOUT_CURSEFORGE_TITLE"])
    createCopyRow(-194, RR.ADDON_PATH .. "\\images\\icon_kofi.tga", "Ko-fi:", "https://ko-fi.com/rakstar91", L["SETTINGS_ABOUT_KOFI_TITLE"])

    local abCmdsHeader = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abCmdsHeader:SetPoint("TOPLEFT", 14, -228)
    abCmdsHeader:SetTextColor(1, 0.82, 0, 1)
    abCmdsHeader:SetText(L["SETTINGS_ABOUT_COMMANDS_HEADER"])

    local commandList = {
        { cmd = "/rr", desc = L["SETTINGS_CMD_MAIN"] },
        { cmd = "/rr config | opt", desc = L["SETTINGS_CMD_CONFIG"] },
        { cmd = "/rr minimap | mm", desc = L["SETTINGS_CMD_MINIMAP"] },
        { cmd = "/rr reset", desc = L["SETTINGS_CMD_RESET"] },
        { cmd = "/rr debug", desc = L["SETTINGS_CMD_DEBUG"] },
        { cmd = "/rr help", desc = L["SETTINGS_CMD_HELP"] },
    }

    local cmdY = -252
    for _, item in ipairs(commandList) do
        local cmdText = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cmdText:SetPoint("TOPLEFT", 20, cmdY)
        cmdText:SetWidth(150)
        cmdText:SetJustifyH("LEFT")
        cmdText:SetText(RR.COLORS.GOLD .. item.cmd .. "|r")

        local descText = panelAbout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        descText:SetPoint("TOPLEFT", cmdText, "TOPRIGHT", 10, 0)
        descText:SetPoint("RIGHT", panelAbout, "RIGHT", -20, 0)
        descText:SetJustifyH("LEFT")
        descText:SetTextColor(0.85, 0.85, 0.85, 1)
        descText:SetText(item.desc)

        cmdY = cmdY - 22
    end

    -- ========================================================================
    -- Navigation Sidebar Tabs
    -- ========================================================================
    self.tabs = {}
    local tabDefs = {
        { id = "chars", label = L["SETTINGS_TAB_CHARACTERS"], panel = panelChars },
        { id = "tooltips", label = L["SETTINGS_TAB_TOOLTIPS"], panel = panelTooltips },
        { id = "interface", label = L["SETTINGS_TAB_INTERFACE"], panel = panelInterface },
        { id = "about", label = L["SETTINGS_TAB_ABOUT"], panel = panelAbout },
    }

    local tabY = -34
    for _, def in ipairs(tabDefs) do
        local btn = RR.UI.Theme:CreateDarkButton(sidebar, def.label, 140, 30)
        btn:SetPoint("TOPLEFT", 8, tabY)
        tabY = tabY - 34

        local tabId = def.id
        btn:SetScript("OnClick", function()
            self:SelectTab(tabId)
        end)

        self.tabs[tabId] = {
            btn = btn,
            panel = def.panel,
        }
    end

    -- 7. Bottom Close Button
    local bottomCloseBtn = RR.UI.Theme:CreateDarkButton(f, CLOSE, 90, 24)
    bottomCloseBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    bottomCloseBtn:SetScript("OnClick", function()
        self:Hide()
    end)
    self.bottomCloseBtn = bottomCloseBtn

    self.frame = f

    f:SetScript("OnShow", function()
        self:RefreshTooltips()
        self:RefreshInterface()
        if self.currentTab == "chars" or not self.currentTab then
            self:RefreshCharacters()
        end
    end)

    self:RefreshTooltips()
    self:RefreshInterface()

    f:Hide()
end

--- Selects an active category tab in the sidebar
-- @param tabId string: "chars", "tooltips", "interface", "about"
function RR.UI.SettingsWindow:SelectTab(tabId)
    if not self.tabs then return end
    tabId = tabId or "chars"

    for id, tab in pairs(self.tabs) do
        if id == tabId then
            tab.btn:SetActive(true)
            tab.panel:Show()
        else
            tab.btn:SetActive(false)
            tab.panel:Hide()
        end
    end

    self.currentTab = tabId
    if tabId == "chars" then
        self:RefreshCharacters()
    elseif tabId == "tooltips" then
        self:RefreshTooltips()
    elseif tabId == "interface" then
        self:RefreshInterface()
    end
end

function RR.UI.SettingsWindow:Show(tabId)
    if not self.frame then self:Initialize() end
    self.frame:Show()
    self:SelectTab(tabId or self.currentTab or "chars")
end

function RR.UI.SettingsWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function RR.UI.SettingsWindow:Toggle(tabId)
    if not self.frame then self:Initialize() end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show(tabId)
    end
end

function RR.UI.SettingsWindow:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self:SelectTab(self.currentTab or "chars")
end

function RR.UI.SettingsWindow:RefreshTooltips()
    if self.cbAlts then
        self.cbAlts:SetChecked(RR.Config:IsTooltipAltsEnabled() == true)
    end
    if self.cbSpells then
        self.cbSpells:SetChecked(RR.Config:IsTooltipSpellsEnabled() == true)
    end
    if self.cbCompact then
        self.cbCompact:SetChecked(RR.Config:IsTooltipCompactEnabled() == true)
    end
end

function RR.UI.SettingsWindow:RefreshInterface()
    if self.cbMinimap then
        self.cbMinimap:SetChecked(RR.Config:IsMinimapButtonShown() == true)
    end
    if self.cbAttach then
        self.cbAttach:SetChecked(RR.Config:IsAttachButtonShown() == true)
    end
    if self.cbAutoShow then
        self.cbAutoShow:SetChecked(RR.Config:IsAutoShowEnabled() == true)
    end
end

function RR.UI.SettingsWindow:RefreshCharacters()
    if not self.frame or not self.frame:IsShown() then return end

    local realm = GetRealmName() or "UnknownRealm"
    if self.realmHeader then
        self.realmHeader:SetText(L["LABEL_REALM"] .. " " .. RR.COLORS.WHITE .. realm .. "|r")
    end

    local rawChars = RR.Config:GetCharacters(realm)
    local list = {}
    local currentCharName = UnitName("player")

    for cName, cData in pairs(rawChars) do
        table.insert(list, {
            name = cName,
            data = cData,
            isCurrent = (cName == currentCharName),
        })
    end

    -- Sort: Current character first, then alphabetically
    table.sort(list, function(a, b)
        if a.isCurrent ~= b.isCurrent then
            return a.isCurrent
        end
        return a.name < b.name
    end)

    self.characterList = list

    local maxScroll = math.max(0, #list - VISIBLE_ROWS)
    self.scrollbar:SetMinMaxValues(0, maxScroll)
    if self.scrollOffset > maxScroll then
        self.scrollOffset = maxScroll
        self.scrollbar:SetValue(maxScroll)
    end

    if maxScroll > 0 then
        self.scrollbar:Show()
    else
        self.scrollbar:Hide()
    end

    if #list == 0 then
        self.emptyLabel:Show()
    else
        self.emptyLabel:Hide()
    end

    if self.charCountLabel then
        self.charCountLabel:SetText(string.format(L["SETTINGS_CHARS_COUNT"], #list))
    end

    self:RenderRows()
end

function RR.UI.SettingsWindow:RenderRows()
    local list = self.characterList or {}
    local offset = self.scrollOffset or 0

    for i = 1, VISIBLE_ROWS do
        local row = self.rows[i]
        local idx = offset + i
        local entry = list[idx]

        if entry then
            row:Show()
            local cName = entry.name
            local cData = entry.data
            row.charName = cName

            -- 1. Class Icon
            local classKey = cData.class or "WARRIOR"
            local cCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classKey]
            if cCoords then
                row.classIcon:SetTexCoord(cCoords[1], cCoords[2], cCoords[3], cCoords[4])
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end

            -- 2. Character Name in Class Color
            local cColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
            if cColor then
                row.nameText:SetText(string.format("|cff%02x%02x%02x%s|r", cColor.r * 255, cColor.g * 255, cColor.b * 255, cName))
            else
                row.nameText:SetText(cName)
            end

            -- 3. Badge (Level or Current Character tag)
            local badgeStr = ""
            if entry.isCurrent then
                badgeStr = "|cff00ff00[" .. L["SETTINGS_CURRENT_CHAR_BADGE"] .. "]|r"
            end
            if cData.level and cData.level > 0 then
                local lvlStr = string.format(L["SETTINGS_LEVEL_FORMAT"], cData.level)
                if badgeStr ~= "" then
                    badgeStr = badgeStr .. " |cffaaaaaa(" .. lvlStr .. ")|r"
                else
                    badgeStr = "|cffaaaaaa(" .. lvlStr .. ")|r"
                end
            end
            row.badgeText:SetText(badgeStr)

            -- 4. Faction Icon
            local faction = cData.faction or "Neutral"
            if faction == "Alliance" then
                row.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
                row.factionIcon:SetTexCoord(0.05, 0.60, 0.05, 0.60)
                row.factionIcon:Show()
            elseif faction == "Horde" then
                row.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
                row.factionIcon:SetTexCoord(0.05, 0.60, 0.05, 0.60)
                row.factionIcon:Show()
            else
                row.factionIcon:Hide()
            end

            -- 5. Profession Badges
            local profList = {}
            if cData.professions and next(cData.professions) then
                local seen = {}
                for pKey, pInfo in pairs(cData.professions) do
                    local engKey = RR.DB and RR.DB:GetEnglishProfessionName(pKey) or pKey
                    if not seen[engKey] and type(pInfo) == "table" then
                        seen[engKey] = true
                        local curRank = pInfo.current or 0
                        local maxRank = pInfo.max or 0
                        local knownCount, totalCount, missingCount = 0, 0, 0
                        if RR.DB and RR.DB.GetCharacterRecipeStats then
                            knownCount, totalCount, missingCount = RR.DB:GetCharacterRecipeStats(cData, engKey)
                        end

                        -- Sort priority: Crafting (1), Gathering (2), Secondary (3)
                        local priority = 3
                        if engKey == "Tailoring" or engKey == "Blacksmithing" or engKey == "Leatherworking" 
                           or engKey == "Alchemy" or engKey == "Enchanting" or engKey == "Engineering" 
                           or engKey == "Jewelcrafting" then
                            priority = 1
                        elseif engKey == "Mining" or engKey == "Herbalism" or engKey == "Skinning" then
                            priority = 2
                        end

                        table.insert(profList, {
                            key = engKey,
                            curRank = curRank,
                            maxRank = maxRank,
                            knownCount = knownCount,
                            totalCount = totalCount,
                            missingCount = missingCount,
                            priority = priority,
                        })
                    end
                end
                table.sort(profList, function(a, b)
                    if a.priority ~= b.priority then
                        return a.priority < b.priority
                    end
                    return a.key < b.key
                end)
            end

            if #profList == 0 then
                if row.noProfsText then row.noProfsText:Show() end
                if row.profBadges then
                    for b = 1, #row.profBadges do
                        row.profBadges[b]:Hide()
                    end
                end
            else
                if row.noProfsText then row.noProfsText:Hide() end
                local showFullRank = (#profList <= 2)
                local currentX = 0

                for b = 1, #row.profBadges do
                    local badge = row.profBadges[b]
                    local pData = profList[b]
                    if pData then
                        badge.profKey = pData.key
                        badge.curRank = pData.curRank
                        badge.maxRank = pData.maxRank
                        badge.knownCount = pData.knownCount
                        badge.totalCount = pData.totalCount
                        badge.missingCount = pData.missingCount

                        -- Icon
                        local iconPath = RR.PROFESSION_ICONS and RR.PROFESSION_ICONS[pData.key] or "Interface\\Icons\\INV_Misc_QuestionMark"
                        badge.icon:SetTexture(iconPath)

                        -- Rank Text (Gold for max rank, white otherwise)
                        local rankStr
                        if pData.maxRank and pData.maxRank > 0 and pData.curRank >= pData.maxRank then
                            rankStr = string.format("|cffffd100%d|r", pData.curRank)
                        elseif showFullRank and pData.maxRank and pData.maxRank > 0 then
                            rankStr = string.format("|cffffffff%d/%d|r", pData.curRank, pData.maxRank)
                        else
                            rankStr = string.format("|cffffffff%d|r", pData.curRank)
                        end
                        badge.text:SetText(rankStr)

                        local badgeWidth = 16 + 4 + math.ceil(badge.text:GetStringWidth() or 20)
                        badge:SetWidth(badgeWidth)
                        badge:ClearAllPoints()
                        badge:SetPoint("LEFT", row.profsContainer, "LEFT", currentX, 0)
                        badge:Show()

                        currentX = currentX + badgeWidth + 10
                    else
                        badge:Hide()
                    end
                end
            end

            -- 6. Mute Checkbox
            local isMuted = (cData.muted == true)
            row.checkBtn:SetChecked(not isMuted)
            if isMuted then
                row.bg:SetVertexColor(0.2, 0.05, 0.05, 0.3)
                row.checkBtn.label:SetTextColor(0.6, 0.6, 0.6, 1)
            else
                if i % 2 == 0 then
                    row.bg:SetVertexColor(1, 1, 1, 0.04)
                else
                    row.bg:SetVertexColor(0, 0, 0, 0.18)
                end
                row.checkBtn.label:SetTextColor(1, 1, 1, 1)
            end

            -- 7. Delete Button (disabled for current player)
            if entry.isCurrent then
                row.deleteBtn:Disable()
                if row.deleteBtn.art_pieces then
                    for _, piece in pairs(row.deleteBtn.art_pieces) do
                        piece:SetVertexColor(0.3, 0.3, 0.3, 0.5)
                    end
                end
                if row.deleteBtn.text then
                    row.deleteBtn.text:SetTextColor(0.4, 0.4, 0.4, 1)
                end
            else
                row.deleteBtn:Enable()
                row.deleteBtn:SetTint("normal")
                if row.deleteBtn.text then
                    row.deleteBtn.text:SetTextColor(0.9, 0.9, 0.9, 1)
                end
            end
        else
            row:Hide()
        end
    end
end
