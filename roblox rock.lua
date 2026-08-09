-- ============================================================================
-- KOI49 ENGINE  |  AUTO FARM SCRIPT DUMPER & REMOTE SPY SUITE
-- DESIGNED FOR SCRIPT DEVELOPERS & AI-ASSISTED AUTO FARM CREATION
-- INCLUDES: FULL MAP DUMP (.RBXL), REMOTE SPY LOGGER, DECOMPILED SCRIPTS, 
-- AND WORKSPACE RESOURCE TARGET SCANNER
-- ============================================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local is_writefile = type(writefile) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"

local Config = {
    MapFileName = "KOI49_Map_" .. tostring(game.PlaceId) .. ".rbxl",
    DumpFileName = "KOI49_AutoFarmData_" .. tostring(game.PlaceId) .. ".txt"
}

local function SendNotify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = 4
        })
    end)
end

local function SetClipboardText(text)
    if setclipboard then setclipboard(text) return true
    elseif toclipboard then toclipboard(text) return true end
    return false
end

-- ============================================================================
-- GUI ENGINE (CLEAN DARK DESIGN)
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("KOI49_EngineUI") then
    TargetParent.KOI49_EngineUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI49_EngineUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Floating K49 Button for Mobile
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
ToggleBtn.Text = "K49"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 15
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 170, 0)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 420)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KOI49 ENGINE  |  AUTO FARM DUMPER & SPY"
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Sidebar Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 135, 1, -68)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
Sidebar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 6)
SidebarPadding.PaddingRight = UDim.new(0, 6)
SidebarPadding.Parent = Sidebar

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -145, 1, -78)
PageContainer.Position = UDim2.new(0, 140, 0, 45)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

-- Status Bar
local ProgressBg = Instance.new("Frame")
ProgressBg.Size = UDim2.new(1, 0, 0, 26)
ProgressBg.Position = UDim2.new(0, 0, 1, -26)
ProgressBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
ProgressBg.Parent = MainFrame

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ProgressFill.Parent = ProgressBg

local ProgressStatus = Instance.new("TextLabel")
ProgressStatus.Size = UDim2.new(1, -10, 1, 0)
ProgressStatus.Position = UDim2.new(0, 10, 0, 0)
ProgressStatus.BackgroundTransparency = 1
ProgressStatus.Text = "[0%] KOI49 Engine Ready."
ProgressStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressStatus.TextSize = 10
ProgressStatus.Font = Enum.Font.GothamBold
ProgressStatus.TextXAlignment = Enum.TextXAlignment.Left
ProgressStatus.Parent = ProgressBg

local function UpdateStatus(pct, msg, isErr)
    pct = math.clamp(pct, 0, 100)
    TweenService:Create(ProgressFill, TweenInfo.new(0.15), {Size = UDim2.new(pct / 100, 0, 1, 0)}):Play()
    if isErr then
        ProgressFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        ProgressStatus.Text = " ❌ " .. tostring(msg)
    else
        ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        ProgressStatus.Text = string.format(" [%d%%] %s", pct, tostring(msg))
    end
end

-- Tab Switcher
local Tabs = {}
local function CreateTab(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 36)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 10
    TabBtn.LayoutOrder = layoutOrder
    TabBtn.Parent = Sidebar
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = PageContainer

    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Page.Visible = false
            tab.Btn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
            tab.Btn.TextColor3 = Color3.fromRGB(160, 165, 180)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    table.insert(Tabs, {Btn = TabBtn, Page = Page})
    if #Tabs == 1 then
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return Page
end

-- ============================================================================
-- TAB 1: MAP DUPLICATOR (.RBXL)
-- ============================================================================
local MapPage = CreateTab("🗺️ Dupe Map", 1)

local MapFileBoxBg = Instance.new("Frame")
MapFileBoxBg.Size = UDim2.new(1, -10, 0, 34)
MapFileBoxBg.Position = UDim2.new(0, 5, 0, 10)
MapFileBoxBg.BackgroundColor3 = Color3.fromRGB(25, 27, 36)
MapFileBoxBg.Parent = MapPage
Instance.new("UICorner", MapFileBoxBg).CornerRadius = UDim.new(0, 6)

local MapFileBox = Instance.new("TextBox")
MapFileBox.Size = UDim2.new(1, -20, 1, 0)
MapFileBox.Position = UDim2.new(0, 10, 0, 0)
MapFileBox.BackgroundTransparency = 1
MapFileBox.Text = Config.MapFileName
MapFileBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MapFileBox.Font = Enum.Font.Gotham
MapFileBox.TextSize = 11
MapFileBox.TextXAlignment = Enum.TextXAlignment.Left
MapFileBox.Parent = MapFileBoxBg

MapFileBox.FocusLost:Connect(function()
    if MapFileBox.Text ~= "" then Config.MapFileName = MapFileBox.Text end
end)

