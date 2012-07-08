﻿--Ion, a World of Warcraft® user interface addon.
--Copyright© 2006-2012 Connor H. Chenoweth, aka Maul - All rights reserved.

local ION, GDB, CDB, PEW, player, realm, barGDB, barCDB = Ion

ION.BAR = setmetatable({}, { __index = CreateFrame("CheckButton") })

ION.HANDLER = setmetatable({}, { __index = CreateFrame("Frame") })

local BAR, BUTTON, HANDLER = ION.BAR, ION.BUTTON, ION.HANDLER

local STORAGE = CreateFrame("Frame", nil, UIParent)

local L = LibStub("AceLocale-3.0"):GetLocale("Ion")

local BARIndex, BARNameIndex, BTNIndex = ION.BARIndex, ION.BARNameIndex, ION.BTNIndex

local MAS = ION.MANAGED_ACTION_STATES
local MBS = ION.MANAGED_BAR_STATES

local InCombatLockdown = _G.InCombatLockdown
local tsort = table.sort

local alphaDir, alphaTimer = 0, 0

local autoHideIndex, alphaupIndex = {}, {}

local alphaUps = {
	L.OFF,
	L.ALPHAUP_MOUSEOVER,
	L.ALPHAUP_BATTLE,
	L.ALPHAUP_BATTLEMOUSE,
	L.ALPHAUP_RETREAT,
	L.ALPHAUP_RETREATMOUSE,
}

local barShapes = {
	L.BAR_SHAPE1,
	L.BAR_SHAPE2,
	L.BAR_SHAPE3,
}

ION.barGDEF = {

	name = "",

	objectList = "",

	hidestates = ":",

	point = "BOTTOM",
	x = 0,
	y = 190,

	shape = 1,
	columns = false,
	scale = 1,
	alpha = 1,
	alphaUp = 1,
	fadeSpeed = 0.5,

	barStrata = "MEDIUM",
	objectStrata = "LOW",

	padH = 0,
	padV = 0,
	arcStart = 0,
	arcLength = 359,

	snapTo = true,
	snapToPad = 0,
	snapToPoint = false,
	snapToFrame = false,

	autoHide = false,
	showGrid = false,
}

ION.barCDEF = {

	barLock = false,
	barLockAlt = false,
	barLockCtrl = false,
	barLockShift = false,

	tooltips = true,
	tooltipsEnhanced = true,
	tooltipsCombat = false,

	spellGlow = true,
	spellGlowDef = true,
	spellGlowAlt = false,

	bindText = true,
	macroText = true,
	countText = true,

	cdText = false,
	cdAlpha = false,
	auraText = false,
	auraInd = false,

	upClicks = true,
	downClicks = false,

	rangeInd = true,

	homestate = true,
	paged = false,
	stance = false,
	prowl = false,
	stealth = false,
	reaction = false,
	combat = false,
	group = false,
	pet = false,
	fishing = false,
	vehicle = false,
	alt = false,
	ctrl = false,
	shift = false,

	custom = false,
	customRange = false,
	customNames = false,

	remap = false,

	conceal = false,

	dualSpec = false,

}

local gDef = {

	[1] = {

		snapTo = false,
		snapToFrame = false,
		snapToPoint = false,
		point = "BOTTOM",
		x = 0,
		y = 55,
	},

	[2] = {

		snapTo = false,
		snapToFrame = false,
		snapToPoint = false,
		point = "BOTTOM",
		x = 0,
		y = 100,
	},
}

local function round(num, idp)

      local mult = 10^(idp or 0)
      return math.floor(num * mult + 0.5) / mult

end

local function IsMouseOverSelfOrWatchFrame(frame)

	if (frame:IsMouseOver()) then
		return true
	end

	if (frame.watchframes) then
		for k,v in pairs(frame.watchframes) do
			if (v:IsMouseOver() and v:IsVisible()) then
				return true
			end
		end
	end

	return false
end

local function controlOnUpdate(self, elapsed)

	for k,v in pairs(autoHideIndex) do
		if (v~=nil) then

			if (k:IsShown()) then
				v:SetAlpha(1)
			else

				if (IsMouseOverSelfOrWatchFrame(k)) then
					if (v:GetAlpha() < k.alpha) then
						if (v:GetAlpha()+v.fadeSpeed <= 1) then
							v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
						else
							v:SetAlpha(1)
						end
					else
						k.seen = 1;
					end
				end

				if (not IsMouseOverSelfOrWatchFrame(k)) then
					if (v:GetAlpha() > 0) then
						if (v:GetAlpha()-v.fadeSpeed >= 0) then
							v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
						else
							v:SetAlpha(0)
						end
					else
						k.seen = 0;
					end
				end
			end
		end
	end

	for k,v in pairs(alphaupIndex) do
		if (v~=nil) then
			if (k.alphaUp == alphaUps[3] or k.alphaUp == alphaUps[4]) then

				if (InCombatLockdown()) then

					if (v:GetAlpha() < 1) then
						if (v:GetAlpha()+v.fadeSpeed <= 1) then
							v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
						else
							v:SetAlpha(1)
						end
					else
						k.seen = 1;
					end

				else
					if (k.alphaUp == alphaUps[4]) then

						if (IsMouseOverSelfOrWatchFrame(k)) then
							if (v:GetAlpha() < 1) then
								if (v:GetAlpha()+v.fadeSpeed <= 1) then
									v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
								else
									v:SetAlpha(1)
								end
							else
								k.seen = 1;
							end
						else
							if (v:GetAlpha() > k.alpha) then
								if (v:GetAlpha()-v.fadeSpeed >= 0) then
									v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
								else
									v:SetAlpha(k.alpha)
								end
							else
								k.seen = 0;
							end
						end
					else
						if (v:GetAlpha() > k.alpha) then
							if (v:GetAlpha()-v.fadeSpeed >= 0) then
								v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
							else
								v:SetAlpha(k.alpha)
							end
						else
							k.seen = 0;
						end
					end
				end

			elseif (k.alphaUp == alphaUps[5] or k.alphaUp == alphaUps[6]) then

				if (not InCombatLockdown()) then

					if (v:GetAlpha() < 1) then
						if (v:GetAlpha()+v.fadeSpeed <= 1) then
							v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
						else
							v:SetAlpha(1)
						end
					else
						k.seen = 1;
					end

				else
					if (k.alphaUp == alphaUps[6]) then

						if (IsMouseOverSelfOrWatchFrame(k)) then
							if (v:GetAlpha() < 1) then
								if (v:GetAlpha()+v.fadeSpeed <= 1) then
									v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
								else
									v:SetAlpha(1)
								end
							else
								k.seen = 1;
							end
						else
							if (v:GetAlpha() > k.alpha) then
								if (v:GetAlpha()-v.fadeSpeed >= 0) then
									v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
								else
									v:SetAlpha(k.alpha)
								end
							else
								k.seen = 0;
							end
						end
					else
						if (v:GetAlpha() > k.alpha) then
							if (v:GetAlpha()-v.fadeSpeed >= 0) then
								v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
							else
								v:SetAlpha(k.alpha)
							end
						else
							k.seen = 0;
						end
					end
				end

			elseif (k.alphaUp == alphaUps[2]) then

				if (IsMouseOverSelfOrWatchFrame(k)) then
					if (v:GetAlpha() < 1) then
						if (v:GetAlpha()+v.fadeSpeed <= 1) then
							v:SetAlpha(v:GetAlpha()+v.fadeSpeed)
						else
							v:SetAlpha(1)
						end
					else
						k.seen = 1;
					end
				else
					if (v:GetAlpha() > k.alpha) then
						if (v:GetAlpha()-v.fadeSpeed >= 0) then
							v:SetAlpha(v:GetAlpha()-v.fadeSpeed)
						else
							v:SetAlpha(k.alpha)
						end
					else
						k.seen = 0;
					end
				end
			end
		end
	end
end

function HANDLER:SetHidden(bar, show, hide)

	for k,v in pairs(bar.vis) do
		if (v.registered) then
			return
		end
	end

	local isAnchorChild = self:GetAttribute("isAnchorChild")

	if (not hide and not isAnchorChild and (show or bar:IsVisible())) then

		self:Show()
	else
		if (bar.cdata.conceal) then
			self:Hide()
		elseif (not bar.gdata.barLink and not isAnchorChild) then
			self:Show()
		end
	end
end

