local addonName, AskMrRobot = ...

--if not addon.healthCheck then return end
local L = AskMrRobot.L

local wow_ver = select(4, GetBuildInfo())
local wow_500 = wow_ver >= 50000
local UIPanelButtonTemplate = wow_500 and "UIPanelButtonTemplate" or "UIPanelButtonTemplate2"

local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = addonName
frame:Hide()

-- Credits to Ace3, Tekkub, cladhaire and Tuller for some of the widget stuff.

local function newCheckbox(label, tooltipTitle, description, onClick)
	local check = CreateFrame("CheckButton", "AmrCheck" .. label, frame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnClick", function(self)
		PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		onClick(self, self:GetChecked() and true or false)
	end)
	check.label = _G[check:GetName() .. "Text"]
	check.label:SetText(label)
	check.tooltipText = tooltipTitle
	check.tooltipRequirement = description
	return check
end

frame:SetScript("OnShow", function(frame)
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)

	local subTitleWrapper = CreateFrame("Frame", nil, frame)
	subTitleWrapper:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subTitleWrapper:SetPoint("RIGHT", -16, 0)
	local subtitle = subTitleWrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", subTitleWrapper)
	subtitle:SetWidth(subTitleWrapper:GetRight() - subTitleWrapper:GetLeft())
	subtitle:SetJustifyH("LEFT")
	subtitle:SetNonSpaceWrap(false)
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L.AMR_CONFIG_EXIMPORT)
	subTitleWrapper:SetHeight(subtitle:GetHeight())

	local autoPopup = newCheckbox(
		L.AMR_CONFIG_CHECKBOX_MINIMAP_LABEL,
		L.AMR_CONFIG_CHECKBOX_MINIMAP_TOOLTIP_TITLE,
		L.AMR_CONFIG_CHECKBOX_MINIMAP_DESCRIPTION,
		function(self, value) 
			if AmrOptions.hideMapIcon then
				AmrOptions.hideMapIcon = false
			else
				AmrOptions.hideMapIcon = true
			end
			AskMrRobot.AmrUpdateMinimap();
		end
	)
	autoPopup:SetChecked(not AmrOptions.hideMapIcon)
	autoPopup:SetPoint("TOPLEFT", subTitleWrapper, "BOTTOMLEFT", -2, -16)

	local autoReforge = newCheckbox(
		L.AMR_CONFIG_CHECKBOX_AUTOREFORGE_LABEL,
		L.AMR_CONFIG_CHECKBOX_AUTOREFORGE_TOOLTIP_TITLE,
		L.AMR_CONFIG_CHECKBOX_AUTOREFORGE_DESCRIPTION,
		function(self, value) 
			if AmrOptions.manualShowReforge then
				AmrOptions.manualShowReforge = false
			else
				AmrOptions.manualShowReforge = true
			end
		end
	)
	autoReforge:SetChecked(not AmrOptions.manualShowReforge)
	autoReforge:SetPoint("TOPLEFT", subTitleWrapper, "BOTTOMLEFT", -2, -52)

	local autoAh = newCheckbox(
		L.AMR_CONFIG_CHECKBOX_AUTOAH_LABEL,
		L.AMR_CONFIG_CHECKBOX_AUTOAH_TOOLTIP_TITLE,
		L.AMR_CONFIG_CHECKBOX_AUTOAH_DESCRIPTION,
		function(self, value) 
			if AmrOptions.manualShowShop then
				AmrOptions.manualShowShop = false
			else
				AmrOptions.manualShowShop = true
			end
		end
	)
	autoAh:SetChecked(not AmrOptions.manualShowShop)
	autoAh:SetPoint("TOPLEFT", subTitleWrapper, "BOTTOMLEFT", -2, -88)

	--[[
	AmrOptions.autoLog = AmrOptions.autoLog or {}

	local autoCombatLog = newCheckbox(
		L.AMR_CONFIG_CHECKBOX_AUTOLOG_LABEL,
		L.AMR_CONFIG_CHECKBOX_AUTOLOG_TOOLTIP_TITLE,
		L.AMR_CONFIG_CHECKBOX_AUTOLOG_DESCRIPTION,
		function(self, value)
			if AmrOptions.autoLog[1136] then
				AmrOptions.autoLog[1136] = false
			else
				AmrOptions.autoLog[1136] = true
			end
		end
	)
	autoCombatLog:SetChecked(AmrOptions.autoLog[1136])
	autoCombatLog:SetPoint("TOPLEFT", subTitleWrapper, "BOTTOMLEFT", -2, -124)
	]]

	frame:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(frame)

