-- ============================================================================
-- RecipeRadar: UI/MainWindow.lua
-- Main window coordinator & component assembler
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.MainWindow = {}

function RR.UI.MainWindow:Initialize()
    if self.frame then return end

    -- 1. Main Container Window Frame
    local f = CreateFrame("Frame", "RecipeRadarFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    f:SetSize(840, 560)
    f:SetPoint("CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    RR.UI.Theme:SkinWindow(f)
    self.frame = f
    f:Hide()

    -- Centered Title Plaque Banner
    self.titlePlaque = RR.UI.Theme:CreateTitlePlaque(f, 420, 38, RR.NAME)
    self.titlePlaque:SetPoint("TOP", f, "TOP", 0, 12)

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        self:Hide()
    end)
    self.closeBtn = closeBtn

    -- 2. Instantiate Sub-Components
    -- Top 3-Row Filter Bar
    self.filterBar = RR.UI.FilterBar:Create(f, function()
        self:Refresh()
    end)

    -- Left Column: Scrollable Recipe List Table
    self.recipeList = RR.UI.RecipeList:Create(f, function(recipeData)
        self:SelectRecipe(recipeData)
    end)

    -- Right Column: Recipe Details & Alt Tracker Pane
    self.detailPane = RR.UI.DetailPane:Create(f)

    -- Footer: Progress Bar
    self.progressBar = RR.UI.ProgressBar:Create(f)

    self.filterBar:UpdateFilterButtons()
end

function RR.UI.MainWindow:IsShown()
    return (self.frame ~= nil and self.frame:IsShown() == true)
end

function RR.UI.MainWindow:Hide()
    if self.frame then
        self.frame:Hide()
        if RR.UI.Dropdown then
            RR.UI.Dropdown:Hide()
        end
    end
end

function RR.UI.MainWindow:Show()
    if not self.frame then self:Initialize() end
    self.frame:Show()
    self:Refresh()
end

function RR.UI.MainWindow:Toggle()
    if not self.frame then self:Initialize() end
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function RR.UI.MainWindow:Refresh()
    if not self.frame or not self.frame:IsShown() then return end

    local prof = RR.Scanner.currentProfession or "Tailoring"
    local rawRecipes = RR.DB:GetRecipesForProfession(prof)

    -- Update the 3rd zone button label to match current profession's stored last zone
    if self.filterBar then
        self.filterBar:UpdateLastZoneForCurrentProfession()
    end

    -- Update Title Banner Plaque with profession name in client locale
    local locProfName = RR.DB:GetProfessionDisplayName(prof)
    if self.titlePlaque and self.titlePlaque.SetTitle then
        self.titlePlaque:SetTitle(RR.NAME .. " - " .. locProfName)
    end

    local searchQuery = (self.filterBar and self.filterBar.searchQuery) or ""
    local filtered, counts = RR.Filter:ApplyFilters(rawRecipes, prof, searchQuery)
    self.currentList = filtered

    -- Update Footer Progress Bar
    local curMode = RR.Config:GetFilterSetting("mode") or "missing"
    if self.progressBar then
        local displayCount = (curMode == "known") and counts.known or counts.missing
        self.progressBar:SetProgress(curMode, displayCount, counts.total)
    end

    -- Auto-select first item or maintain selection
    local selectedId = self.selectedRecipe and self.selectedRecipe.id
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
            selectedId = filtered[1].id
        end
    else
        self.selectedRecipe = nil
        selectedId = nil
    end

    -- Render Recipe List
    if self.recipeList then
        self.recipeList:Render(filtered, selectedId)
    end
end

function RR.UI.MainWindow:SelectRecipe(recipeItem)
    if not recipeItem then return end
    self.selectedRecipe = recipeItem

    if RR.Debug then
        local data = recipeItem.data or {}
        local spellId = data.id or recipeItem.id
        local craftedId = spellId and RR.DB and RR.DB:GetCraftedItemId(spellId)
        local recName = data.name and RR.DB:GetLocalizedText(data.name) or "Unknown"
        print(string.format("|cff00ccff[RecipeRadar Debug]|r Selected: '%s' | SpellID=%s | CraftedID=%s", tostring(recName), tostring(spellId), tostring(craftedId)))
    end

    if self.detailPane then
        self.detailPane:Display(recipeItem)
    end

    if self.recipeList then
        self.recipeList:Render(nil, recipeItem.id)
    end
end

-- Backward compatibility delegate for any external callers
function RR.UI.MainWindow:ShowDropdown(anchorBtn, items)
    if RR.UI.Dropdown then
        RR.UI.Dropdown:Show(anchorBtn, items)
    end
end
