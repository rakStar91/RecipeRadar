-- ============================================================================
-- RecipeRadar: Core/Utils.lua
-- Utility functions, TomTom integration & formatters
-- ============================================================================

local RR = RecipeRadar
RR.Utils = {}

--- Adds a waypoint to TomTom if installed
-- @param zoneName string: The zone name
-- @param x number: X coordinate (0-100)
-- @param y number: Y coordinate (0-100)
-- @param title string: Title for the waypoint
function RR.Utils:AddTomTomWaypoint(zoneName, x, y, title)
    if not (x and y and zoneName) then return end
    
    if SlashCmdList["TOMTOM_WAY"] or _G["TomTom"] then
        local cmd = string.format("/way %s %.1f %.1f %s", zoneName, x, y, title or "Recipe Source")
        if SlashCmdList["TOMTOM_WAY"] then
            SlashCmdList["TOMTOM_WAY"](string.format("%s %.1f %.1f %s", zoneName, x, y, title or "Recipe Source"))
        end
        print(RR.COLORS.TEAL .. "RecipeRadar: " .. RR.COLORS.WHITE .. string.format(RR.L["TOMTOM_ADDED"], title or "NPC", zoneName, tostring(x), tostring(y)))
    else
        print(RR.COLORS.ORANGE .. "RecipeRadar: " .. RR.COLORS.WHITE .. "TomTom is not installed! Location: " .. zoneName .. " (" .. tostring(x) .. ", " .. tostring(y) .. ")")
    end
end

--- Formats copper amount to gold/silver/copper string
-- @param copper number: Amount in copper
-- @return string formatted
function RR.Utils:FormatMoney(copper)
    if not copper or copper <= 0 then return "Free" end
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