function HANDLER:SetAutoHide(bar)

	if (bar.gdata.autoHide) then
		autoHideIndex[bar] = self; self.fadeSpeed = bar.gdata.fadeSpeed
	else
		autoHideIndex[bar] = nil
	end

	if (bar.gdata.alphaUp == L.OFF) then
		alphaupIndex[bar] = nil
	else
		alphaupIndex[bar] = self; self.fadeSpeed = bar.gdata.fadeSpeed
	end
end

function HANDLER:AddVisibilityDriver(bar, state, conditions)

	if (MBS[state]) then
		RegisterStateDriver(self, state, conditions)
	end

	if (self:GetAttribute("activestates"):find(state)) then
		self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-"..state)..";"))
	else
		self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-"..state)..";")
	end

	self:SetAttribute("state-"..state, self:GetAttribute("state-"..state))

	bar.vis[state].registered = true

end

function HANDLER:ClearVisibilityDriver(bar, state)

	UnregisterStateDriver(self, state)

	self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", ""))
	self:SetAttribute("state-current", "homestate")
	self:SetAttribute("state-last", "homestate")

	bar.vis[state].registered = false

end

function HANDLER:UpdateVisibility(bar)

	for state, values in pairs(MBS) do

		if (bar.gdata.hidestates:find(":"..state)) then

			if (not bar.vis[state] or not bar.vis[state].registered) then

				if (not bar.vis[state]) then
					bar.vis[state] = {}
				end

				if (state == "stance" and bar.gdata.hidestates:find(":stance8")) then
					self:AddVisibilityDriver(bar, state, "[stance:2/3,stealth] stance8; "..values.states)
				else
					self:AddVisibilityDriver(bar, state, values.states)
				end
			end

		elseif (bar.vis[state] and bar.vis[state].registered) then

			self:ClearVisibilityDriver(bar, state)

		end
	end
end

function HANDLER:BuildStateMap(bar, remapState)

	local statemap, state, map, remap, homestate = "", remapState:gsub("paged", "bar")

	for states in gmatch(bar.cdata.remap, "[^;]+") do

		map, remap = (":"):split(states)

		if (not homestate) then
			statemap = statemap.."["..state..":"..map.."] homestate; "; homestate = true
		else
			local newstate = remapState..remap

			if (MAS[remapState] and
			    MAS[remapState].homestate and
			    MAS[remapState].homestate == newstate) then
				statemap = statemap.."["..state..":"..map.."] homestate; "
			else
				statemap = statemap.."["..state..":"..map.."] "..newstate.."; "
			end
		end

		if (map == "1" and bar.cdata.prowl and remapState == "stance") then
			statemap = statemap.."[stance:2/3,stealth] stance8; "
		end
	end

	statemap = gsub(statemap, "; $", "")

	return statemap
end

function HANDLER:AddStates(bar, state, conditions)

	if (MAS[state]) then
		RegisterStateDriver(self, state, conditions)
	end

	if (MAS[state].homestate) then
		self:SetAttribute("handler-homestate", MAS[state].homestate)
	end

	bar[state].registered = true

end

function HANDLER:ClearStates(bar, state)

	local clearState

	if (state ~= "homestate") then

		if (MAS[state].homestate) then
			self:SetAttribute("handler-homestate", nil)
		end

		self:SetAttribute("state-"..state, nil)

		UnregisterStateDriver(self, state)

		bar[state].registered = false
	end

	self:SetAttribute("state-current", "homestate")
	self:SetAttribute("state-last", "homestate")

end

function HANDLER:UpdateStates(bar)

	for state, values in pairs(MAS) do

		if (bar.cdata[state]) then

			if (not bar[state] or not bar[state].registered) then

				local statemap

				if (not bar[state]) then
					bar[state] = {}
				end

				if (bar.cdata.remap and (state == "paged" or state == "stance")) then
					statemap = self:BuildStateMap(bar, state)
				end

				if (state == "custom" and bar.cdata.custom) then

					self:AddStates(bar, state, bar.cdata.custom)

				elseif (statemap) then

					self:AddStates(bar, state, statemap)

				else
					self:AddStates(bar, state, values.states)

				end
			end

		elseif (bar[state] and bar[state].registered) then

			self:ClearStates(bar, state)

		end
	end
end