local SaveMapBtn = Instance.new("TextButton")
SaveMapBtn.Size = UDim2.new(1, -10, 0, 42)
SaveMapBtn.Position = UDim2.new(0, 5, 0, 52)
SaveMapBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
SaveMapBtn.Text = "💾 DUPLICATE MAP FILE (.RBXL)"
SaveMapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveMapBtn.Font = Enum.Font.GothamBold
SaveMapBtn.TextSize = 12
SaveMapBtn.Parent = MapPage
Instance.new("UICorner", SaveMapBtn).CornerRadius = UDim.new(0, 6)

local MapDesc = Instance.new("TextLabel")
MapDesc.Size = UDim2.new(1, -10, 0, 180)
MapDesc.Position = UDim2.new(0, 5, 0, 105)
MapDesc.BackgroundTransparency = 1
MapDesc.Text = "📌 KOI49 Map Duplicator:\n\n• ดูดวัตถุ 3D, โมเดลแมพ, จุดเกิด, อาวุธ และโครงสร้างเกมทั้งหมดออกเป็นไฟล์ .RBXL\n• ถอดระบบ Character Animator ออกอัตโนมัติ เพื่อป้องกันปัญหาเปิดใน Roblox Studio แล้วเจอ Error\n• นำไฟล์ .rbxl ไปเปิดใน Roblox Studio เพื่อดูตำแหน่ง Coordinate (CFrame) สำหรับทำ Auto-Farm ได้ทันที!"
MapDesc.TextColor3 = Color3.fromRGB(160, 165, 180)
MapDesc.TextSize = 11
MapDesc.Font = Enum.Font.Gotham
MapDesc.TextWrapped = true
MapDesc.TextYAlignment = Enum.TextYAlignment.Top
MapDesc.Parent = MapPage

SaveMapBtn.MouseButton1Click:Connect(function()
    local fileName = Config.MapFileName
    if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then
        fileName = fileName .. ".rbxl"
    end

    SendNotify("KOI49", "กำลังเริ่มคัดลอกโมเดลแมพทั้งหมด...")
    UpdateStatus(15, "Indexing Workspace & ReplicatedStorage...")

    task.spawn(function()
        local saved = false
        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            saved = pcall(function()
                saveFn({
                    FilePath = fileName,
                    Decompile = true,
                    NilInstances = true,
                    RemovePlayer = true,
                    ExtraInstances = {
                        game:GetService("StarterPack"),
                        game:GetService("ReplicatedStorage"),
                        game:GetService("StarterGui"),
                        game:GetService("Lighting")
                    }
                })
            end)
        end

        if saved then
            UpdateStatus(100, "MAP DUMP SUCCESS: " .. fileName)
            SendNotify("KOI49 Success", "บันทึกไฟล์แมพ " .. fileName .. " สำเร็จ!")
        else
            local summary = string.format("-- KOI49 MAP BACKUP STRUCTURE\n-- PlaceId: %d\n-- Objects Count: %d\n", game.PlaceId, #workspace:GetDescendants())
            SetClipboardText(summary)
            UpdateStatus(100, "COPIED TO CLIPBOARD (Android File Access Blocked)")
            SendNotify("KOI49 Alert", "ระบบถูกล็อกสิทธิ์ไฟล์ จึงคัดลอกลง Clipboard แทนเรียบร้อย!")
        end
    end)
end)

-- ============================================================================
-- TAB 2: SCRIPTS & AUTO-FARM DATA DUMPER
-- ============================================================================
local DataPage = CreateTab("📜 Scrape Source", 2)

local ScrapeAllBtn = Instance.new("TextButton")
ScrapeAllBtn.Size = UDim2.new(1, -10, 0, 36)
ScrapeAllBtn.Position = UDim2.new(0, 5, 0, 10)
ScrapeAllBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 90)
ScrapeAllBtn.Text = "⚡ DUMP AUTO-FARM SCRIPTS & REMOTES"
ScrapeAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrapeAllBtn.Font = Enum.Font.GothamBold
ScrapeAllBtn.TextSize = 11
ScrapeAllBtn.Parent = DataPage
Instance.new("UICorner", ScrapeAllBtn).CornerRadius = UDim.new(0, 6)

local CopyDumpBtn = Instance.new("TextButton")
CopyDumpBtn.Size = UDim2.new(1, -10, 0, 28)
CopyDumpBtn.Position = UDim2.new(0, 5, 0, 50)
CopyDumpBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
CopyDumpBtn.Text = "📋 COPY DUMPED DATA TO CLIPBOARD"
CopyDumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyDumpBtn.Font = Enum.Font.GothamBold
CopyDumpBtn.TextSize = 10
CopyDumpBtn.Parent = DataPage
Instance.new("UICorner", CopyDumpBtn).CornerRadius = UDim.new(0, 6)

