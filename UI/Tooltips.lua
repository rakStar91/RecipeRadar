-- ============================================================================
-- RecipeRadar: UI/Tooltips.lua
-- Hooks item tooltips to display knowledge across alts on this realm
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.Tooltips = {}

function RR.UI.Tooltips:Initialize()
    local function OnTooltipSetItem(tooltip)
        local profile = RR.Config:GetProfile()
        if not (profile and profile.tooltipAlts) then return end

        local _, itemLink = tooltip:GetItem()
        if not itemLink then return end

        local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
        if not itemId then return end

        local itemData = RR.DB:GetItem(itemId)
        if not itemData then return end

        -- Extract profession and spell info
        local profName = itemData.profession or "Tailoring"
        local spellId = itemData.creates or itemData.teaches or itemData.id

        local alts = RR.AltTracker:GetAltStatusForRecipe(profName, spellId, itemData.name and itemData.name["English"])
        if alts and #alts > 0 then
            tooltip:AddLine(" ")
            tooltip:AddLine(RR.COLORS.TITLE .. "RecipeRadar (Alts):")
            for _, alt in ipairs(alts) do
                local statusStr = alt.isKnown and (RR.COLORS.GREEN .. "✓ Known") or (RR.COLORS.RED .. "✗ Missing")
                tooltip:AddDoubleLine(RR.COLORS.WHITE .. alt.name .. " (" .. alt.class .. "):", statusStr)
            end
            tooltip:Show()
        end
    end

    if GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
    if ItemRefTooltip and ItemRefTooltip.HookScript then
        ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
end
