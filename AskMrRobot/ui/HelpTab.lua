local _, AskMrRobot = ...
local L = AskMrRobot.L;

-- initialize the HelpTab class
AskMrRobot.HelpTab = AskMrRobot.inheritsFrom(AskMrRobot.Frame)

function AskMrRobot.HelpTab:new(parent)

	local tab = AskMrRobot.Frame:new(nil, parent)
	setmetatable(tab, { __index = AskMrRobot.HelpTab })
	tab:SetPoint("TOPLEFT")
	tab:SetPoint("BOTTOMRIGHT")
	tab:Hide()

	local text = tab:CreateFontString("AmrHelpText1", "ARTWORK", "GameFontNormalLarge")
	text:SetPoint("TOPLEFT", 0, -5)
	text:SetText(L.AMR_HELPTAB_TITLE)

	local text2 = tab:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	text2:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -20)
	text2:SetPoint("RIGHT", tab, "RIGHT", -25, -20)
	text2:SetWidth(text2:GetWidth())
	text2:SetText(L.AMR_HELPTAB_LINK ..
                  L.AMR_HELPTAB_Q1 ..
                  L.AMR_HELPTAB_A1 ..
				  L.AMR_HELPTAB_Q2 ..
                  L.AMR_HELPTAB_A2 ..
                  L.AMR_HELPTAB_Q3 ..
                  L.AMR_HELPTAB_A3 ..
                  L.AMR_HELPTAB_Q4 ..
                  L.AMR_HELPTAB_A4 ..
                  L.AMR_HELPTAB_Q5 ..
                  L.AMR_HELPTAB_A5)
	--text2:SetHeight(100)
	text2:SetJustifyH("LEFT")

	return tab
end