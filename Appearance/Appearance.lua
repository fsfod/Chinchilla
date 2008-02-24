local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_Appearance = Chinchilla:NewModule("Appearance", "LibRockEvent-1.0", "LibRockTimer-1.0")
local self = Chinchilla_Appearance
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Appearance.desc = L["Allow for a customized look of the minimap"]

local newDict, unpackDictAndDel = Rock:GetRecyclingFunctions("Chinchilla", "newDict", "unpackDictAndDel")

local rotateMinimap = GetCVar("rotateMinimap") == "1"
function Chinchilla_Appearance:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Appearance")
	Chinchilla:SetDatabaseNamespaceDefaults("Appearance", "profile", {
		scale = 1,
		alpha = 1,
		combatAlpha = 1,
		borderColor = {1, 1, 1, 1},
		buttonBorderAlpha = 1,
		strata = "BACKGROUND",
		frameLevel = 1,
		shape = "CORNER-BOTTOMLEFT",
		borderStyle = "Blizzard",
		borderRadius = 80,
	})
end

local borderStyles = {}
function Chinchilla_Appearance:AddBorderStyle(english, localized, texture)
	if type(english) ~= "string" then
		error(("Bad argument #2 to `AddBorderStyle'. Expected %q, got %q"):format("string", type(english)), 2)
	elseif borderStyles[english] then
		error(("Bad argument #2 to `AddBorderStyle'. %q already provided"):format(english), 2)
	elseif type(localized) ~= "string" then
		error(("Bad argument #3 to `AddBorderStyle'. Expected %q, got %q"):format("string", type(localized)), 2)
	elseif type(texture) ~= "string" then
		error(("Bad argument #4 to `AddBorderStyle'. Expected %q, got %q"):format("string", type(texture)), 2)
	end
	borderStyles[english] = { localized, texture }
end
Chinchilla.AddBorderStyle = Chinchilla_Appearance.AddBorderStyle

Chinchilla_Appearance:AddBorderStyle("Blizzard",   L["Blizzard"], [[Interface\AddOns\Chinchilla\Appearance\Border-Blizzard]])
Chinchilla_Appearance:AddBorderStyle("Thin",       L["Thin"],     [[Interface\AddOns\Chinchilla\Appearance\Border-Thin]])
Chinchilla_Appearance:AddBorderStyle("Alliance",   L["Alliance"], [[Interface\AddOns\Chinchilla\Appearance\Border-Alliance]])
Chinchilla_Appearance:AddBorderStyle("Tooltip",    L["Tooltip"],  [[Interface\AddOns\Chinchilla\Appearance\Border-Tooltip]])
Chinchilla_Appearance:AddBorderStyle("Tubular",    L["Tubular"],  [[Interface\AddOns\Chinchilla\Appearance\Border-Tubular]])
Chinchilla_Appearance:AddBorderStyle("Flat",       L["Flat"],     [[Interface\AddOns\Chinchilla\Appearance\Border-Flat]])
Chinchilla_Appearance:AddBorderStyle("Chinchilla", "Chinchilla",  [[Interface\AddOns\Chinchilla\Appearance\Border-Chinchilla]])

local cornerTextures = {}
function Chinchilla_Appearance:OnEnable()
	self:SetScale(nil)
	self:SetAlpha(nil)
	self:SetFrameStrata(nil)
	self:SetFrameLevel(nil)
	self:SetShape(nil)
	self:SetBorderColor(nil, nil, nil, nil)
	self:SetButtonBorderAlpha(nil)
	
	MinimapBorder:Hide()
	for i,v in ipairs(cornerTextures) do
		v:Show()
	end
	
	self:AddEventListener("MINIMAP_UPDATE_ZOOM")
	self:AddEventListener("PLAYER_REGEN_ENABLED")
	self:AddEventListener("PLAYER_REGEN_DISABLED")
	
	--[[ these issues seem to have been fixed with the custom mask textures
	self:AddEventListener("CVAR_UPDATE", "CVAR_UPDATE", 0.05)
	if IsMacClient() then --temporary hack to try and fix minimaps going black for Mac users. ~Ellipsis
		self:AddEventListener("DISPLAY_SIZE_CHANGED", "CVAR_UPDATE")
		self:AddEventListener("ZONE_CHANGED_NEW_AREA", "CVAR_UPDATE")
	end
	--]]
end

