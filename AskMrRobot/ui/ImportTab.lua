local _, AskMrRobot = ...
local L = AskMrRobot.L;

-- initialize the ImportTab class
AskMrRobot.ImportTab = AskMrRobot.inheritsFrom(AskMrRobot.Frame)

function AskMrRobot.ImportTab:new(parent)

	local tab = AskMrRobot.Frame:new(nil, parent)
	setmetatable(tab, { __index = AskMrRobot.ImportTab })
	tab:SetPoint("TOPLEFT")
	tab:SetPoint("BOTTOMRIGHT")
	tab:Hide()

	-- import button
	tab.button = CreateFrame("Button", "AmrImportButton", tab, "UIPanelButtonTemplate")	
	tab.button:SetPoint("BOTTOM")
	tab.button:SetText(L.AMR_IMPORTTAB_BUTTON)
	tab.button:SetWidth(100)
	tab.button:SetHeight(20)
	tab.button:SetPoint("BOTTOM", 0, 15)

	local text = tab:CreateFontString("AmrImportText1", "ARTWORK", "GameFontNormalLarge")
	text:SetPoint("TOPLEFT", 0, -5)
	text:SetFormattedText(L.AMR_IMPORTTAB_TITLE)

	text = tab:CreateFontString("AmrImportText2", "ARTWORK", "GameFontWhite")
	text:SetPoint("TOPLEFT", "AmrImportText1", "BOTTOMLEFT", 0, -20)
	text:SetPoint("RIGHT", 0, -20)
	text:SetWidth(text:GetWidth())
	text:SetJustifyH("LEFT")
	text:SetText(L.AMR_IMPORTTAB_INSTRUCTIONS_1)

	local image = tab:CreateTexture(nil, "BACKGROUND")
	image:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 16, -10)
	image:SetTexture("Interface\\AddOns\\AskMrRobot\\Media\\AddonExport")
	image:SetSize(256, 256)

	text = tab:CreateFontString("AmrImportText3", "ARTWORK", "GameFontWhite")
	text:SetPoint("TOPLEFT", image, "BOTTOMLEFT", -16, 24)
	text:SetPoint("RIGHT", -15, 40)
	text:SetWidth(text:GetWidth())
	text:SetJustifyH("LEFT")
	text:SetText(L.AMR_IMPORTTAB_INSTRUCTIONS_2)

	local scrollFrame = CreateFrame("ScrollFrame", "AmrImportScrollFrame", tab, "InputScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 5, -10)
	scrollFrame:SetPoint("BOTTOM", "AmrImportButton", "TOP", 0, 10)
	scrollFrame:SetPoint("RIGHT", -30, 0)
	scrollFrame:SetWidth(430)
	scrollFrame.EditBox:SetWidth(scrollFrame:GetWidth())
	scrollFrame.EditBox:SetMaxLetters(1100)
	scrollFrame.CharCount:Hide()
	scrollFrame.EditBox.PromptText:SetText(L.AMR_IMPORTTAB_INSTRUCTIONS_3)
	scrollFrame.EditBox:SetFocus()
	scrollFrame.EditBox:HighlightText()
	tab.scrollFrame = scrollFrame
	
	tab:SetScript("OnShow", function()
		tab.scrollFrame.EditBox:HighlightText()
		tab.scrollFrame.EditBox:SetFocus()
	end)

	return tab	
end