function BAR:CreateDriver()

	local driver = CreateFrame("Frame", "IonBarDriver"..self:GetID(), UIParent, "SecureHandlerStateTemplate")

	setmetatable(driver, { __index = HANDLER })

	driver:SetID(self:GetID())

	driver:SetAttribute("_onstate-paged", [[

						local state = self:GetAttribute("state-paged"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-paged")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-paged")..";")
							end

							control:ChildUpdate("paged", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-stance", [[

						local state = self:GetAttribute("state-stance"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-stance")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-stance")..";")
							end

							control:ChildUpdate("stance", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-pet", [[

						local state = self:GetAttribute("state-pet"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-pet")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-pet")..";")
							end

							control:ChildUpdate("pet", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-stealth", [[

						local state = self:GetAttribute("state-stealth"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-stealth")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-stealth")..";")
							end

							control:ChildUpdate("stealth", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-reaction", [[

						local state = self:GetAttribute("state-reaction"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-reaction")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-reaction")..";")
							end

							control:ChildUpdate("reaction", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-combat", [[

						local state = self:GetAttribute("state-combat"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-combat")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-combat")..";")
							end

							control:ChildUpdate("combat", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-group", [[

						local state = self:GetAttribute("state-group"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-group")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-group")..";")
							end

							control:ChildUpdate("group", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-fishing", [[

						local state = self:GetAttribute("state-fishing"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-fishing")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-fishing")..";")
							end

							control:ChildUpdate("fishing", self:GetAttribute("activestates"))
						end
						]])

	driver:SetAttribute("_onstate-vehicle", [[

						local state = self:GetAttribute("state-vehicle"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-vehicle")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-vehicle")..";")
							end

							control:ChildUpdate("vehicle", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-alt", [[

						local state = self:GetAttribute("state-alt"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-alt")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-alt")..";")
							end

							control:ChildUpdate("alt", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-ctrl", [[

						local state = self:GetAttribute("state-ctrl"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-ctrl")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-ctrl")..";")
							end

							control:ChildUpdate("ctrl", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-shift", [[

						local state = self:GetAttribute("state-shift"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-shift")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-shift")..";")
							end

							control:ChildUpdate("shift", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("_onstate-custom", [[

						local state = self:GetAttribute("state-custom"):match("%a+")

						if (state) then

							if (self:GetAttribute("activestates"):find(state)) then
								self:SetAttribute("activestates", self:GetAttribute("activestates"):gsub(state.."%d+;", self:GetAttribute("state-custom")..";"))
							else
								self:SetAttribute("activestates", self:GetAttribute("activestates")..self:GetAttribute("state-custom")..";")
							end

							control:ChildUpdate("custom", self:GetAttribute("activestates"))
						end

						]])

	driver:SetAttribute("activestates", "")

	driver:HookScript("OnAttributeChanged",

			function(self,name,value)

		end)

	driver:SetAllPoints(self)

	self.driver = driver; driver.bar = self

end

function BAR:CreateHandler()

	local handler = CreateFrame("Frame", "IonBarHandler"..self:GetID(), self.driver, "SecureHandlerStateTemplate")

	setmetatable(handler, { __index = HANDLER })

	handler:SetID(self:GetID())

	handler:SetAttribute("_onstate-paged", [[

						self:SetAttribute("assertstate", "paged")

						self:SetAttribute("state-last", self:GetAttribute("state-paged"))

						self:SetAttribute("state-current", self:GetAttribute("state-paged"))

						if (self:GetAttribute("state-paged") and self:GetAttribute("state-paged") == self:GetAttribute("handler-homestate")) then
							control:ChildUpdate("paged", "homestate:"..self:GetAttribute("state-paged"))
						else
							control:ChildUpdate("paged", self:GetAttribute("state-paged"))
						end

						]])

	handler:SetAttribute("_onstate-stance", [[

						self:SetAttribute("assertstate", "stance")

						self:SetAttribute("state-last", self:GetAttribute("state-stance"))

						self:SetAttribute("state-current", self:GetAttribute("state-stance"))

						if (self:GetAttribute("state-stance") and self:GetAttribute("state-stance") == self:GetAttribute("handler-homestate")) then
							control:ChildUpdate("stance", "homestate:"..self:GetAttribute("state-stance"))
						else
							control:ChildUpdate("stance", self:GetAttribute("state-stance"))
						end

						]])

	handler:SetAttribute("_onstate-pet", [[

						self:SetAttribute("assertstate", "pet")

						self:SetAttribute("state-last", self:GetAttribute("state-pet"))

						self:SetAttribute("state-current", self:GetAttribute("state-pet"))

						if (self:GetAttribute("state-pet") and self:GetAttribute("state-pet") == self:GetAttribute("handler-homestate")) then
							control:ChildUpdate("pet", "homestate:"..self:GetAttribute("state-pet"))
						else
							control:ChildUpdate("pet", self:GetAttribute("state-pet"))
						end

						]])

	handler:SetAttribute("_onstate-stealth", [[

						self:SetAttribute("assertstate", "stealth")

						if (self:GetAttribute("state-stealth") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-stealth"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("stealth", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-stealth", nil)
						else
							self:SetAttribute("state-last-stealth", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-stealth"))
							self:SetAttribute("state-current", self:GetAttribute("state-stealth"))
							control:ChildUpdate("stealth", self:GetAttribute("state-stealth"))
						end

						]])

	handler:SetAttribute("_onstate-reaction", [[

						self:SetAttribute("assertstate", "reaction")

						if (self:GetAttribute("state-reaction") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-reaction"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("reaction", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-reaction", nil)
						else
							self:SetAttribute("state-last-reaction", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-reaction"))
							self:SetAttribute("state-current", self:GetAttribute("state-reaction"))
							control:ChildUpdate("reaction", self:GetAttribute("state-reaction"))
						end

						]])

	handler:SetAttribute("_onstate-combat", [[

						self:SetAttribute("assertstate", "combat")

						if (self:GetAttribute("state-combat") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-combat"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("combat", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-combat", nil)
						else
							self:SetAttribute("state-last-combat", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-combat"))
							self:SetAttribute("state-current", self:GetAttribute("state-combat"))
							control:ChildUpdate("combat", self:GetAttribute("state-combat"))
						end

						]])

	handler:SetAttribute("_onstate-group", [[

						self:SetAttribute("assertstate", "group")

						if (self:GetAttribute("state-group") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-group"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("group", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-group", nil)
						else
							self:SetAttribute("state-last-group", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-group"))
							self:SetAttribute("state-current", self:GetAttribute("state-group"))
							control:ChildUpdate("group", self:GetAttribute("state-group"))
						end

						]])

	handler:SetAttribute("_onstate-fishing", [[

						self:SetAttribute("assertstate", "fishing")

						if (self:GetAttribute("state-fishing") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-fishing"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("fishing", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-fishing", nil)
						else
							self:SetAttribute("state-last-fishing", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-fishing"))
							self:SetAttribute("state-current", self:GetAttribute("state-fishing"))
							control:ChildUpdate("fishing", self:GetAttribute("state-fishing"))
						end

						]])

	handler:SetAttribute("_onstate-vehicle", [[

						self:SetAttribute("assertstate", "vehicle")

						if (self:GetAttribute("state-vehicle") == "laststate") then
							self:SetAttribute("state-last", self:GetAttribute("state-last-vehicle"))
							self:SetAttribute("state-current", self:GetAttribute("state-last"))
							control:ChildUpdate("vehicle", self:GetAttribute("state-last") or "homestate")
							self:SetAttribute("state-last-vehicle", nil)
						else
							self:SetAttribute("state-last-vehicle", self:GetAttribute("state-last"))
							self:SetAttribute("state-last", self:GetAttribute("state-vehicle"))
							self:SetAttribute("state-current", self:GetAttribute("state-vehicle"))
							control:ChildUpdate("vehicle", self:GetAttribute("state-vehicle"))
						end

						]])

	handler:SetAttribute("_onstate-alt", [[

						self:SetAttribute("assertstate", "alt")

						if (self:GetAttribute("state-alt") == "laststate") then
							self:SetAttribute("state-current", self:GetAttribute("state-last") or "homestate")
							control:ChildUpdate("alt", self:GetAttribute("state-last") or "homestate")
						else
							self:SetAttribute("state-current", self:GetAttribute("state-alt"))
							control:ChildUpdate("alt", self:GetAttribute("state-alt"))
						end

						]])

	handler:SetAttribute("_onstate-ctrl", [[

						self:SetAttribute("assertstate", "ctrl")

						if (self:GetAttribute("state-ctrl") == "laststate") then
							self:SetAttribute("state-current", self:GetAttribute("state-last") or "homestate")
							control:ChildUpdate("ctrl", self:GetAttribute("state-last") or "homestate")
						else
							self:SetAttribute("state-current", self:GetAttribute("state-ctrl"))
							control:ChildUpdate("ctrl", self:GetAttribute("state-ctrl"))
						end

						]])

	handler:SetAttribute("_onstate-shift", [[

						self:SetAttribute("assertstate", "shift")

						if (self:GetAttribute("state-shift") == "laststate") then
							self:SetAttribute("state-current", self:GetAttribute("state-last") or "homestate")
							control:ChildUpdate("shift", self:GetAttribute("state-last") or "homestate")
						else
							self:SetAttribute("state-current", self:GetAttribute("state-shift"))
							control:ChildUpdate("shift", self:GetAttribute("state-shift"))
						end

						]])

	handler:SetAttribute("_onstate-custom", [[

						self:SetAttribute("assertstate", "custom")

						self:SetAttribute("state-last", self:GetAttribute("state-custom"))

						self:SetAttribute("state-current", self:GetAttribute("state-custom"))

						control:ChildUpdate("alt", self:GetAttribute("state-custom"))

						]])

	handler:SetAttribute("_onstate-current", [[ self:SetAttribute("activestate", self:GetAttribute("state-current") or "homestate") ]])

	handler:SetAttribute("activestate", "homestate")

	handler:SetAttribute("state-last", "homestate")

	handler:HookScript("OnAttributeChanged",

			function(self,name,value)

			end)

	--handler:SetAttribute("_onshow", [[ control:ChildUpdate("onshow", "show") ]])

	--handler:SetAttribute("_onhide", [[ control:ChildUpdate("onshow", "hide") ]])

	handler:SetAttribute("_childupdate", [[

			if (not self:GetAttribute("editmode")) then

				self:SetAttribute("vishide", false)

				if (self:GetAttribute("hidestates")) then
					for state in gmatch(message, "[^;]+") do
						for hidestate in gmatch(self:GetAttribute("hidestates"), "[^:]+") do
							if (state == hidestate) then
								self:Hide(); self:SetAttribute("vishide", true)
							end
						end
					end
				end

				if (not self:IsShown() and not self:GetAttribute("vishide")) then
					self:Show()
				end
			end

	]] )

	handler:SetAllPoints(self)

	self.handler = handler; handler.bar = self

end

function BAR:Update(show, hide)

	local handler, driver = self.handler, self.driver

	self.elapsed = 0;
	self.alpha = self.gdata.alpha;
	self.alphaUp = self.gdata.alphaUp

	if (self.stateschanged) then

		handler:UpdateStates(self)

		self.stateschanged = nil
	end

	if (self.vischanged) then

		handler:SetAttribute("hidestates", self.gdata.hidestates)

		driver:UpdateVisibility(self)

		self.vischanged = nil
	end

	if (self.countChanged) then

		self:UpdateObjectData()

		self.countChanged = nil

	end

	handler:SetHidden(self, show, hide)

	handler:SetAutoHide(self)

	self.text:SetText(self.gdata.name)

	handler:SetAlpha(self.gdata.alpha)

	self:SaveData()

	if (not hide and IonBarEditor and IonBarEditor:IsVisible()) then
		ION:UpdateBarGUI()
	end
end

function BAR:GetPosition(oFrame)

	local relFrame, point

	if (oFrame) then
		relFrame = oFrame
	else
		relFrame = self:GetParent()
	end

	local s = self:GetScale()
	local w, h = relFrame:GetWidth()/s, relFrame:GetHeight()/s
	local x, y = self:GetCenter()
	local vert = (y>h/1.5) and "TOP" or (y>h/3) and "CENTER" or "BOTTOM"
	local horz = (x>w/1.5) and "RIGHT" or (x>w/3) and "CENTER" or "LEFT"

	if (vert == "CENTER") then
		point = horz
	elseif (horz == "CENTER") then
		point = vert
	else
		point = vert..horz
	end

	if (vert:find("CENTER")) then y = y - h/2 end
	if (horz:find("CENTER")) then x = x - w/2 end
	if (point:find("RIGHT")) then x = x - w end
	if (point:find("TOP")) then y = y - h end

	return point, x, y
end

function BAR:SetPosition()

	if (self.gdata.snapToPoint and self.gdata.snapToFrame) then
		self:StickToPoint(_G[self.gdata.snapToFrame], self.gdata.snapToPoint, self.gdata.snapToPad, self.gdata.snapToPad)
	else

		local point, x, y = self.gdata.point, self.gdata.x, self.gdata.y

		if (point:find("SnapTo")) then
			self.gdata.point = "CENTER"; point = "CENTER"
		end

		self:SetUserPlaced(false)
		self:ClearAllPoints()
		self:SetPoint("CENTER", "UIParent", point, x, y)
		self:SetUserPlaced(true)
		self:SetFrameStrata(self.gdata.barStrata)

		if (self.message) then
			self.message:SetText(point:lower().."     x: "..format("%0.2f", x).."     y: "..format("%0.2f", y))
			self.messagebg:SetWidth(self.message:GetWidth()*1.05)
			self.messagebg:SetHeight(self.message:GetHeight()*1.1)
		end

		self.posSet = true
	end
end

function BAR:SetFauxState(state)

	self.objCount = 0

	self.handler:SetAttribute("fauxstate", state)

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object) then
			object:SetFauxState(state)
		end
	end

	if (IonObjectEditor and IonObjectEditor:IsVisible()) then
		ION:UpdateObjectGUI()
	end
end

function BAR:LoadObjects(init)

	self.objCount = 0

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object) then

			self.objTable[object.objTIndex][2] = 0

			object:SetData(self)

			object:LoadData(SPEC.cSpec, self.handler:GetAttribute("activestate"))

			object:SetAux()

			object:SetType(nil, nil, init)

			object:SetGrid()

			self.objCount = self.objCount + 1

			self.countChanged = true
		end
	end
end

function BAR:SetObjectLoc()

	local width, height, num, count, origCol, x, y, object, lastObj, placed = 0, 0, 0, self.objCount, self.gdata.columns
	local shape, padH, padV, arcStart, arcLength = self.gdata.shape, self.gdata.padH, self.gdata.padV, self.gdata.arcStart, self.gdata.arcLength
	local cAdjust, rAdjust, columns, rows = 0.5, 1

	if (not origCol) then
		origCol = count; rows = 1
	else
		rows = (round(ceil(count/self.gdata.columns), 1)/2)+0.5
	end

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object and num < count) then

			object:ClearAllPoints()

			object:SetParent(self.handler)

			object:SetAttribute("lastPos", nil)

			width = object:GetWidth(); height = object:GetHeight()

			if (count > origCol and mod(count, origCol)~=0 and rAdjust == 1) then
				columns = (mod(count, origCol))/2
			elseif (origCol >= count) then
				columns = count/2
			else
				columns = origCol/2
			end

			if (shape == 2) then

				if (not placed) then
					placed = arcStart
				end

				x = ((width+padH)*(count/math.pi))*(cos(placed))
				y = ((width+padV)*(count/math.pi))*(sin(placed))

				object:SetPoint("CENTER", self, "CENTER", x, y)

				placed = placed - (arcLength/count)

			elseif (shape == 3) then

				if (not placed) then

					placed = arcStart

					object:SetPoint("CENTER", self, "CENTER", 0, 0)

					placed = placed - (arcLength/count)

				else

					x = ((width+padH)*(count/math.pi))*(cos(placed))
					y = ((width+padV)*(count/math.pi))*(sin(placed))

					object:SetPoint("CENTER", self, "CENTER", x, y)

					placed = placed - (arcLength/(count-1))
				end

			else
				if (not placed) then
					placed = 0
				end

				x = -(width + padH) * (columns-cAdjust)
				y = (height + padV) * (rows-rAdjust)

				object:SetPoint("CENTER", self, "CENTER", x, y)

				placed = placed + 1; cAdjust = cAdjust + 1

				if (placed >= columns*2) then
					placed = 0
					cAdjust = 0.5
					rAdjust = rAdjust + 1
				end
			end

			lastObj = object

			num = num + 1

			object:SetAttribute("barPos", num)

			object:SetData(self)
		end
	end

	if (lastObj) then
		lastObj:SetAttribute("lastPos", true)
	end
end

function BAR:SetPerimeter()

	local num, count = 0, self.objCount

	self.objectCount = 0

	self.top = nil; self.bottom = nil; self.left = nil; self.right = nil

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object and num < count) then

			local objTop, objBottom, objLeft, objRight = object:GetTop(), object:GetBottom(), object:GetLeft(), object:GetRight()
			local scale = 1

			self.objectCount = self.objectCount + 1

			if (self.top) then
				if (objTop*scale > self.top) then self.top = objTop*scale end
			else self.top = objTop*scale end

			if (self.bottom) then
				if (objBottom*scale < self.bottom) then self.bottom = objBottom*scale end
			else self.bottom = objBottom*scale end

			if (self.left) then
				if (objLeft*scale < self.left) then self.left = objLeft*scale end
			else self.left = objLeft*scale end

			if (self.right) then
				if (objRight*scale > self.right) then self.right = objRight*scale end
			else self.right = objRight*scale end

			num = num + 1
		end
	end
end

function BAR:SetDefaults(gdefaults, cdefaults)

	if (gdefaults) then
		for k,v in pairs(gdefaults) do
			self.gdata[k] = v
		end
	end

	if (cdefaults) then
		for k,v in pairs(cdefaults) do
			self.cdata[k] = v
		end
	end

	self:SaveData()
end

function BAR:SetRemap_Paged()

	self.cdata.remap = ""

	for i=1,6 do
		self.cdata.remap = self.cdata.remap..i..":"..i..";"
	end

	self.cdata.remap = gsub(self.cdata.remap, ";$", "")

end

function BAR:SetRemap_Stance()

	local start = tonumber(MAS.stance.homestate:match("%d+"))

	if (start) then

		self.cdata.remap = ""

		for i=start,7 do
			self.cdata.remap = self.cdata.remap..i..":"..i..";"
		end

		self.cdata.remap = gsub(self.cdata.remap, ";$", "")

		if (ION.class == "DRUID") then
			self.cdata.remap = gsub(self.cdata.remap, "2:2", "2:0")
			self.cdata.remap = gsub(self.cdata.remap, "4:4", "4:0")
			self.cdata.remap = gsub(self.cdata.remap, "5:5", "5:0")
		end
	end
end

function BAR:SetSize()

	if (self.right) then
		self:SetWidth(((self.right-self.left)+5)*(self.gdata.scale))
		self:SetHeight(((self.top-self.bottom)+5)*(self.gdata.scale))
	else
		self:SetWidth(195)
		self:SetHeight(36*(self.gdata.scale))
	end

end

function BAR:ACTIONBAR_SHOWGRID(...)

	if (not InCombatLockdown() and self:IsVisible()) then
		self:Hide(); self.showgrid = true
	end

end

function BAR:ACTIONBAR_HIDEGRID(...)

	if (not InCombatLockdown() and self.showgrid) then
		self:Show(); self.showgrid = nil
	end

end

function BAR:ACTIVE_TALENT_GROUP_CHANGED(...)

	self.stateschanged = true

	self.vischanged = true

	self:Update()

end


function BAR:OnEvent(...)

	local event = select(1,...)

	if (BAR[event]) then
		BAR[event](self, ...)
	end
end

function BAR:OnClick(...)

	local click, down = select(1, ...), select(2, ...)

	if (not down) then
		self.newBar = ION:ChangeBar(self)
	end

	self.click = click
	self.dragged = false
	self.elapsed = 0
	self.pushed = 0

	if (IsShiftKeyDown() and not down) then

		if (self.microAdjust) then
			self.microAdjust = false
			self:EnableKeyboard(false)
			self.message:Hide()
			self.messagebg:Hide()
		else
			self.gdata.snapTo = false
			self.gdata.snapToPoint = false
			self.gdata.snapToFrame = false
			self.microAdjust = 1
			self:EnableKeyboard(true)
			self.message:Show()
			self.message:SetText(self.gdata.point:lower().."     x: "..format("%0.2f", self.gdata.x).."     y: "..format("%0.2f", self.gdata.y))
			self.messagebg:Show()
			self.messagebg:SetWidth(self.message:GetWidth()*1.05)
			self.messagebg:SetHeight(self.message:GetHeight()*1.1)
		end

	elseif (click == "MiddleButton") then

		if (GetMouseFocus() ~= ION.CurrentBar) then
			self.newBar = ION:ChangeBar(self)
		end

		if (down) then
			--ION:ConcealBar(nil, true)
		end

	elseif (click == "RightButton" and not self.action and not down) then

		self.mousewheelfunc = nil

		if (not IsAddOnLoaded("Ion-GUI")) then
			LoadAddOn("Ion-GUI")
		end

		if (not self.newBar and IonBarEditor:IsVisible()) then
			IonBarEditor:Hide()
		else
			IonBarEditor:Show()
		end

	elseif (not down) then

		if (not self.newBar) then
			--updateState(self, 1)
		end

	end

	if (not down and IonBarEditor and IonBarEditor:IsVisible()) then
		ION:UpdateBarGUI()
	end

end

function BAR:OnEnter(...)

	if (self.cdata.conceal) then
		self:SetBackdropColor(1,0,0,0.6)
	else
		self:SetBackdropColor(0,0,1,0.5)
	end

	self.text:Show()
end

function BAR:OnLeave(...)

	if (self ~= ION.CurrentBar) then

		if (self.cdata.conceal) then
			self:SetBackdropColor(1,0,0,0.4)
		else
			self:SetBackdropColor(0,0,0,0.4)
		end
	end

	if (self ~= ION.CurrentBar) then
		self.text:Hide()
	end
end

function BAR:OnDragStart(...)

	ION:ChangeBar(self)

	self:SetFrameStrata(self.gdata.barStrata)
	self:EnableKeyboard(false)

	self.adjusting = true
	self.selected = true
	self.isMoving = true

	self.gdata.snapToPoint = false
	self.gdata.snapToFrame = false

	self:StartMoving()
end

function BAR:OnDragStop(...)

      local point

	self:StopMovingOrSizing()

	for _,bar in pairs(BARIndex) do

		if (not point and self.gdata.snapTo and bar.gdata.snapTo and self ~= bar) then

			point = self:Stick(bar, GDB.snapToTol, self.gdata.snapToPad, self.gdata.snapToPad)

			if (point) then
				self.gdata.snapToPoint = point
				self.gdata.snapToFrame = bar:GetName()
				self.gdata.point = "SnapTo: "..point
				self.gdata.x = 0
				self.gdata.y = 0
			end
		end
	end

	if (not point) then
		self.gdata.snapToPoint = false
		self.gdata.snapToFrame = false
		self.gdata.point, self.gdata.x, self.gdata.y = self:GetPosition()
		self:SetPosition()
	end

	if (self.gdata.snapTo and not self.gdata.snapToPoint) then
		self:StickToEdge()
	end

	self.isMoving = false
	self.dragged = true
	self.elapsed = 0

	self:Update()

end

local barStack = {}
local stackWatch = CreateFrame("Frame", nil, UIParent)
stackWatch:SetScript("OnUpdate", function(self) self.bar = GetMouseFocus():GetName() if (not BARNameIndex[self.bar]) then wipe(barStack); self:Hide() end end)
stackWatch:Hide()

function BAR:OnKeyDown(key, onupdate)

	if (self.microAdjust) then

		self.keydown = key

		if (not onupdate) then
			self.elapsed = 0
		end

		self.gdata.point, self.gdata.x, self.gdata.y = self:GetPosition()

		self:SetUserPlaced(false)

		self:ClearAllPoints()

		if (key == "UP") then
			self.gdata.y = self.gdata.y + .1 * self.microAdjust
		elseif (key == "DOWN") then
			self.gdata.y = self.gdata.y - .1 * self.microAdjust
		elseif (key == "LEFT") then
			self.gdata.x = self.gdata.x - .1 * self.microAdjust
		elseif (key == "RIGHT") then
			self.gdata.x = self.gdata.x + .1 * self.microAdjust
		elseif (not key:find("SHIFT")) then
			self.microAdjust = false
			self:EnableKeyboard(false)
		end

		self:SetPosition()

		self:SaveData()
	end
end

function BAR:OnKeyUp(key)

	if (self.microAdjust and not key:find("SHIFT")) then

		self.microAdjust = 1
		self.keydown = nil
		self.elapsed = 0
	end
end

function BAR:OnMouseWheel(delta)

	stackWatch:Show()

	IonTooltipScan:SetOwner(UIParent, "ANCHOR_NONE")
	IonTooltipScan:SetFrameStack()

	local objects = ION:GetParentKeys(IonTooltipScan)
	local _, bar, level, text, added

	for k,v in pairs(objects) do

		if (_G[v]:IsObjectType("FontString")) then

			text = _G[v]:GetText()

			if (text and text:find("%p%d+%p")) then

				_, level, text = (" "):split(text)

				if (text and BARNameIndex[text]) then

					level = tonumber(level:match("%d+"))

					if (level and level < 3) then

						added = nil

						bar = BARNameIndex[text]

						for k,v in pairs(barStack) do
							if (bar == v) then
								added = true
							end
						end

						if (not added) then
							tinsert(barStack, bar)
						end
					end
				end
			end
		end
	end

	bar = tremove(barStack, 1)

	if (bar) then
		ION:ChangeBar(bar)
	end
end

function BAR:OnShow()

	if (self == ION.CurrentBar) then

		if (self.cdata.conceal) then
			self:SetBackdropColor(1,0,0,0.6)
		else
			self:SetBackdropColor(0,0,1,0.5)
		end

	else
		if (self.cdata.conceal) then
			self:SetBackdropColor(1,0,0,0.4)
		else
			self:SetBackdropColor(0,0,0,0.4)
		end
	end

	self.handler:SetAttribute("editmode", true)
	self.handler:Show()

	self:UpdateObjectGrid(ION.BarsShown)

	self:EnableKeyboard(false)
end

function BAR:OnHide()

	self.handler:SetAttribute("editmode", nil)

	if (self.handler:GetAttribute("vishide")) then
		self.handler:Hide()
	end

	self:UpdateObjectGrid()

	self:EnableKeyboard(false)

end

function BAR:Pulse(elapsed)

	alphaTimer = alphaTimer + elapsed * 1.5

	if (alphaDir == 1) then
		if (1-alphaTimer <= 0) then
			alphaDir = 0; alphaTimer = 0
		end
	else
		if (alphaTimer >= 1) then
			alphaDir = 1; alphaTimer = 0
		end
	end

	if (alphaDir == 1) then
		if ((1-(alphaTimer)) >= 0) then
			self:SetAlpha(1-(alphaTimer))
		end
	else
		if ((alphaTimer) <= 1) then
			self:SetAlpha((alphaTimer))
		end
	end

	self.pulse = true
end

function BAR:OnUpdate(elapsed)

	if (self.elapsed) then

		self.elapsed = self.elapsed + elapsed

		if (self.elapsed > 10) then
			self.elapsed = 0.75
		end

		if (self.microAdjust and not self.action) then

			self:Pulse(elapsed)

			if (self.keydown and self.elapsed >= 0.5) then
				self.microAdjust = self.microAdjust + 1
				self:OnKeyDown(self.keydown, self.microAdjust)
			end

		elseif (self.pulse) then
			self:SetAlpha(1)
			self.pulse = nil
		end

		if (self.hover) then
			self.elapsed = 0
		end
	end

	if (GetMouseFocus() == self) then
		if (not self.wheel) then
			self:EnableMouseWheel(true); self.wheel = true
		end
	elseif (self.wheel) then
		self:EnableMouseWheel(false); self.wheel = nil
	end
end

function BAR:SaveData()

	local id = self:GetID()

	if (self.GDB[id]) then

		for key,value in pairs(self.gdata) do
			self.GDB[id][key] = value
		end

	else
		print("DEBUG: Bad Global Save Data for "..self:GetName().." ?")
	end

	if (self.CDB[id]) then

		for key,value in pairs(self.cdata) do
			self.CDB[id][key] = value
		end

	else
		print("DEBUG: Bad Character Save Data for "..self:GetName().." ?")
	end
end

function BAR:LoadData()

	local id = self:GetID()

	if (not self.GDB[id]) then
		self.GDB[id] = CopyTable(ION.barGDEF)
	end

	ION:UpdateData(self.GDB[id], ION.barGDEF)

	self.gdata = CopyTable(self.GDB[id])

	if (not self.CDB[id]) then
		self.CDB[id] = CopyTable(ION.barCDEF)
	end

	ION:UpdateData(self.CDB[id], ION.barCDEF)

	self.cdata = CopyTable(self.CDB[id])

	if (#self.gdata.name < 1) then
		self.gdata.name = self.barLabel.." "..self:GetID()
	end

end

function BAR:UpdateObjectData()

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object) then
			object:SetData(self)
		end
	end
end

function BAR:UpdateObjectGrid(show)

	for objID in gmatch(self.gdata.objectList, "[^;]+") do

		object = _G[self.objPrefix..objID]

		if (object) then
			object:SetGrid(show)
		end
	end
end

function BAR:DeleteBar()

	local handler = self.handler

	handler:SetAttribute("state-current", "homestate")
	handler:SetAttribute("state-last", "homestate")
	handler:SetAttribute("showstates", "homestate")

	handler:ClearStates(self, "homestate")

	for state, values in pairs(MAS) do

		if (self.cdata[state] and self[state] and self[state].registered) then

			if (state == "custom" and self.cdata.customRange) then

				local start = tonumber(match(self.cdata.customRange, "^%d+"))
				local stop = tonumber(match(self.cdata.customRange, "%d+$"))

				if (start and stop) then
					handler:ClearStates(self, state, start, stop)
				end

			else
				handler:ClearStates(self, state, values.rangeStart, values.rangeStop)
			end

		end
	end

	self:RemoveObjects(self.objCount)

	self:SetScript("OnClick", function() end)
	self:SetScript("OnDragStart", function() end)
	self:SetScript("OnDragStop", function() end)
	self:SetScript("OnEnter", function() end)
	self:SetScript("OnLeave", function() end)
	self:SetScript("OnEvent", function() end)
	self:SetScript("OnKeyDown", function() end)
	self:SetScript("OnKeyUp", function() end)
	self:SetScript("OnMouseWheel", function() end)
	self:SetScript("OnShow", function() end)
	self:SetScript("OnHide", function() end)
	self:SetScript("OnUpdate", function() end)

	self:UnregisterEvent("ACTIONBAR_SHOWGRID")
	self:UnregisterEvent("ACTIONBAR_HIDEGRID")
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

	self:SetWidth(36)
	self:SetHeight(36)
	self:ClearAllPoints()
	self:SetPoint("CENTER")
	self:Hide()

	BARIndex[self.index] = nil
	BARNameIndex[self:GetName()] = nil

	self.GDB[self:GetID()] = nil
	self.CDB[self:GetID()] = nil

	if (IonBarEditor and IonBarEditor:IsVisible()) then
		ION:UpdateBarGUI()
	end

end

function BAR:AddObjectToList(object)

	if (not self.gdata.objectList or self.gdata.objectList == "") then
		self.gdata.objectList = tostring(object.id)
	elseif (self.barReverse) then
		self.gdata.objectList = object.id..";"..self.gdata.objectList
	else
		self.gdata.objectList = self.gdata.objectList..";"..object.id
	end

end

function BAR:AddObjects(num)

	num = tonumber(num)

	if (not num) then
		num = 1
	end

	if (num) then

		for i=1,num do

			local object

			for index,data in ipairs(self.objTable) do
				if (not object and data[2] == 1) then
					object = data[1]; data[2] = 0
				end
			end

			if (not object and not self.objMax) then

				local id = 1

				for _ in ipairs(self.objGDB) do
					id = id + 1
				end

				object = ION:CreateNewObject(self.class, id)
			end

			if (object) then

				object:Show()

				self:AddObjectToList(object)

				self:LoadObjects()

				self:SetObjectLoc()

				self:SetPerimeter()

				self:SetSize()

				self:Update()
			end
		end
	end
end

function BAR:StoreObject(object, storage, objTable)

	object:ClearAllPoints()

	object.config.scale = 1
	object.config.XOffset = 0
	object.config.YOffset = 0
	object.config.target = "none"

	object.config.mouseAnchor = false
	object.config.clickAnchor = false
	object.config.anchorDelay = false
	object.config.anchoredBar = false

	if (object.binder) then
		object.binder:ClearBindings(object)
	end

	object:SaveData()

	--ION.UpdateAnchor(button, nil, nil, nil, true)

	objTable[object.objTIndex][2] = 1

	object:SetParent(storage)
end

function BAR:RemoveObjectFromList(objID)

	if (self.barReverse) then
		self.gdata.objectList = (self.gdata.objectList):gsub("^"..objID.."[;]*", "")
	else
		self.gdata.objectList = (self.gdata.objectList):gsub("[;]*"..objID.."$", "")
	end

end

function BAR:RemoveObjects(num)

	if (not self.objStorage) then return end

	if (not num) then
		num = 1
	end

	if (num) then

		for i=1,num do

			local objID

			if (self.barReverse) then
				objID = (self.gdata.objectList):match("^%d+")
			else
				objID = (self.gdata.objectList):match("%d+$")
			end

			if (objID) then

				local object = _G[self.objPrefix..objID]

				if (object) then

					self:StoreObject(object, self.objStorage, self.objTable)

					self:RemoveObjectFromList(objID)

					self.objCount = self.objCount - 1

					self.countChanged = true
				end

				self:SetObjectLoc()

				self:SetPerimeter()

				self:SetSize()

				self:Update()
			end
		end
	end
end

local statetable = {}

function BAR:SetState(msg, gui, silent)

	if (msg) then

		local state = msg:match("^%S+")
		local command = msg:gsub(state, ""); command = command:gsub("^%s+", "")

		if (not MAS[state]) then
			if (not silent) then
				ION:PrintStateList()
				return
			end
		end

		if (self.cdata[state] and not gui) then

			self.cdata[state] = false

		elseif (not gui) then

			self.cdata[state] = true
		end

		if (state == "paged") then

			self.cdata.stance = false
			self.cdata.pet = false

			if (self.cdata.paged) then
				self:SetRemap_Paged()
			else
				self.cdata.remap = false
			end
		end

		if (state == "stance") then

			self.cdata.paged = false
			self.cdata.pet = false

			if (not self.cdata.stance and self.cdata.prowl) then
				self.cdata.prowl = false
			end

			if (self.cdata.stance) then
				self:SetRemap_Stance()
			else
				self.cdata.remap = false
			end
		end

		if (state == "custom") then

			if (self.cdata.custom) then

				local count, newstates = 0, ""

				self.cdata.customNames = {}

				for states in gmatch(command, "[^;]+") do

					self.cdata.customRange = "1;"..count

					if (count == 0) then
						newstates = states.." homestate; "
						self.cdata.customNames["homestate"] = states
					else
						newstates = newstates..states.." custom"..count.."; "
						self.cdata.customNames["custom"..count] = states
					end

					count = count + 1
				end

				self.cdata.custom = newstates or ""

			else
				self.cdata.customNames = false
				self.cdata.customRange = false
			end
		end

		if (state == "pet") then
			self.cdata.paged = false
			self.cdata.stance = false
		end

		self.stateschanged = true

		self:Update()
	else

		wipe(statetable)

		for k,v in pairs(ION.STATEINDEX) do

			if (self.cdata[k]) then
				tinsert(statetable, k..": on")
			else
				tinsert(statetable, k..": off")
			end
		end

		tsort(statetable)

		for k,v in ipairs(statetable) do
			print(v)
		end
	end

end

function BAR:SetVisibility(msg, gui, silent)

	if (msg) then

		wipe(statetable)

		local toggle, index, num = (" "):split(msg)

		toggle = toggle:lower()

		if (toggle and ION.STATEINDEX[toggle]) then

			if (index) then

				num = index:match("%d+")

				if (num) then

					local hidestate = ION.STATEINDEX[toggle]..num

					if (ION.STATES[hidestate]) then

						if (self.gdata.hidestates:find(hidestate)) then
							self.gdata.hidestates = self.gdata.hidestates:gsub(hidestate..":", "")
						else
							self.gdata.hidestates = self.gdata.hidestates..hidestate..":"
						end
					else
						print(L.INVALID_INDEX); return
					end

				elseif (index == L.STATE_SHOW) then

					local hidestate = ION.STATEINDEX[toggle].."%d+"

					self.gdata.hidestates = self.gdata.hidestates:gsub(hidestate..":", "")

				elseif (index == L.STATE_HIDE) then

					local hidestate = ION.STATEINDEX[toggle]

					for state in pairs(ION.STATES) do
						if (state:find("^"..hidestate) and not self.gdata.hidestates:find(state)) then
							self.gdata.hidestates = self.gdata.hidestates..state..":"
						end
					end
				end

			end

			if (not silent) then

				local hidestates, desc, showhide = self.gdata.hidestates

				local highindex = 0

				for state,desc in pairs(ION.STATES) do

					local index = state:match("%d+$")

					if (index) then

						index = tonumber(index)

						if (index and state:find("^"..toggle)) then

							if (hidestates:find(state)) then
								statetable[index] = desc..":".."Hide:"..state
							else
								statetable[index] = desc..":".."Show:"..state
							end

							if (index > highindex) then
								highindex = index
							end
						end
					end
				end

				for i=1,highindex do
					if (not statetable[i]) then
						statetable[i] = "ignore"
					end
				end

				if (#statetable > 0) then

					print("\n")

					if (statetable[0]) then
						desc, showhide = (":"):split(statetable[0])
						print("0: "..desc.." - "..showhide)
					end

					for k,v in ipairs(statetable) do
						if (v ~= "ignore") then
							desc, showhide = (":"):split(v)
							print(k..": "..desc.." - "..showhide)
						end
					end
				end
			end

			self.vischanged = true

			self:Update()
		else
			ION:PrintStateList()
		end

	else

	end
end

function BAR:AutoHideBar(msg, gui, checked, query)

	if (query) then
		return self.gdata.autoHide
	end

	if (gui) then

		if (checked) then
			self.gdata.autoHide = true
		else
			self.gdata.autoHide = false
		end

	else

		local toggle = self.gdata.autoHide

		if (toggle) then
			self.gdata.autoHide = false
		else
			self.gdata.autoHide = true
		end
	end

	self:Update()
end

function BAR:ShowGridSet(msg, gui, checked, query)

	if (query) then
		return self.gdata.showGrid
	end

	if (gui) then

		if (checked) then
			self.gdata.showGrid = true
		else
			self.gdata.showGrid = false
		end
	else

		if (self.gdata.showGrid) then
			self.gdata.showGrid = false
		else
			self.gdata.showGrid = true
		end
	end

	self:UpdateObjectData()

	self:UpdateObjectGrid()

	self:Update()

end

local function spellGlowMod(self, msg, gui)

	if (msg:lower() == "default") then

		if (self.cdata.spellGlowDef) then
			self.cdata.spellGlowDef = false
		else
			self.cdata.spellGlowDef = true
			self.cdata.spellGlowAlt = false
		end

		if (not self.cdata.spellGlowDef and not self.cdata.spellGlowAlt) then
			self.cdata.spellGlowDef = true
		end

	elseif (msg:lower() == "alt") then

		if (self.cdata.spellGlowAlt) then
			self.cdata.spellGlowAlt = false
		else
			self.cdata.spellGlowAlt = true
			self.cdata.spellGlowDef = false
		end

		if (not self.cdata.spellGlowDef and not self.cdata.spellGlowAlt) then
			self.cdata.spellGlowDef = true
		end
	elseif (not gui) then
		print(L.SPELLGLOWS)
	end

end

function BAR:SpellGlowSet(msg, gui, checked, query)

	if (query) then
		if (msg == "default") then
			return self.cdata.spellGlowDef
		elseif(msg == "alt") then
			return self.cdata.spellGlowAlt
		else
			return self.cdata.spellGlow
		end
	end

	if (gui) then

		if (msg) then
			spellGlowMod(self, msg, gui)
		elseif (checked) then
			self.cdata.spellGlow = true
		else
			self.cdata.spellGlow = false
		end

	else

		if (msg) then
			spellGlowMod(self, msg, gui)
		elseif (self.cdata.spellGlow) then
			self.cdata.spellGlow = false
		else
			self.cdata.spellGlow = true
		end
	end

	self:UpdateObjectData()

	self:Update()

end

function BAR:SnapToBar(msg, gui, checked, query)

	if (query) then
		return self.gdata.snapTo
	end

	if (gui) then

		if (checked) then
			self.gdata.snapTo = true
		else
			self.gdata.snapTo = false
		end
	else

		local toggle = self.gdata.snapTo

		if (toggle) then

			self.gdata.snapTo = false
			self.gdata.snapToPoint = false
			self.gdata.snapToFrame = false

			self:SetUserPlaced(true)

			self.gdata.point, self.gdata.x, self.gdata.y = self:GetPosition()

			self:SetPosition()

		else
			self.gdata.snapTo = true
		end
	end

	self:Update()
end

function BAR:DualSpecSet(msg, gui, checked, query)

	if (query) then
		return self.cdata.dualSpec
	end

	if (gui) then

		if (checked) then
			self.cdata.dualSpec = true
		else
			self.cdata.dualSpec = false
		end
	else

		local toggle = self.cdata.dualSpec

		if (toggle) then
			self.cdata.dualSpec = false
		else
			self.cdata.dualSpec = true
		end
	end

	self:Update()
end

function BAR:ConcealBar(msg, gui, checked, query)

	if (InCombatLockdown()) then return end

	if (query) then
		return self.cdata.conceal
	end

	if (gui) then

		if (checked) then
			self.cdata.conceal = true
		else
			self.cdata.conceal = false
		end

	else

		local toggle = self.cdata.conceal

		if (toggle) then
			self.cdata.conceal = false
		else
			self.cdata.conceal = true
		end
	end

	if (self.cdata.conceal) then

		if (self.selected) then
			self:SetBackdropColor(1,0,0,0.6)
		else
			self:SetBackdropColor(1,0,0,0.4)
		end
	else
		if (self.selected) then
			self:SetBackdropColor(0,0,1,0.5)
		else
			self:SetBackdropColor(0,0,0,0.4)
		end
	end

	self:Update()
end

local function barLockMod(self, msg, gui)

	if (msg:lower() == "alt") then

		if (self.cdata.barLockAlt) then
			self.cdata.barLockAlt = false
		else
			self.cdata.barLockAlt = true
		end
	elseif (msg:lower() == "ctrl") then

		if (self.cdata.barLockCtrl) then
			self.cdata.barLockCtrl = false
		else
			self.cdata.barLockCtrl = true
		end
	elseif (msg:lower() == "shift") then

		if (self.cdata.barLockShift) then
			self.cdata.barLockShift = false
		else
			self.cdata.barLockShift = true
		end
	elseif (not gui) then
		print(L.BARLOCK_MOD)
	end

end

function BAR:LockSet(msg, gui, checked, query)

	if (query) then
		if (msg == "shift") then
			return self.cdata.barLockShift
		elseif(msg == "ctrl") then
			return self.cdata.barLockCtrl
		elseif(msg == "alt") then
			return self.cdata.barLockAlt
		else
			return self.cdata.barLock
		end
	end

	if (gui) then

		if (msg) then
			barLockMod(self, msg, gui)
		elseif (checked) then
			self.cdata.barLock = true
		else
			self.cdata.barLock = false
		end

	else
		if (msg) then
			barLockMod(self, msg, gui)
		else
			if (self.cdata.barLock) then
				self.cdata.barLock = false
			else
				self.cdata.barLock = true
			end
		end
	end

	self:UpdateObjectData()

	self:Update()
end

local function toolTipMod(self, msg, gui)

	if (msg:lower() == "enhanced") then

		if (self.cdata.tooltipsEnhanced) then
			self.cdata.tooltipsEnhanced = false
		else
			self.cdata.tooltipsEnhanced = true
		end
	elseif (msg:lower() == "combat") then

		if (self.cdata.tooltipsCombat) then
			self.cdata.tooltipsCombat = false
		else
			self.cdata.tooltipsCombat = true
		end
	elseif (not gui) then
		print(L.TOOLTIPS)
	end

end

function BAR:ToolTipSet(msg, gui, checked, query)

	if (query) then
		if (msg == "enhanced") then
			return self.cdata.tooltipsEnhanced
		elseif(msg == "combat") then
			return self.cdata.tooltipsCombat
		else
			return self.cdata.tooltips
		end
	end

	if (gui) then

		if (msg) then
			toolTipMod(self, msg, gui)
		elseif (checked) then
			self.cdata.tooltips = true
		else
			self.cdata.tooltips = false
		end

	else

		if (msg) then

			toolTipMod(self, msg, gui)

		else
			if (self.cdata.tooltips) then
				self.cdata.tooltips = false
			else
				self.cdata.tooltips = true
			end
		end
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:NameBar(name, gui)

	if (name) then

		self.gdata.name = name

		self:Update()
	end
end

function BAR:ShapeBar(shape, gui, query)

	if (query) then
		return barShapes[self.gdata.shape]
	end

	local shape = tonumber(shape)

	if (shape and barShapes[shape]) then

		self.gdata.shape = shape

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_SHAPES)
	end
end

function BAR:ColumnsSet(command, gui, query)

	if (query) then
		if (self.gdata.columns) then
			return self.gdata.columns
		else
			return L.OFF
		end
	end

	local columns = tonumber(command)

	if (columns and columns > 0) then

		self.gdata.columns = columns

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not columns) then

		self.gdata.columns = false

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_COLUMNS)
	end
end

function BAR:ArcStartSet(command, gui, query)

	if (query) then
		return self.gdata.arcStart
	end

	local start = tonumber(command)

	if (start and start>=0 and start<=359) then

		self.gdata.arcStart = start

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_ARCSTART)
	end
end

function BAR:ArcLengthSet(command, gui, query)

	if (query) then
		return self.gdata.arcLength
	end

	local length = tonumber(command)

	if (length and length>=0 and length<=359) then

		self.gdata.arcLength = length

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_ARCLENGTH)
	end