function Chinchilla_Appearance:OnDisable()
	self:SetScale(nil)
	self:SetAlpha(nil)
	self:SetFrameStrata(nil)
	self:SetFrameLevel(nil)
	self:SetShape(nil)
	self:SetBorderColor(nil, nil, nil, nil)
	self:SetButtonBorderAlpha(nil)
	
	MinimapBorder:Show()
	Minimap:SetMaskTexture([[Textures\MinimapMask]])
	
	for i,v in ipairs(cornerTextures) do
		v:Hide()
	end
	if Chinchilla:HasModule("MoveButtons") then
		Chinchilla:GetModule("MoveButtons"):Update()
	end
end

local indoors
function Chinchilla_Appearance:MINIMAP_UPDATE_ZOOM()
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	indoors = GetCVar("minimapZoom")+0 ~= Minimap:GetZoom()
	Minimap:SetZoom(zoom)
	
	self:SetAlpha(nil)
end

local inCombat = InCombatLockdown()
function Chinchilla_Appearance:PLAYER_REGEN_ENABLED()
	inCombat = false
	self:SetAlpha(nil)
end

function Chinchilla_Appearance:PLAYER_REGEN_DISABLED()
	inCombat = true
	self:SetCombatAlpha(nil)
end

function Chinchilla_Appearance:OnRotateMinimapUpdate(value)
	rotateMinimap = value
	self:SetShape(nil)
	Minimap:SetFrameLevel(MinimapCluster:GetFrameLevel()+1)
end

function Chinchilla_Appearance:SetScale(value)
	if value then
		self.db.profile.scale = value
	else
		value = self.db.profile.scale
	end
	if not Chinchilla:IsModuleActive(self) then
		value = 1
	end
	
	MinimapCluster:SetScale(value)
end

function Chinchilla_Appearance:SetAlpha(value)
	if value then
		self.db.profile.alpha = value
	else
		value = self.db.profile.alpha
	end
	if not Chinchilla:IsModuleActive(self) or indoors then
		value = 1
	end
	
	if not inCombat then
		MinimapCluster:SetAlpha(value)
	else
		MinimapCluster:SetAlpha(self.db.profile.combatAlpha)
	end
end

function Chinchilla_Appearance:SetCombatAlpha(value)
	if value then
		self.db.profile.combatAlpha = value
	else
		value = self.db.profile.combatAlpha
	end
	if not Chinchilla:IsModuleActive(self) or indoors then
		value = 1
	end
	
	if inCombat then
		MinimapCluster:SetAlpha(value)
	end
end

function Chinchilla_Appearance:SetFrameStrata(value)
	if value then
		self.db.profile.strata = value
	else
		value = self.db.profile.strata
	end
	if not Chinchilla:IsModuleActive(self) then
		value = "BACKGROUND"
	end

	MinimapCluster:SetFrameStrata(value)
end

function Chinchilla_Appearance:SetFrameLevel(value)
	if value then
		self.db.profile.frameLevel = value
	else
		value = self.db.profile.frameLevel
	end
	if not Chinchilla:IsModuleActive(self) then
		value = 1
	end
	
	MinimapCluster:SetFrameLevel(value)
end

