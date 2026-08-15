-- ============================================================================
-- RecipeRadar: Core/Utils.lua
-- Utility functions, TomTom integration & formatters
-- ============================================================================

local RR = RecipeRadar
RR.Utils = {}

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
    
    if SlashCmdList and SlashCmdList["TOMTOM_WAY"] then
        SlashCmdList["TOMTOM_WAY"](string.format("%s %.1f %.1f %s", zoneName, numX, numY, title))
        print(RR.COLORS.TEAL .. "RecipeRadar: " .. RR.COLORS.WHITE .. string.format(RR.L["TOMTOM_ADDED"], title, zoneName, string.format("%.1f", numX), string.format("%.1f", numY)))
    elseif _G["TomTom"] and _G["TomTom"].AddWaypoint then
        -- Direct TomTom API fallback if slash command differs
        print(RR.COLORS.TEAL .. "RecipeRadar: " .. RR.COLORS.WHITE .. string.format(RR.L["TOMTOM_ADDED"], title, zoneName, string.format("%.1f", numX), string.format("%.1f", numY)))
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
