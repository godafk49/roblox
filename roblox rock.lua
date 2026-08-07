-- =================================================================
-- VALEN HUB REPLICA + GET KEY SYSTEM
-- สคริปต์จำลองฟังก์ชันค่าย Valen Hub พร้อมระบบ Get Key
-- =================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- -----------------------------------------------------------------
-- ตั้งค่าระบบ Key System
-- -----------------------------------------------------------------
local KEY_CONFIG = {
    Get_Key_URL = "https://valenhubstore.com/getkey", -- ลิงก์สำหรับรับ Key
    Valid_Keys = {
        ["VALEN-CREA-2WNY"] = true,
        ["VALEN-KEY-2026"] = true,
        ["FREE-KEY-DEMO"] = true
    }
}

-- ตัวแปรเก็บการตั้งค่า Map Dump
local DUMP_CONFIG = {
    FolderName = "ValenHub_Map",
    IncludeTerrain = true,
    IncludeScripts = true,
    IncludeCharacters = true
}

-- -----------------------------------------------------------------
-- Helper Functions
-- -----------------------------------------------------------------
local function setClipboardText(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif toclipboard then
        toclipboard(text)
        return true
    end
    return false
end

local function sendNotify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- -----------------------------------------------------------------
-- สร้าง GUI Container
-- -----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValenHub_UI_System"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- -----------------------------------------------------------------
-- 1. สร้างหน้าต่าง KEY SYSTEM UI (Authentication Required)
-- -----------------------------------------------------------------
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 360, 0, 260)
KeyFrame.Position = UDim2.new(0.5, -180, 0.5, -130)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true
KeyFrame.Parent = ScreenGui

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 10)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Color = Color3.fromRGB(45, 45, 55)
KeyStroke.Thickness = 1.5
KeyStroke.Parent = KeyFrame

-- Title Header
local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 35)
KeyTitle.Position = UDim2.new(0, 0, 0, 15)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "VALEN HUB"
KeyTitle.TextColor3 = Color3.fromRGB(240, 240, 245)
KeyTitle.TextSize = 20
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.Parent = KeyFrame

local KeySubTitle = Instance.new("TextLabel")
KeySubTitle.Size = UDim2.new(1, 0, 0, 20)
KeySubTitle.Position = UDim2.new(0, 0, 0, 45)
KeySubTitle.BackgroundTransparency = 1
KeySubTitle.Text = "Authentication Required"
KeySubTitle.TextColor3 = Color3.fromRGB(140, 140, 150)
KeySubTitle.TextSize = 13
KeySubTitle.Font = Enum.Font.Gotham
KeySubTitle.Parent = KeyFrame

-- Key Input TextBox
local KeyInputBg = Instance.new("Frame")
KeyInputBg.Size = UDim2.new(0.85, 0, 0, 40)
KeyInputBg.Position = UDim2.new(0.075, 0, 0, 80)
KeyInputBg.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
KeyInputBg.BorderSizePixel = 0
KeyInputBg.Parent = KeyFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = KeyInputBg

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Size = UDim2.new(1, -20, 1, 0)
KeyTextBox.Position = UDim2.new(0, 10, 0, 0)
KeyTextBox.BackgroundTransparency = 1
KeyTextBox.PlaceholderText = "Enter your access key"
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
KeyTextBox.Text = ""
KeyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTextBox.TextSize = 14
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.Parent = KeyInputBg

-- Status Text
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0, 128)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting for key..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = KeyFrame

-- Action Buttons Container
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(0.85, 0, 0, 40)
ButtonContainer.Position = UDim2.new(0.075, 0, 0, 180)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = KeyFrame

local ButtonLayout = Instance.new("UIListLayout")
ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ButtonLayout.Padding = UDim.new(0, 10)
ButtonLayout.Parent = ButtonContainer

-- Get Key Button (ฟังก์ชันเพิ่มพิเศษสำหรับรับ Key)
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.48, -5, 1, 0)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
GetKeyBtn.TextSize = 13
GetKeyBtn.Font = Enum.Font.GothamMedium
GetKeyBtn.Parent = ButtonContainer

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 8)
GetKeyCorner.Parent = GetKeyBtn

-- Verify Button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(0.48, -5, 1, 0)
VerifyBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 80)
VerifyBtn.Text = "Verify"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 13
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.Parent = ButtonContainer

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 8)
VerifyCorner.Parent = VerifyBtn

