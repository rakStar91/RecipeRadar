-- ============================================================================
-- RecipeRadar: Core/Utils.lua
-- Utility functions, TomTom integration & formatters
-- ============================================================================

local RR = RecipeRadar
RR.Utils = {}

--- Registers the given events on a frame, skipping events this client does not know
-- (e.g. WoW Forever has no CRAFT_* events and registering an unknown event raises an error).
-- Known events are registered directly, so real errors are not hidden.
function RR.Utils:RegisterEvents(frame, events)
    local isValid = C_EventUtils and C_EventUtils.IsEventValid
    for _, event in ipairs(events) do
        if not isValid or isValid(event) then
            frame:RegisterEvent(event)
        end
    end
end

--- Returns the hyperlink of an item, or nil while it is not cached.
-- The legacy global is preferred so Classic Era and TBC behave as before; clients that dropped it
-- (WoW Forever) fall back to C_Item.
function RR.Utils:GetItemLink(itemId)
    local getInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if not getInfo then return nil end
    local _, link = getInfo(itemId)
    return link
end

--- Returns the hyperlink of a spell, using the legacy global when the client still has it.
function RR.Utils:GetSpellLink(spellId)
    local getLink = GetSpellLink or (C_Spell and C_Spell.GetSpellLink)
    return getLink and getLink(spellId) or nil
end

--- Adds a waypoint to TomTom if installed
-- Robustly handles (title, zoneName, x, y) or (zoneName, x, y, title)
function RR.Utils:AddTomTomWaypoint(arg1, arg2, arg3, arg4)
    local title, zoneName, numX, numY

    if tonumber(arg2) and tonumber(arg3) then
        -- Called as (zoneName, x, y, title)
        zoneName = tostring(arg1 or "")
        numX = tonumber(arg2)
        numY = tonumber(arg3)
        title = tostring(arg4 or "Recipe Source")
    else
        -- Called as (title, zoneName, x, y)
        title = tostring(arg1 or "Recipe Source")
        zoneName = tostring(arg2 or "")
        numX = tonumber(arg3)
        numY = tonumber(arg4)
    end

    if not (numX and numY and zoneName and zoneName ~= "") then return end

    -- Normalize zone name: strip leading German/English articles ("Die ", "Der ", "Das ", "The ") as safety guard
    local cleanZone = zoneName:gsub("^[Dd][ieaer]+%s+", ""):gsub("^[Tt]he%s+", "")
    local added = false

    local TomTom = _G["TomTom"]
    if TomTom and TomTom.AddWaypoint and TomTom.NameToMapId then
        local mapId = TomTom.NameToMapId[zoneName] or TomTom.NameToMapId[cleanZone]
        if not mapId then
            local lz = zoneName:lower():gsub("[%s]", "")
            local clz = cleanZone:lower():gsub("[%s]", "")
            for name, id in pairs(TomTom.NameToMapId) do
                local ln = name:lower():gsub("[%s]", "")
                if ln == lz or ln == clz or ln:find(clz, 1, true) then
                    mapId = type(id) == "table" and id[1] or id
                    break
                end
            end
        end

        if mapId then
            if type(mapId) == "table" then mapId = mapId[1] end
            TomTom:AddWaypoint(mapId, numX / 100, numY / 100, {
                title = title,
                from = "RecipeRadar",
            })
            added = true
        end
    end

    if not added and SlashCmdList and SlashCmdList["TOMTOM_WAY"] then
        SlashCmdList["TOMTOM_WAY"](string.format("%s %.1f %.1f %s", cleanZone, numX, numY, title))
        added = true
    end

    if added then
        print(RR.COLORS.TEAL .. "RecipeRadar: " .. RR.COLORS.WHITE .. string.format(RR.L["TOMTOM_ADDED"], title, cleanZone, string.format("%.1f", numX), string.format("%.1f", numY)))
    else
        print(RR.COLORS.ORANGE .. "RecipeRadar: " .. RR.COLORS.WHITE .. RR.L["TOMTOM_NOT_INSTALLED"] .. zoneName .. " (" .. string.format("%.1f", numX) .. ", " .. string.format("%.1f", numY) .. ")")
    end
end

--- Formats copper amount to gold/silver/copper string
-- @param copper number: Amount in copper
-- @return string formatted
function RR.Utils:FormatMoney(copper)
    if not copper or copper <= 0 then return RR.L["FREE"] end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100

    local str = ""
    if g > 0 then str = str .. g .. "|cffffd700g|r " end
    if s > 0 or g > 0 then str = str .. s .. "|cffc7c7cfs|r " end
    if c > 0 or (g == 0 and s == 0) then str = str .. c .. "|cffeda55fc|r" end
    return str
end

--- Checks if a table contains a value
function RR.Utils:TableContains(tbl, val)
    if not tbl then return false end
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end