end

function BAR:PadHSet(command, gui, query)

	if (query) then
		return self.gdata.padH
	end

	local padh = tonumber(command)

	if (padh) then

		self.gdata.padH = padh

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_PADH)
	end
end

function BAR:PadVSet(command, gui, query)

	if (query) then
		return self.gdata.padV
	end

	local padv = tonumber(command)

	if (padv) then

		self.gdata.padV = padv

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_PADV)
	end
end

function BAR:PadHVSet(command, gui, query)

	if (query) then
		return "---"
	end

	local padhv = tonumber(command)

	if (padhv) then

		self.gdata.padH = self.gdata.padH + padhv
		self.gdata.padV = self.gdata.padV + padhv

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()

	elseif (not gui) then

		print(L.BAR_PADHV)
	end
end

function BAR:ScaleBar(scale, gui, query)

	if (query) then
		return self.gdata.scale
	end

	scale = tonumber(scale)

	if (scale) then

		self.gdata.scale = scale

		self:SetObjectLoc()

		self:SetPerimeter()

		self:SetSize()

		self:Update()
	end
end

function BAR:StrataSet(command, gui, query)

	if (query) then
		return self.gdata.objectStrata
	end

	local strata = tonumber(command)

	if (strata and ION.Stratas[strata] and ION.Stratas[strata+1]) then

		self.gdata.barStrata = ION.Stratas[strata+1]
		self.gdata.objectStrata = ION.Stratas[strata]

		self:SetPosition()

		self:UpdateObjectData()

		self:Update()

	elseif (not gui) then

		print(L.BAR_STRATAS)
	end