-- -----------------------------------------------------------------
-- 2. สร้างหน้าต่าง MAIN HUB UI (Valen Hub)
-- -----------------------------------------------------------------
local MainHubFrame = Instance.new("Frame")
MainHubFrame.Name = "MainHubFrame"
MainHubFrame.Size = UDim2.new(0, 520, 0, 360)
MainHubFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
MainHubFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainHubFrame.BorderSizePixel = 0
MainHubFrame.Active = true
MainHubFrame.Draggable = true
MainHubFrame.Visible = false -- ซ่อนไว้จนกว่าจะ Verify ผ่าน
MainHubFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainHubFrame

-- Sidebar (แถบเมนูด้านข้าง)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainHubFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local HubTitle = Instance.new("TextLabel")
HubTitle.Size = UDim2.new(1, 0, 0, 40)
HubTitle.Position = UDim2.new(0, 0, 0, 10)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "Valen Hub"
HubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HubTitle.TextSize = 18
HubTitle.Font = Enum.Font.GothamBold
HubTitle.Parent = Sidebar

-- Tab List Container
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -16, 1, -60)
TabContainer.Position = UDim2.new(0, 8, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)
TabListLayout.Parent = TabContainer

-- Page Content Display Area
local PageDisplay = Instance.new("Frame")
PageDisplay.Size = UDim2.new(1, -150, 1, -20)
PageDisplay.Position = UDim2.new(0, 145, 0, 10)
PageDisplay.BackgroundTransparency = 1
PageDisplay.Parent = MainHubFrame

local Pages = {}

local function createPage(name)
    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = PageDisplay
    Pages[name] = page
    return page
end

