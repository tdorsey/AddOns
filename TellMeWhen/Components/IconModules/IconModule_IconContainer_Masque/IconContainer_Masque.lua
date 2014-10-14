﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))


local IconContainer_Masque = TMW:NewClass("IconModule_IconContainer_Masque", "IconModule_IconContainer")


if LibStub("LibButtonFacade", true) and select(6, GetAddOnInfo("Masque")) == "MISSING" then
	TMW.Warn("TellMeWhen no longer supports ButtonFacade. If you wish to continue to skin your icons, please upgrade to ButtonFacade's successor, Masque.")
end


local function GetLMBGroup(icon)
	if icon.group.Domain == "global" then
		return LMB:Group("TellMeWhen", L["DOMAIN_GLOBAL"] .. " " .. L["fGROUP"]:format(icon.group:GetID()))
	else
		return LMB:Group("TellMeWhen", L["fGROUP"]:format(icon.group:GetID()))
	end
end

--- Static method to check if a given icon will be skinned.
function IconContainer_Masque:IsIconSkinned(icon)
	self:AssertSelfIsClass()

	if not LMB then
		return false
	end

	local lmbGroup = GetLMBGroup(icon)
	return lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled)
end



if not LMB then
	IconContainer_Masque.isDefaultSkin = 1
	-- IconModule_IconContainer_Masque will just be a clone of IconModule_IconContainer at this point.
	-- No need to load any of the Masque-handling code it Masque isn't installed, so just leave it as a clone.
	return
end





if LMB.GetSpellAlert then
	-- Copied (and slightly modified) from masque so that TMW's activation borders will get skinned properly when they aren't square.
	IconContainer_Masque:PostHookMethod("ShowOverlayGlow", function(self)
		local self = self.container
		local Overlay = self.overlay
		if not Overlay or not Overlay.spark then return end
		if Overlay.__MSQ_Shape ~= self.__MSQ_Shape then
			local Shape = self.__MSQ_Shape

			local Glow, Ants
			if Shape then
				Glow, Ants = LMB:GetSpellAlert(Shape)
			end
			if not (Shape and (Glow or Ants)) then
				Glow, Ants = LMB:GetSpellAlert("Square")
			end

			Overlay.innerGlow:SetTexture(Glow)
			Overlay.innerGlowOver:SetTexture(Glow)
			Overlay.outerGlow:SetTexture(Glow)
			Overlay.outerGlowOver:SetTexture(Glow)
			Overlay.spark:SetTexture(Glow)
			Overlay.ants:SetTexture(Ants)
			Overlay.__MSQ_Shape = self.__MSQ_Shape
		end
	end)
end

function IconContainer_Masque:OnNewInstance_IconContainer_Masque(icon)
	self.lmbGroup = GetLMBGroup(icon)
end

function IconContainer_Masque:SetupForIcon(icon)
	if icon ~= self.icon then
		local icnt = icon.normaltex
		local iconnt = self.icon.normaltex
		if icnt and iconnt then
			iconnt:SetVertexColor(icnt:GetVertexColor())
		end
	end
end



IconContainer_Masque:PostHookMethod("OnEnable", function(self)
	local icon = self.icon
	local container = self.container
	
	-- I really really hate the fact that this exists. But, oh well. At least it works more than 26.8% of the time.
	self.isDefaultSkin = nil
	
	local lmbGroup = self.lmbGroup
	
	local disabled = lmbGroup.Disabled or (lmbGroup.db and lmbGroup.db.Disabled)
	
	if self.hasSkinned then
		lmbGroup:AddButton(container, icon.lmbButtonData)
	end
	if disabled then
		if self.hasSkinned then
			lmbGroup:RemoveButton(container)
		end
		--self.isDefaultSkin = 1
	elseif not self.hasSkinned then
		lmbGroup:AddButton(container, icon.lmbButtonData)
		self.hasSkinned = true
	end
	
	icon.normaltex = container.__MSQ_NormalTexture or container:GetNormalTexture()
	
	if disabled and not icon.normaltex then
		self.isDefaultSkin = 1
	end
end)

IconContainer_Masque:PostHookMethod("OnDisable", function(self)
	self.lmbGroup:RemoveButton(self.container, true)
	
	self.isDefaultSkin = 1
end)