local roundShapes = {
	{
		["ROUND"] = true,
		["CORNER-TOPLEFT"] = true,
		["SIDE-LEFT"] = true,
		["SIDE-TOP"] = true,
		["TRICORNER-TOPRIGHT"] = true,
		["TRICORNER-TOPLEFT"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-TOPRIGHT"] = true,
		["SIDE-RIGHT"] = true,
		["SIDE-TOP"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
		["TRICORNER-TOPRIGHT"] = true,
		["TRICORNER-TOPLEFT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-BOTTOMLEFT"] = true,
		["SIDE-LEFT"] = true,
		["SIDE-BOTTOM"] = true,
		["TRICORNER-TOPLEFT"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-BOTTOMRIGHT"] = true,
		["SIDE-RIGHT"] = true,
		["SIDE-BOTTOM"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
		["TRICORNER-TOPRIGHT"] = true,
	},
}
function Chinchilla_Appearance:SetShape(shape)
	if shape then
		self.db.profile.shape = shape
	else
		shape = self.db.profile.shape
	end
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	if rotateMinimap and shape ~= "SQUARE" then
		shape = "ROUND"
	end
	
	if not cornerTextures[1] then
		local borderRadius = self.db.profile.borderRadius
		for i = 1, 4 do
			local tex = MinimapBackdrop:CreateTexture("Chinchilla_Appearance_MinimapCorner" .. i, "ARTWORK")
			cornerTextures[i] = tex
			cornerTextures[i]:SetWidth(borderRadius)
			cornerTextures[i]:SetHeight(borderRadius)
		end
		
		cornerTextures[1]:SetPoint("BOTTOMRIGHT", Minimap, "CENTER")
		cornerTextures[1]:SetTexCoord(0, 0.25, 0, 0.5)
		
		cornerTextures[2]:SetPoint("BOTTOMLEFT", Minimap, "CENTER")
		cornerTextures[2]:SetTexCoord(0.25, 0.5, 0, 0.5)
		
		cornerTextures[3]:SetPoint("TOPRIGHT", Minimap, "CENTER")
		cornerTextures[3]:SetTexCoord(0, 0.25, 0.5, 1)
		
		cornerTextures[4]:SetPoint("TOPLEFT", Minimap, "CENTER")
		cornerTextures[4]:SetTexCoord(0.25, 0.5, 0.5, 1)
	end
	
	local borderStyle = borderStyles[self.db.profile.borderStyle] or borderStyles.Blizzard
	local texture = borderStyle and borderStyle[2] or [[Interface\AddOns\Chinchilla\Appearance\Border-Blizzard]]
	for i,v in ipairs(cornerTextures) do
		v:SetTexture(texture)
		local x_offset = roundShapes[i][shape] and 0 or 0.5
		v:SetTexCoord(((i-1) % 2) / 4 + x_offset, ((i-1) % 2) / 4 + 0.25 + x_offset, math.floor((i-1) / 2) / 2, math.floor((i-1) / 2) / 2 + 0.5)
	end
	
	Minimap:SetMaskTexture([[Interface\AddOns\Chinchilla\Appearance\Masks\Mask-]] .. shape)
	
	if Chinchilla:HasModule("MoveButtons") then
		Chinchilla:GetModule("MoveButtons"):Update()
	end
end

function Chinchilla_Appearance:SetBorderStyle(style)
	if style then
		self.db.profile.borderStyle = style
	else
		return
	end
	self:SetShape(nil)
end

function Chinchilla_Appearance:SetBorderRadius(value)
	if value then
		self.db.profile.borderRadius = value
	else
		return
	end
	if cornerTextures[1] then
		for i,v in ipairs(cornerTextures) do
			v:SetWidth(value)
			v:SetHeight(value)
		end
	end
end

function Chinchilla_Appearance:SetBorderColor(r, g, b, a)
	if r and g and b and a then
		self.db.profile.borderColor[1] = r
		self.db.profile.borderColor[2] = g
		self.db.profile.borderColor[3] = b
		self.db.profile.borderColor[4] = a
	else
		r = self.db.profile.borderColor[1]
		g = self.db.profile.borderColor[2]
		b = self.db.profile.borderColor[3]
		a = self.db.profile.borderColor[4]
	end
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	
	for i,v in ipairs(cornerTextures) do
		v:SetVertexColor(r, g, b, a)
	end
end

local buttonBorderTextures = {
	MiniMapBattlefieldBorder,
	MiniMapWorldBorder,
	MiniMapMailBorder,
	MiniMapMeetingStoneBorder,
--	GameTimeFrame,
	MiniMapTrackingBorder,
	MiniMapVoiceChatFrameBorder,
--	MinimapZoomIn,
--	MinimapZoomOut
}
function Chinchilla_Appearance:SetButtonBorderAlpha(alpha)
	if alpha then
		self.db.profile.buttonBorderAlpha = alpha
	else
		alpha = self.db.profile.buttonBorderAlpha
	end
	if not Chinchilla:IsModuleActive(self) then
		alpha = 1
	end
	
	for i,v in ipairs(buttonBorderTextures) do
		v:SetAlpha(alpha)
	end
end

local shape_choices = {
	["ROUND"] = L["Round"],
	["SQUARE"] = L["Square"],
	["CORNER-TOPRIGHT"] = L["Corner, top-right rounded"],
	["CORNER-TOPLEFT"] = L["Corner, top-left rounded"],
	["CORNER-BOTTOMRIGHT"] = L["Corner, bottom-right rounded"],
	["CORNER-BOTTOMLEFT"] = L["Corner, bottom-left rounded"],
	["SIDE-TOP"] = L["Side, top rounded"],
	["SIDE-RIGHT"] = L["Side, right rounded"],
	["SIDE-BOTTOM"] = L["Side, bottom rounded"],
	["SIDE-LEFT"] = L["Side, left rounded"],
	["TRICORNER-TOPRIGHT"] = L["Tri-corner, bottom-left square"],
	["TRICORNER-BOTTOMRIGHT"] = L["Tri-corner, top-left square"],
	["TRICORNER-BOTTOMLEFT"] = L["Tri-corner, top-right square"],
	["TRICORNER-TOPLEFT"] = L["Tri-corner, bottom-right square"],
}

local shape_choices_alt = {
	["ROUND"] = L["Round"],
	["SQUARE"] = L["Square"],
}

Chinchilla_Appearance:AddChinchillaOption({
	name = L["Appearance"],
	desc = Chinchilla_Appearance.desc,
	type = 'group',
	args = {
		scale = {
			name = L["Size"],
			desc = L["Set how large the minimap is"],
			type = 'number',
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.scale
			end,
			set = "SetScale",
			isPercent = true,
		},
		alpha = {
			name = L["Opacity"],
			desc = L["Set how transparent or opaque the minimap is when not in combat"],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.alpha
			end,
			set = "SetAlpha",
			isPercent = true,
		},
		combatAlpha = {
			name = L["Combat opacity"],
			desc = L["Set how transparent or opaque the minimap is when in combat"],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.combatAlpha
			end,
			set = "SetCombatAlpha",
			isPercent = true,
		},
		strata = {
			name = L["Strata"],
			desc = L["Set which layer the minimap is layered on in relation to others in your interface."],
			type = 'choice',
			choices = {
				BACKGROUND = L["Background"],
				LOW = L["Low"],
				MEDIUM = L["Medium"],
				HIGH = L["High"],
				DIALOG = L["Dialog"],
				FULLSCREEN = L["Fullscreen"],
				FULLSCREEN_DIALOG = L["Fullscreen-dialog"],
				TOOLTIP = L["Tooltip"]
			},
			choiceOrder = {
				"BACKGROUND",
				"LOW",
				"MEDIUM",
				"HIGH",
				"DIALOG",
				"FULLSCREEN",
				"FULLSCREEN_DIALOG",
				"TOOLTIP"
			},
			get = function()
				return Chinchilla_Appearance.db.profile.strata
			end,
			set = "SetFrameStrata",
		},
		frameLevel = {
			name = L["Frame level"],
			desc = L["Set which frame level the minimap is layered on in relation to others in your interface."],
			type = 'number',
			min = 0,
			max = 50,
			step = 1,
			get = function()
				return Chinchilla_Appearance.db.profile.frameLevel
			end,
			set = "SetFrameLevel",
		},
		shape = {
			name = L["Shape"],
			desc = L["Set the shape of the minimap."],
			type = 'choice',
			choices = function()
				return rotateMinimap and shape_choices_alt or shape_choices
			end,
			get = function()
				local shape = Chinchilla_Appearance.db.profile.shape
				if rotateMinimap then
					if shape == "SQUARE" then
						return "SQUARE"
					else
						return "ROUND"
					end
				else
					return shape
				end
			end,
			set = "SetShape",
		},
		borderAlpha = {
			name = L["Border color"],
			desc = L["Set the color the minimap border is."],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(Chinchilla_Appearance.db.profile.borderColor)
			end,
			set = "SetBorderColor",
		},
		borderStyle = {
			name = L["Border style"],
			desc = L["Set what texture style you want the minimap border to use."],
			type = 'choice',
			choices = function()
				local t = newDict()
				for k,v in pairs(borderStyles) do
					t[k] = v[1]
				end
				return "@dict", unpackDictAndDel(t)
			end,
			get = function()
				return Chinchilla_Appearance.db.profile.borderStyle
			end,
			set = "SetBorderStyle",
		},
		borderRadius = {
			name = L["Border radius"],
			desc = L["Set how large the border texture is."],
			type = 'number',
			min = 50,
			max = 200,
			step = 1,
			bigStep = 5,
			get = function()
				return Chinchilla_Appearance.db.profile.borderRadius
			end,
			set = "SetBorderRadius",
		},
		buttonBorderAlpha = {
			name = L["Button border opacity"],
			desc = L["Set how transparent or opaque the minimap button borders are."],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.buttonBorderAlpha
			end,
			set = "SetButtonBorderAlpha",
			isPercent = true,
		}
	}
})

function _G.GetMinimapShape()
	if Chinchilla_Appearance:IsActive() and not rotateMinimap then
		return self.db.profile.shape
	else
		if self.db.profile.shape == "SQUARE" then
			return "SQUARE"
		else
			return "ROUND"
		end
	end
end