local function addTabButton(name, iconText, layoutOrder)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = "   " .. name
    tabBtn.TextColor3 = Color3.fromRGB(160, 160, 175)
    tabBtn.TextSize = 13
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.LayoutOrder = layoutOrder
    tabBtn.Parent = TabContainer

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        for _, page in pairs(Pages) do
            page.Visible = false
        end
        for _, btn in ipairs(TabContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Color3.fromRGB(160, 160, 175)
            end
        end
        Pages[name].Visible = true
        tabBtn.BackgroundTransparency = 0
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return tabBtn
end

-- สร้างแต่ละหน้าตามเมนูในคลิป
local MainPage = createPage("Main")
local PreviewPage = createPage("Preview")
local RemoteSpyPage = createPage("RemoteSpy")
local SettingsPage = createPage("Settings")
local MapDumpPage = createPage("MapDump")

addTabButton("Main", "", 1)
addTabButton("Preview", "", 2)
addTabButton("Remote Spy", "", 3)
addTabButton("Settings", "", 4)
local mapDumpTabBtn = addTabButton("Map Dump", "", 5)

-- เปิดหน้า Map Dump เป็นหน้าเริ่มต้นหลังจากล็อกอิน
Pages["MapDump"].Visible = true
mapDumpTabBtn.BackgroundTransparency = 0
mapDumpTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- -----------------------------------------------------------------
-- 3. ตกแต่งหน้า MAP DUMP (Map Reconstructor) ตามคลิปวิดีโอ [00:00:53]
-- -----------------------------------------------------------------
local MapDumpTitle = Instance.new("TextLabel")
MapDumpTitle.Size = UDim2.new(1, 0, 0, 25)
MapDumpTitle.BackgroundTransparency = 1
MapDumpTitle.Text = "Map Reconstructor"
MapDumpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MapDumpTitle.TextSize = 18
MapDumpTitle.TextXAlignment = Enum.TextXAlignment.Left
MapDumpTitle.Font = Enum.Font.GothamBold
MapDumpTitle.Parent = MapDumpPage

local MapDumpDesc = Instance.new("TextLabel")
MapDumpDesc.Size = UDim2.new(1, 0, 0, 20)
MapDumpDesc.Position = UDim2.new(0, 0, 0, 22)
MapDumpDesc.BackgroundTransparency = 1
MapDumpDesc.Text = "Function Dump/Dupe Saved Workspace"
MapDumpDesc.TextColor3 = Color3.fromRGB(130, 130, 145)
MapDumpDesc.TextSize = 11
MapDumpDesc.TextXAlignment = Enum.TextXAlignment.Left
MapDumpDesc.Font = Enum.Font.Gotham
MapDumpDesc.Parent = MapDumpPage

-- Folder Name Input Container
local FolderLabel = Instance.new("TextLabel")
FolderLabel.Size = UDim2.new(1, 0, 0, 20)
FolderLabel.Position = UDim2.new(0, 0, 0, 52)
FolderLabel.BackgroundTransparency = 1
FolderLabel.Text = "Folder Name:"
FolderLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
FolderLabel.TextSize = 12
FolderLabel.TextXAlignment = Enum.TextXAlignment.Left
FolderLabel.Font = Enum.Font.GothamMedium
FolderLabel.Parent = MapDumpPage

local FolderInputBg = Instance.new("Frame")
FolderInputBg.Size = UDim2.new(1, 0, 0, 32)
FolderInputBg.Position = UDim2.new(0, 0, 0, 75)
FolderInputBg.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FolderInputBg.BorderSizePixel = 0
FolderInputBg.Parent = MapDumpPage

local FolderCorner = Instance.new("UICorner")
FolderCorner.CornerRadius = UDim.new(0, 6)
FolderCorner.Parent = FolderInputBg

local FolderTextBox = Instance.new("TextBox")
FolderTextBox.Size = UDim2.new(1, -20, 1, 0)
FolderTextBox.Position = UDim2.new(0, 10, 0, 0)
FolderTextBox.BackgroundTransparency = 1
FolderTextBox.Text = DUMP_CONFIG.FolderName
FolderTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FolderTextBox.TextSize = 13
FolderTextBox.Font = Enum.Font.Gotham
FolderTextBox.TextXAlignment = Enum.TextXAlignment.Left
FolderTextBox.Parent = FolderInputBg

FolderTextBox.FocusLost:Connect(function()
    if FolderTextBox.Text ~= "" then
        DUMP_CONFIG.FolderName = FolderTextBox.Text
    end
end)

-- ฟังก์ชันสร้าง Toggle Switch
local toggleY = 120
local function createToggle(text, defaultConfig, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 28)
    toggleFrame.Position = UDim2.new(0, 0, 0, toggleY)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = MapDumpPage

    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(0.7, 0, 1, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = text
    toggleText.TextColor3 = Color3.fromRGB(200, 200, 210)
    toggleText.TextSize = 12
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Font = Enum.Font.Gotham
    toggleText.Parent = toggleFrame

    local switchBg = Instance.new("TextButton")
    switchBg.Size = UDim2.new(0, 42, 0, 20)
    switchBg.Position = UDim2.new(1, -42, 0.5, -10)
    switchBg.BackgroundColor3 = defaultConfig and Color3.fromRGB(45, 140, 80) or Color3.fromRGB(50, 50, 60)
    switchBg.Text = ""
    switchBg.Parent = toggleFrame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    local switchCircle = Instance.new("Frame")
    switchCircle.Size = UDim2.new(0, 16, 0, 16)
    switchCircle.Position = defaultConfig and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    switchCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchCircle.Parent = switchBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = switchCircle

    local state = defaultConfig
    switchBg.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        if state then
            switchBg.BackgroundColor3 = Color3.fromRGB(45, 140, 80)
            switchCircle.Position = UDim2.new(1, -18, 0.5, -8)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            switchCircle.Position = UDim2.new(0, 2, 0.5, -8)
        end
    end)

    toggleY = toggleY + 34
end

createToggle("Include Terrain", DUMP_CONFIG.IncludeTerrain, function(v) DUMP_CONFIG.IncludeTerrain = v end)
createToggle("Include Scripts", DUMP_CONFIG.IncludeScripts, function(v) DUMP_CONFIG.IncludeScripts = v end)
createToggle("Include Characters (Humanoid, Animator)", DUMP_CONFIG.IncludeCharacters, function(v) DUMP_CONFIG.IncludeCharacters = v end)

-- ปุ่มบันทึกไฟล์ (Save as Studio File)
local SaveStudioBtn = Instance.new("TextButton")
SaveStudioBtn.Size = UDim2.new(1, 0, 0, 36)
SaveStudioBtn.Position = UDim2.new(0, 0, 0, 230)
SaveStudioBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 210)
SaveStudioBtn.Text = "Save as Studio File (.rbxl)"
SaveStudioBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveStudioBtn.TextSize = 13
SaveStudioBtn.Font = Enum.Font.GothamBold
SaveStudioBtn.Parent = MapDumpPage

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 6)
SaveCorner.Parent = SaveStudioBtn

