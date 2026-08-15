-- ============================================================================
-- RecipeRadar: UI/Tooltips.lua
-- Hooks item and spell tooltips to display knowledge across alts on this realm
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.Tooltips = {}

function RR.UI.Tooltips:Initialize()
    local function AppendAltLines(tooltip, profName, spellId, recipeName)
        if not (profName and (spellId or recipeName)) then return end
        local alts = RR.AltTracker:GetAltStatusForRecipe(profName, spellId, recipeName)
        if alts and #alts > 0 then
            tooltip._rr_hasAppended = true
            tooltip:AddLine(" ")
            tooltip:AddLine(RR.COLORS.TITLE .. "RecipeRadar (" .. (RR.L["ALTS"] or "Alts") .. "):")
            for _, alt in ipairs(alts) do
                local classKey = alt.class or "WARRIOR"
                local classIcon = ""
                local cCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classKey]
                if cCoords then
                    local left = math.floor(cCoords[1] * 256)
                    local right = math.floor(cCoords[2] * 256)
                    local top = math.floor(cCoords[3] * 256)
                    local bottom = math.floor(cCoords[4] * 256)
                    classIcon = string.format("|TInterface\\WorldStateFrame\\Icons-Classes:13:13:0:0:256:256:%d:%d:%d:%d|t ", left, right, top, bottom)
                end

                local cColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
                local coloredName = alt.name
                if cColor then
                    coloredName = string.format("|cff%02x%02x%02x%s|r", cColor.r * 255, cColor.g * 255, cColor.b * 255, alt.name)
                end

                local statusStr
                if alt.isKnown then
                    statusStr = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12:12:0:0|t |cff33ff33" .. (RR.L["LEARNED"] or "Gelernt") .. "|r"
                else
                    statusStr = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12:12:0:0|t |cffff4444" .. (RR.L["MODE_MISSING"] or "Fehlend") .. "|r"
                end

                tooltip:AddDoubleLine(classIcon .. coloredName .. ":", statusStr)
            end
            tooltip:Show()
        end
    end

    local function OnTooltipSetItem(tooltip)
        local profile = RR.Config:GetProfile()
        if not (profile and profile.tooltipAlts) then return end
        if tooltip._rr_hasAppended then return end

        local _, itemLink = tooltip:GetItem()
        if not itemLink then return end

        local itemId = tonumber(string.match(itemLink, "item:(%d+)"))
        if not itemId then return end

        -- Check if this item is a recipe / pattern or a crafted item from any profession
        local skillInfo = RR.DB:GetSkillByItemId(itemId)
        local profName, spellId, recipeName

        if skillInfo then
            profName = skillInfo.profession
            spellId = skillInfo.spellId
            recipeName = RR.DB:GetLocalizedText(skillInfo.skill.name)
        else
            local itemData = RR.DB:GetItem(itemId)
            if itemData and itemData.profession then
                profName = itemData.profession
                spellId = itemData.creates or itemData.teaches or itemData.id
                recipeName = itemData.name and RR.DB:GetLocalizedText(itemData.name)
            end
        end

        AppendAltLines(tooltip, profName, spellId, recipeName)
    end

    local function OnTooltipSetSpell(tooltip)
        local profile = RR.Config:GetProfile()
        if not (profile and profile.tooltipAlts) then return end
        if tooltip._rr_hasAppended then return end

        local _, spellId = tooltip:GetSpell()
        if not spellId then return end

        local skillInfo = RR.DB:GetSkillBySpellId(spellId)
        if not skillInfo then return end

        local profName = skillInfo.profession
        local recipeName = RR.DB:GetLocalizedText(skillInfo.skill.name)
        AppendAltLines(tooltip, profName, spellId, recipeName)
    end

    local function HookTooltip(tt)
        if not tt then return end
        if tt.HookScript then
            tt:HookScript("OnTooltipSetItem", OnTooltipSetItem)
            tt:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
            tt:HookScript("OnTooltipCleared", function(self)
                self._rr_hasAppended = nil
            end)
        end
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
    if ShoppingTooltip1 then HookTooltip(ShoppingTooltip1) end
    if ShoppingTooltip2 then HookTooltip(ShoppingTooltip2) end
end