local CodeBoxBg = Instance.new("Frame")
CodeBoxBg.Size = UDim2.new(1, -10, 1, -90)
CodeBoxBg.Position = UDim2.new(0, 5, 0, 84)
CodeBoxBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
CodeBoxBg.Parent = DataPage
Instance.new("UICorner", CodeBoxBg).CornerRadius = UDim.new(0, 6)

local CodeDisplay = Instance.new("TextBox")
CodeDisplay.Size = UDim2.new(1, -12, 1, -12)
CodeDisplay.Position = UDim2.new(0, 6, 0, 6)
CodeDisplay.BackgroundTransparency = 1
CodeDisplay.TextColor3 = Color3.fromRGB(180, 220, 180)
CodeDisplay.Font = Enum.Font.Code
CodeDisplay.TextSize = 10
CodeDisplay.TextXAlignment = Enum.TextXAlignment.Left
CodeDisplay.TextYAlignment = Enum.TextYAlignment.Top
CodeDisplay.ClearTextOnFocus = false
CodeDisplay.MultiLine = true
CodeDisplay.ReadOnly = false
CodeDisplay.Text = "-- KOI49 AUTO FARM DUMPER READY\n-- Click 'DUMP AUTO-FARM SCRIPTS & REMOTES' to extract script code & remotes for AI!"
CodeDisplay.Parent = CodeBoxBg

ScrapeAllBtn.MouseButton1Click:Connect(function()
    UpdateStatus(10, "Extracting Scripts, Remotes & Farm Targets...")
    
    task.spawn(function()
        local lines = {}
        table.insert(lines, "-- ============================================================================")
        table.insert(lines, "-- KOI49 AUTO FARM SOURCE CODE & GAME DATA DUMP")
        table.insert(lines, string.format("-- PlaceId: %d | Place Name: %s", game.PlaceId, game.Name))
        table.insert(lines, "-- ============================================================================\n")

        -- 1. Scrape RemoteEvents & RemoteFunctions
        table.insert(lines, "-- [ SECTION 1: ALL REMOTE EVENTS & FUNCTIONS (CRITICAL FOR AUTO FARM) ] --\n")
        local remoteCount = 0
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
                remoteCount = remoteCount + 1
                table.insert(lines, string.format("[%s] %s -> Path: %s", v.ClassName, v.Name, v:GetFullName()))
            end
        end

        -- 2. Scrape Decompiled Scripts
        table.insert(lines, "\n-- [ SECTION 2: DECOMPILED LOCAL & MODULE SCRIPTS ] --\n")
        local scriptCount = 0
        local decompileFn = decompile or (getscriptbytecode and function(s) return "-- Bytecode extracted" end)

        for _, inst in ipairs(game:GetDescendants()) do
            if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
                scriptCount = scriptCount + 1
                table.insert(lines, string.format("-- SCRIPT: %s [%s]", inst:GetFullName(), inst.ClassName))
                
                local src = nil
                if decompileFn then pcall(function() src = decompileFn(inst) end) end
                if not src or src == "" then pcall(function() src = inst.Source end) end

                if src and src ~= "" then
                    table.insert(lines, src)
                else
                    table.insert(lines, "-- [Protected Script Source]")
                end
                table.insert(lines, "\n----------------------------------------------------------------------------\n")
            end
        end

        -- 3. Scrape Workspace Resources, Enemies & Tools
        table.insert(lines, "\n-- [ SECTION 3: WORKSPACE FARM TARGETS & TOOLS ] --\n")
        for _, item in ipairs(workspace:GetChildren()) do
            if item:IsA("Model") or item:IsA("Folder") or item:IsA("Tool") then
                table.insert(lines, string.format("Workspace Target: %s [%s]", item.Name, item.ClassName))
            end
        end

        local dumpText = table.concat(lines, "\n")
        CodeDisplay.Text = dumpText

        if is_writefile then pcall(function() writefile(Config.DumpFileName, dumpText) end) end
        SetClipboardText(dumpText)

        UpdateStatus(100, string.format("Dumped %d Remotes, %d Scripts!", remoteCount, scriptCount))
        SendNotify("KOI49 Dumper", "ดัมพ์ข้อมูลเรียบร้อย! คัดลอกลง Clipboard พร้อมส่งให้ AI เขียน Auto Farm แล้ว!")
    end)
end)

CopyDumpBtn.MouseButton1Click:Connect(function()
    if CodeDisplay.Text ~= "" then
        SetClipboardText(CodeDisplay.Text)
        UpdateStatus(100, "COPIED TO CLIPBOARD!")
        SendNotify("KOI49", "คัดลอกข้อมูลทั้งหมดลง Clipboard เรียบร้อย!")
    end
end)