end

function BAR:AlphaSet(command, gui, query)

	if (query) then
		return self.gdata.alpha
	end

	local alpha = tonumber(command)

	if (alpha and alpha>=0 and alpha<=1) then

		self.gdata.alpha = alpha

		self:Update()

	elseif (not gui) then

		print(L.BAR_ALPHA)
	end

end

function BAR:AlphaUpSet(command, gui, query)

	if (query) then

		--temp fix
		if (self.gdata.alphaUp == "none" or self.gdata.alphaUp == 1) then
			self.gdata.alphaUp = alphaUps[1]
		end

		return self.gdata.alphaUp
	end

	local alphaUp = tonumber(command)

	if (alphaUp and alphaUps[alphaUp]) then

		self.gdata.alphaUp = alphaUps[alphaUp]

		self:Update()

	elseif (not gui) then
		local text = ""

		for k,v in ipairs(alphaUps) do
			text = text.."\n"..k.."="..v
		end

		print(text)
	end
end

function BAR:AlphaUpSpeedSet(command, gui, query)

	if (query) then
		return (self.gdata.fadeSpeed*100).."%"
	end

	local speed = tonumber(command)

	if (speed) then

		self.gdata.fadeSpeed = self.gdata.fadeSpeed + speed

		if (self.gdata.fadeSpeed > 1) then
			self.gdata.fadeSpeed = 1
		end

		if (self.gdata.fadeSpeed < 0.01) then
			self.gdata.fadeSpeed = 0.01
		end

		self:Update()

	elseif (not gui) then

	end