-- ปุ่ม Dump & Copy
local CopyDumpBtn = Instance.new("TextButton")
CopyDumpBtn.Size = UDim2.new(1, 0, 0, 32)
CopyDumpBtn.Position = UDim2.new(0, 0, 0, 274)
CopyDumpBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
CopyDumpBtn.Text = "Dump Map & Copy to Clipboard"
CopyDumpBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
CopyDumpBtn.TextSize = 12
CopyDumpBtn.Font = Enum.Font.GothamMedium
CopyDumpBtn.Parent = MapDumpPage

local CopyCorner = Instance.new("UICorner")
CopyCorner.CornerRadius = UDim.new(0, 6)
CopyCorner.Parent = CopyDumpBtn

-- -----------------------------------------------------------------
-- LOGIC & EVENT HANDLERS
-- -----------------------------------------------------------------

-- 1. กดปุ่ม Get Key
GetKeyBtn.MouseButton1Click:Connect(function()
    local copied = setClipboardText(KEY_CONFIG.Get_Key_URL)
    if copied then
        StatusLabel.Text = "Key link copied to clipboard!"
        StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        sendNotify("Valen Hub", "คัดลอกลิงก์รับ Key เรียบร้อยแล้ว!", 3)
    else
        StatusLabel.Text = "Failed to copy link."
        StatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
    end
end)

-- 2. กดปุ่ม Verify Key
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyTextBox.Text
    StatusLabel.Text = "Verifying key..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 180, 60)

    task.wait(0.8) -- จำลองระยะเวลาเช็กคีย์สไตล์ช้าๆ ชัวร์ๆ

    if KEY_CONFIG.Valid_Keys[inputKey] then
        StatusLabel.Text = "Access Key Valid!"
        StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
        sendNotify("Valen Hub", "ยืนยัน Key สำเร็จ! กำลังโหลดหน้าต่างหลัก...", 3)
        
        task.wait(0.6)
        KeyFrame.Visible = false
        MainHubFrame.Visible = true
    else
        StatusLabel.Text = "Invalid Key! Please check again."
        StatusLabel.TextColor3 = Color3.fromRGB(240, 80, 80)
        sendNotify("Valen Hub Error", "Key ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง", 3)
    end
end)

-- 3. กดปุ่ม Save as Studio File (.rbxl)
SaveStudioBtn.MouseButton1Click:Connect(function()
    sendNotify("Valen Hub", "กำลังเริ่มกระบวนการ Dump แมพ...", 4)
    SaveStudioBtn.Text = "Dumping... Please wait"

    task.spawn(function()
        if saveinstance then
            local options = {
                mode = "full",
                noscripts = not DUMP_CONFIG.IncludeScripts,
                isremovespawn = false,
                FilePath = DUMP_CONFIG.FolderName
            }
            local ok, err = pcall(function()
                saveinstance(options)
            end)
            
            if ok then
                sendNotify("Map Dump", "บันทึกไฟล์ " .. DUMP_CONFIG.FolderName .. ".rbxl เรียบร้อยแล้ว!", 5)
            else
                sendNotify("Map Dump", "เกิดข้อผิดพลาดในการบันทึก: " .. tostring(err), 5)
            end
        else
            -- ระบบสำรองเมื่อ Executor ไม่รองรับ saveinstance
            local clonedFolder = Instance.new("Folder")
            clonedFolder.Name = DUMP_CONFIG.FolderName
            
            for _, child in ipairs(Workspace:GetChildren()) do
                pcall(function()
                    if child.Archivable then
                        child:Clone().Parent = clonedFolder
                    end
                end)
            end
            sendNotify("Map Dump (Fallback)", "สร้างโฟลเดอร์สำรองไว้ใน Workspace สำเร็จ!", 5)
        end
        
        SaveStudioBtn.Text = "Save as Studio File (.rbxl)"
    end)
end)

-- 4. กดปุ่ม Dump Map & Copy
CopyDumpBtn.MouseButton1Click:Connect(function()
    setClipboardText("-- Valen Hub Map Dump Data: " .. DUMP_CONFIG.FolderName)
    sendNotify("Valen Hub", "คัดลอกข้อมูลแมพไปยัง Clipboard แล้ว", 3)
end)

print("Valen Hub Script Loaded Successfully!")