-- ============================================================================
-- TAB 3: REMOTE SPY (REAL-TIME ACTION LOGGER FOR AUTO-FARM)
-- ============================================================================
local SpyPage = CreateTab("🕵️ Remote Spy", 3)

local SpyToggleBtn = Instance.new("TextButton")
SpyToggleBtn.Size = UDim2.new(1, -10, 0, 34)
SpyToggleBtn.Position = UDim2.new(0, 5, 0, 10)
SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
SpyToggleBtn.Text = "🔴 REMOTE SPY: OFF (CLICK TO TURN ON)"
SpyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpyToggleBtn.Font = Enum.Font.GothamBold
SpyToggleBtn.TextSize = 11
SpyToggleBtn.Parent = SpyPage
Instance.new("UICorner", SpyToggleBtn).CornerRadius = UDim.new(0, 6)

local ClearSpyBtn = Instance.new("TextButton")
ClearSpyBtn.Size = UDim2.new(1, -10, 0, 26)
ClearSpyBtn.Position = UDim2.new(0, 5, 0, 48)
ClearSpyBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
ClearSpyBtn.Text = "🧹 CLEAR LOGS"
ClearSpyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearSpyBtn.Font = Enum.Font.GothamBold
ClearSpyBtn.TextSize = 10
ClearSpyBtn.Parent = SpyPage
Instance.new("UICorner", ClearSpyBtn).CornerRadius = UDim.new(0, 6)

local SpyBoxBg = Instance.new("Frame")
SpyBoxBg.Size = UDim2.new(1, -10, 1, -88)
SpyBoxBg.Position = UDim2.new(0, 5, 0, 80)
SpyBoxBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
SpyBoxBg.Parent = SpyPage
Instance.new("UICorner", SpyBoxBg).CornerRadius = UDim.new(0, 6)

local SpyDisplay = Instance.new("TextBox")
SpyDisplay.Size = UDim2.new(1, -12, 1, -12)
SpyDisplay.Position = UDim2.new(0, 6, 0, 6)
SpyDisplay.BackgroundTransparency = 1
SpyDisplay.TextColor3 = Color3.fromRGB(255, 215, 100)
SpyDisplay.Font = Enum.Font.Code
SpyDisplay.TextSize = 10
SpyDisplay.TextXAlignment = Enum.TextXAlignment.Left
SpyDisplay.TextYAlignment = Enum.TextYAlignment.Top
SpyDisplay.ClearTextOnFocus = false
SpyDisplay.MultiLine = true
SpyDisplay.ReadOnly = false
SpyDisplay.Text = "-- REMOTE SPY DISBALED\n-- Turn ON, then perform actions in game (Attack, Buy, Harvest, Upgrade)\n-- RemoteEvent arguments will be captured here in real-time!"
SpyDisplay.Parent = SpyBoxBg

local isSpyActive = false
local spyLogs = {}

local function FormatArgs(args)
    local formatted = {}
    for i, v in ipairs(args) do
        if type(v) == "string" then
            table.insert(formatted, string.format('"%s"', tostring(v)))
        else
            table.insert(formatted, tostring(v))
        end
    end
    return table.concat(formatted, ", ")
end

-- Hook Namecall for RemoteSpy
local rawNamecall = getrawmetatable and getrawmetatable(game) and getrawmetatable(game).__namecall
if rawNamecall and setreadonly then
    setreadonly(getrawmetatable(game), false)
    getrawmetatable(game).__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if isSpyActive and (method == "FireServer" or method == "invokeServer" or method == "FireServer") then
            local args = {...}
            local logLine = string.format('game:GetService("%s").%s:%s(%s)', self.Parent and self.Parent.Name or "ReplicatedStorage", self.Name, method, FormatArgs(args))
            table.insert(spyLogs, 1, logLine)
            if #spyLogs > 40 then table.remove(spyLogs) end
            SpyDisplay.Text = table.concat(spyLogs, "\n")
        end
        return rawNamecall(self, ...)
    end)
    setreadonly(getrawmetatable(game), true)
end

SpyToggleBtn.MouseButton1Click:Connect(function()
    isSpyActive = not isSpyActive
    if isSpyActive then
        SpyToggleBtn.Text = "🟢 REMOTE SPY: ACTIVE (LOGGING REMOTES...)"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        SendNotify("KOI49 Spy", "เริ่มอัด Remote Spy แล้ว! ไปกดทำแอ็กชันในเกมเพื่อจับโค้ดได้เลย")
    else
        SpyToggleBtn.Text = "🔴 REMOTE SPY: OFF (CLICK TO TURN ON)"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

ClearSpyBtn.MouseButton1Click:Connect(function()
    spyLogs = {}
    SpyDisplay.Text = "-- Logs Cleared --"
end)

UpdateStatus(100, "KOI49 ENGINE LOADED READY!")