end

function BAR:XAxisSet(command)

	local x = tonumber(command)

	if (x) then

		self.gdata.x = self.gdata.x + x

		self.gdata.snapTo = false
		self.gdata.snapToPoint = false
		self.gdata.snapToFrame = false

		self:SetPosition()

		self.gdata.point, self.gdata.x, self.gdata.y = self:GetPosition()

		self.message:Show()
		self.messagebg:Show()

		self:Update()
	else
		print(L.BAR_XPOS)
	end
end

function BAR:YAxisSet(command)

	local y = tonumber(command)

	if (y) then

		self.gdata.y = self.gdata.y + y

		self.gdata.snapTo = false
		self.gdata.snapToPoint = false
		self.gdata.snapToFrame = false

		self:SetPosition()

		self.gdata.point, self.gdata.x, self.gdata.y = self:GetPosition()

		self.message:Show()
		self.messagebg:Show()

		self:Update()
	else
		print(L.BAR_YPOS)
	end
end

function BAR:BindTextSet()

	if (self.cdata.bindText) then
		self.cdata.bindText = false
	else
		self.cdata.bindText = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:MacroTextSet()

	if (self.cdata.macroText) then
		self.cdata.macroText = false
	else
		self.cdata.macroText = true
	end

	self:UpdateObjectData()

	self:Update()

