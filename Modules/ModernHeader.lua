
local ModernHeader = Chinchilla:NewModule("Modern Header", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

ModernHeader.displayName = L["Modern Header"]
ModernHeader.desc = L["Use the modern minimap header and customize it."]

local defaultHeight = 16

function ModernHeader:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("ModernHeader", {
		profile = {
			enabled = true,
			scale = 1,
			height = 16
		}
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

function ModernHeader:OnEnable()
	MinimapCluster.BorderTop:Show()
	MinimapCluster.ZoneTextButton:Show()
	MiniMapMailIcon:SetPoint("BOTTOMRIGHT", MinimapCluster.MailFrame)
	--MinimapZoneText


	if self.db.profile.height then
		self:SetHeight(self.db.profile.height)
	end
end

function ModernHeader:OnDisable()
	MinimapCluster.BorderTop:Hide()
	defaultHeight:SetHeight(defaultHeight)
end

function ModernHeader:SetHeight(height)
	MinimapCluster.BorderTop:SetHeight(height)
	MinimapCluster.MailFrame:SetSize(height+5, height)
end

function ModernHeader:GetOptions()
	return {
		scale = {
			name = L["Scale"],
			desc = L["Set scale of Modern Header."],
			type = 'range',
			order = 1,
			min = 0.5,
			max = 10,
			step = 0.5,
			get = function() return self.db.profile.wheelZoom end,
			set = function(_, value)
				self.db.profile.wheelZoom = value
				MinimapCluster.BorderTop:SetScale(value)
			end,
		},
		height = {
			name = L["Height"],
			desc = L["Set height of Modern Header."],
			type = 'range',
			order = 2,
			min = 12,
			max = 80,
			step = 1,
			get = function() return self.db.profile.height end,
			set = function(_, value)
				self.db.profile.height = value
				ModernHeader:SetHeight(value)
			end,
		},
		autoZoom = {
			name = L["Auto zoom"],
			desc = L["Automatically zoom out after a specified time."],
			type = 'toggle', order = 2,
			get = function() return self.db.profile.autoZoom end,
			set = function(_, value) self.db.profile.autoZoom = value end,
		},
	}
end
