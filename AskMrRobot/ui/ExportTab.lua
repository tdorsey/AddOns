local _, AskMrRobot = ...
local L = AskMrRobot.L;

-- initialize the ExportTab class
AskMrRobot.ExportTab = AskMrRobot.inheritsFrom(AskMrRobot.Frame)

-- helper to create text for this tab
local function CreateText(state, tab, font, relativeTo, xOffset, yOffset, text)
    local t = tab:CreateFontString(nil, "ARTWORK", font)
	t:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", xOffset, yOffset)
	t:SetPoint("RIGHT", tab, "RIGHT", -25, 0)
	t:SetWidth(t:GetWidth())
	t:SetJustifyH("LEFT")
	t:SetText(text)
    
    if (state ~= nil) then
        table.insert(state, t)
    end
    
    return t
end

function AskMrRobot.ExportTab:new(parent)

	local tab = AskMrRobot.Frame:new(nil, parent)	
	setmetatable(tab, { __index = AskMrRobot.ExportTab })
	tab:SetPoint("TOPLEFT")
	tab:SetPoint("BOTTOMRIGHT")
	tab:Hide()
    
    -- used to toggle between the two states... could use like, tabs or a UI panel or something, but then I would have to read more pseudo-documentation.
    tab.manualElements = {}
    tab.autoElements = {}

	local text = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetPoint("TOPLEFT", 0, -5)
	text:SetText(L.AMR_EXPORTTAB_EXPORT_BB)  
    
    local chooseText = CreateText(nil, tab, "GameFontWhite", text, 0, -15, "Choose a method:")
	chooseText:SetJustifyV("MIDDLE")
    chooseText:SetHeight(30)
    
    local btn = CreateFrame("Button", "AmrExportManual", tab, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 125, -15)
	btn:SetText(L.AMR_EXPORTTAB_COPY_PASTE)
	btn:SetWidth(120)
	btn:SetHeight(30)
    tab.btnManual = btn
    
    btn:SetScript("OnClick", function()
        AmrOptions.exportToClient = false
        tab:Update()
    end)
    
    btn = CreateFrame("Button", "AmrExportAuto", tab, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 275, -15)
	btn:SetText(L.AMR_EXPORTTAB_AMR_CLIENT)
	btn:SetWidth(120)
	btn:SetHeight(30)
    tab.btnAuto = btn
    
    btn:SetScript("OnClick", function()
        AmrOptions.exportToClient = true
        tab:Update()
    end)
    
    -- copy/paste
    text = CreateText(tab.manualElements, tab, "GameFontNormalLarge", chooseText, 0, -20, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT)
    local text2 = CreateText(tab.manualElements, tab, "GameFontWhite", text, 0, -15, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT_1)
    text = CreateText(tab.manualElements, tab, "GameFontWhite", text2, 0, -15, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT_2)

	local txtExportString = CreateFrame("ScrollFrame", "AmrScrollFrame", tab, "InputScrollFrameTemplate")
	txtExportString:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 12, -10)
	txtExportString:SetPoint("RIGHT", -25, 0)
	txtExportString:SetWidth(txtExportString:GetWidth())
	txtExportString:SetHeight(50)
	txtExportString.EditBox:SetWidth(txtExportString:GetWidth())
    txtExportString.EditBox:SetMaxLetters(0)
	txtExportString.CharCount:Hide()
	tab.txtExportString = txtExportString
    table.insert(tab.manualElements, txtExportString)
    
    txtExportString.EditBox:SetScript("OnEscapePressed", function()
        AskMrRobot_ReforgeFrame:Hide()
    end)
    
    text = CreateText(tab.manualElements, tab, "GameFontWhite", txtExportString, -12, -20, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT_3)
    text2 = CreateText(tab.manualElements, tab, "GameFontWhite", text, 10, -5, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT_4)

    local image = tab:CreateTexture(nil, "BACKGROUND")
	image:SetPoint("TOPLEFT", text2, "BOTTOMLEFT", 2, -10)
	image:SetTexture("Interface\\AddOns\\AskMrRobot\\Media\\BiBScreen")
    table.insert(tab.manualElements, image)
    
    text = CreateText(tab.manualElements, tab, "GameFontWhite", text2, 0, -120, L.AMR_EXPORTTAB_COPY_PASTE_EXPORT_NOTE)
    
    btn = CreateFrame("Button", "AmrUpdateExportString", tab, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -5)
	btn:SetText("Update")
	btn:SetWidth(120)
	btn:SetHeight(25)
    table.insert(tab.manualElements, btn)
    
    btn:SetScript("OnClick", function()
        tab:Update()
    end)
    
    -- amr client
    text = CreateText(tab.autoElements, tab, "GameFontNormalLarge", chooseText, 0, -20, L.AMR_EXPORTTAB_AMR_CLIENT_EXPORT)
    text2 = CreateText(tab.autoElements, tab, "GameFontWhite", text, 0, -15, L.AMR_EXPORTTAB_AMR_CLIENT_EXPORT_1)
    text = CreateText(tab.autoElements, tab, "GameFontWhite", text2, 0, -15, L.AMR_EXPORTTAB_AMR_CLIENT_EXPORT_2)

    btn = CreateFrame("Button", "AmrExportFile", tab, "UIPanelButtonTemplate")
	btn:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 12, -10)
	btn:SetText("Export to File")
	btn:SetWidth(180)
	btn:SetHeight(25)
    table.insert(tab.autoElements, btn)
    
    btn:SetScript("OnClick", function()
        AskMrRobot.SaveAll()
        ReloadUI()
    end)

    text = CreateText(tab.autoElements, tab, "GameFontWhite", btn, -12, -20, L.AMR_EXPORTTAB_AMR_CLIENT_EXPORT_3)
    text2 = CreateText(tab.autoElements, tab, "GameFontWhite", text, 10, -5, L.AMR_EXPORTTAB_AMR_CLIENT_EXPORT_4)

    image = tab:CreateTexture(nil, "BACKGROUND")
	image:SetPoint("TOPLEFT", text2, "BOTTOMLEFT", 2, -10)
	image:SetTexture("Interface\\AddOns\\AskMrRobot\\Media\\BiBScreen")
    table.insert(tab.autoElements, image)

    tab:SetScript("OnShow", function()
        tab:Update()
	end)
    
	return tab
end

-- update the panel and state
function AskMrRobot.ExportTab:Update()

    if (AmrOptions.exportToClient) then
        for i, v in ipairs(self.manualElements) do v:Hide() end
        for i, v in ipairs(self.autoElements) do v:Show() end
        self.btnManual:UnlockHighlight()
        self.btnAuto:LockHighlight()
    else
        for i, v in ipairs(self.autoElements) do v:Hide() end
        for i, v in ipairs(self.manualElements) do v:Show() end
        self.btnAuto:UnlockHighlight()
        self.btnManual:LockHighlight()
        
        AskMrRobot.SaveAll()
        self.txtExportString.EditBox:SetText(AskMrRobot.ExportToString())
        self.txtExportString.EditBox:HighlightText()
        self.txtExportString.EditBox:SetFocus()
    end
end