end

function BAR:CountTextSet()

	if (self.cdata.countText) then
		self.cdata.countText = false
	else
		self.cdata.countText = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:CDTextSet()

	if (self.cdata.cdText) then
		self.cdata.cdText = false
	else
		self.cdata.cdText = true
	end

	self:UpdateObjectData()

	self:Update()

end

function BAR:CDAlphaSet()

	if (self.cdata.cdAlpha) then
		self.cdata.cdAlpha = false
	else
		self.cdata.cdAlpha = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:AuraTextSet()

	if (self.cdata.auraText) then
		self.cdata.auraText = false
	else
		self.cdata.auraText = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:AuraIndSet()

	if (self.cdata.auraInd) then
		self.cdata.auraInd = false
	else
		self.cdata.auraInd = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:UpClicksSet()

	if (self.cdata.upClicks) then
		self.cdata.upClicks = false
	else
		self.cdata.upClicks = true
	end

	self:UpdateObjectData()

	self:Update()

end

function BAR:DownClicksSet()

	if (self.cdata.downClicks) then
		self.cdata.downClicks = false
	else
		self.cdata.downClicks = true
	end

	self:UpdateObjectData()

	self:Update()
end

function BAR:Load()

	self:SetPosition()

	self:LoadObjects(true)

	self:SetObjectLoc()

	self:SetPerimeter()

	self:SetSize()

	self:EnableKeyboard(false)

	self:Update()
