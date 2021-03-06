
local pID = UnitGUID("player")
local healedTotal, overhealTotal, unitnames, colors = {}, {}, {}, {}, {}, {}
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


local obj = LibStub("LibDataBroker-1.1"):NewDataObject("picoHeal", {type = "data source", text = "0% OH"})


local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
f:RegisterEvent("PLAYER_LOGIN")


function f:PLAYER_LOGIN()
	pID = UnitGUID("player")
	unitnames[pID] = "|cff"..colors[select(2, UnitClass("player"))]..UnitName("player").."|r"

	self:GROUP_MEMBERS_CHANGED()

	self:RegisterEvent("GROUP_MEMBERS_CHANGED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function f:GROUP_MEMBERS_CHANGED()
	for i=1,GetNumSubgroupMembers() do
		local id = UnitGUID("party"..i)
		if id and not unitnames[id] then
			local _, color = UnitClass("party"..i)
			color = colors[color or "PRIEST"]
			unitnames[id] = "|cff"..color..UnitName("party"..i).."|r"
		end
	end
	for i=1,GetNumGroupMembers() do
		local id = UnitGUID("raid"..i)
		if id and not unitnames[id] then
			local _, color = UnitClass("raid"..i)
			color = colors[color or "PRIEST"]
			unitnames[id] = "|cff"..color..UnitName("raid"..i).."|r"
		end
	end
end


function f:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if event ~= "SPELL_HEAL" and event ~= "SPELL_PERIODIC_HEAL" then return end

	local spellId, spellName, spellSchool, amount, overheal, critical = ...

	if unitnames[sourceGUID] then healedTotal[sourceGUID], overhealTotal[sourceGUID] = (healedTotal[sourceGUID] or 0) + amount, (overhealTotal[sourceGUID] or 0) + overheal end
	if sourceGUID == pID then obj.text = string.format("%d%% OH", 100*(overhealTotal[pID] or 0)/(healedTotal[pID] or 1)) end
end


function obj:OnClick()
	for i in pairs(healedTotal) do healedTotal[i] = nil end
	for i in pairs(overhealTotal) do overhealTotal[i] = nil end
	obj.text = "0% OH"
end


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


local tip = LibStub("tektip-1.0").new(4)
function obj.OnEnter(self)
	tip:AnchorTo(self)

	tip:AddLine("picoHeal")
	tip:AddLine(" ")

	tip:AddMultiLine("Player", "Healed", "Overheal", "OH%")
	local th, oh = healedTotal[pID] or 0, overhealTotal[pID] or 0
	local h = th - oh
	tip:AddMultiLine(unitnames[pID] or UnitName("player"), h, oh, string.format("%d%%", (th > 0) and oh/th*100 or 0), nil,nil,nil, 1,1,1, 1,1,1, 1,1,1)
	for id in pairs(healedTotal) do
		if id ~= pID then
			local th, oh = healedTotal[id] or 0, overhealTotal[id] or 0
			local h = th - oh
			tip:AddMultiLine(unitnames[id] or "???", h, oh, string.format("%d%%", (th > 0) and oh/th*100 or 0), nil,nil,nil, 1,1,1, 1,1,1, 1,1,1)
		end
	end

	tip:Show()
end


function obj.OnLeave() tip:Hide() end