end

local function controlOnEvent(self, event, ...)

	if (event == "ADDON_LOADED" and ... == "Ion") then

		GDB, CDB, SPEC = IonGDB, IonCDB, IonSpec

		barGDB = GDB.bars

		barCDB = CDB.bars

		ION:RegisterBarClass("bar", "Action Bar", "Action Button", barGDB, barCDB, BTNIndex, GDB.buttons, "CheckButton", "IonActionButtonTemplate", { __index = BUTTON }, false, false, STORAGE, nil, nil, true)

		ION:RegisterGUIOptions("bar",	{ AUTOHIDE = true, SHOWGRID = true,	SPELLGLOW = true,	SNAPTO = true, DUALSPEC = true, HIDDEN = true, LOCKBAR = true, TOOLTIPS = true }, true)

		if (GDB.firstRun) then

			local oid, offset = 1, 0

			for id, defaults in ipairs(gDef) do

				ION.RegisteredBarData["bar"].gDef = defaults

				local bar, object = ION:CreateNewBar("bar", id, true)

				for i=oid+offset,oid+11+offset do
					object = ION:CreateNewObject("bar", i, true)
					bar:AddObjectToList(object)
				end

				ION.RegisteredBarData["bar"].gDef = nil

				offset = offset + 12
			end
		else

			for id,data in pairs(barGDB) do
				if (data ~= nil) then
					ION:CreateNewBar("bar", id)
				end
			end

			for id,data in pairs(GDB.buttons) do
				if (data ~= nil) then
					ION:CreateNewObject("bar", id)
				end
			end
		end

		STORAGE:Hide()

	elseif (event == "PLAYER_LOGIN") then

		for _,bar in pairs(BARIndex) do
			bar:Load()
		end

	elseif (event == "PLAYER_LOGOUT") then


	elseif (event == "PLAYER_ENTERING_WORLD" and not PEW) then

		PEW = true; self.elapsed = 0

	elseif (event == "PLAYER_REGEN_DISABLED") then


	end
end

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetScript("OnEvent", controlOnEvent)
frame:SetScript("OnUpdate", controlOnUpdate)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame.elapsed = 0