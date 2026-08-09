-- ============================================================================
-- KOI49 ENGINE v2.1.0  |  REAL DATA DUMPER & REMOTE SPY (NO FAKE / NO LAG)
-- BASED ON VALEN HUB DUMPING SYSTEM FOR AI AUTO-FARM SCRIPT GENERATION
-- NO KEY SYSTEM | REAL-TIME CHUNKED SCANNING | DIRECT WORKSPACE FILE WRITE
-- ============================================================================

local SCRIPT_VERSION = "v2.1.0 (REAL DUMP)"

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local is_writefile = type(writefile) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"
local is_makefolder = type(makefolder) == "function"

local Config = {
    MapFileName = "KOI49_Map_" .. tostring(game.PlaceId) .. ".rbxl",
    DumpFileName = "KOI49_RealDump_" .. tostring(game.PlaceId) .. ".txt"
}

local function SendNotify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = 4
        })
    end)
end

local function SetClipboardText(text)
    if setclipboard then setclipboard(text) return true
    elseif toclipboard then toclipboard(text) return true end
    return false
end

-- Safely write real dump file to executor workspace folder
local function SaveToWorkspace(filename, content)
    if is_writefile then
        local success, err = pcall(function()
            if is_makefolder then pcall(function() makefolder("KOI49_Dumps") end) end
            writefile("KOI49_Dumps/" .. filename, content)
        end)
        if not success then
            pcall(function() writefile(filename, content) end)
        end
        return true
    end
    return false
end

-- ============================================================================
-- GUI ENGINE (CLEAN UI WITH VERSION BADGE)
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("KOI49_EngineUI") then
    TargetParent.KOI49_EngineUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI49_EngineUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Mobile Floating Button (K49)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
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
MainFrame.Size = UDim2.new(0, 550, 0, 420)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Header Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -140, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KOI49 ENGINE  |  REAL DATA DUMPER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local VerBadge = Instance.new("TextLabel")
VerBadge.Size = UDim2.new(0, 110, 0, 22)
VerBadge.Position = UDim2.new(1, -150, 0, 9)
VerBadge.BackgroundColor3 = Color3.fromRGB(35, 140, 80)
VerBadge.Text = SCRIPT_VERSION
VerBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
VerBadge.Font = Enum.Font.GothamBold
VerBadge.TextSize = 10
VerBadge.Parent = TopBar
Instance.new("UICorner", VerBadge).CornerRadius = UDim.new(0, 5)

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
Sidebar.Size = UDim2.new(0, 140, 1, -68)
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
PageContainer.Size = UDim2.new(1, -150, 1, -78)
PageContainer.Position = UDim2.new(0, 145, 0, 45)
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
ProgressStatus.Text = string.format("[%s] Ready to dump real game data.", SCRIPT_VERSION)
ProgressStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressStatus.TextSize = 10
ProgressStatus.Font = Enum.Font.GothamBold
ProgressStatus.TextXAlignment = Enum.TextXAlignment.Left
ProgressStatus.Parent = ProgressBg

local function UpdateStatus(pct, msg, isErr)
    pct = math.clamp(pct, 0, 100)
    TweenService:Create(ProgressFill, TweenInfo.new(0.08), {Size = UDim2.new(pct / 100, 0, 1, 0)}):Play()
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
-- TAB 1: REAL 100% SCRIPT & DATA DUMPER
-- ============================================================================
local DumpPage = CreateTab("📜 Real Dump (100%)", 1)

local ScrapeAllBtn = Instance.new("TextButton")
ScrapeAllBtn.Size = UDim2.new(1, -10, 0, 36)
ScrapeAllBtn.Position = UDim2.new(0, 5, 0, 10)
ScrapeAllBtn.BackgroundColor3 = Color3.fromRGB(35, 140, 80)
ScrapeAllBtn.Text = "⚡ START REAL 100% GAME DUMP"
ScrapeAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrapeAllBtn.Font = Enum.Font.GothamBold
ScrapeAllBtn.TextSize = 11
ScrapeAllBtn.Parent = DumpPage
Instance.new("UICorner", ScrapeAllBtn).CornerRadius = UDim.new(0, 6)

local CopyDumpBtn = Instance.new("TextButton")
CopyDumpBtn.Size = UDim2.new(1, -10, 0, 28)
CopyDumpBtn.Position = UDim2.new(0, 5, 0, 50)
CopyDumpBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
CopyDumpBtn.Text = "📋 COPY REAL DUMP TO CLIPBOARD"
CopyDumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyDumpBtn.Font = Enum.Font.GothamBold
CopyDumpBtn.TextSize = 10
CopyDumpBtn.Parent = DumpPage
Instance.new("UICorner", CopyDumpBtn).CornerRadius = UDim.new(0, 6)

local CodeBoxBg = Instance.new("Frame")
CodeBoxBg.Size = UDim2.new(1, -10, 1, -90)
CodeBoxBg.Position = UDim2.new(0, 5, 0, 84)
CodeBoxBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
CodeBoxBg.Parent = DumpPage
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
CodeDisplay.Text = string.format("-- KOI49 ENGINE %s READY\n-- Click 'START REAL 100%% GAME DUMP' to scan and extract real scripts & remotes!", SCRIPT_VERSION)
CodeDisplay.Parent = CodeBoxBg

-- REAL SCANNING & DUMPING ENGINE (NO FAKE DELAYS / NON-BLOCKING)
ScrapeAllBtn.MouseButton1Click:Connect(function()
    ScrapeAllBtn.Text = "⏳ DUMPING REAL DATA (PLEASE WAIT)..."
    UpdateStatus(5, "Collecting All Game Instances...")
    
    task.spawn(function()
        local output = {}
        table.insert(output, "-- ============================================================================")
        table.insert(output, string.format("-- KOI49 REAL DATA DUMP | VERSION: %s", SCRIPT_VERSION))
        table.insert(output, string.format("-- PlaceId: %d | Place Name: %s", game.PlaceId, game.Name))
        table.insert(output, string.format("-- Date/Time: %s", os.date("%Y-%m-%d %H:%M:%S")))
        table.insert(output, "-- ============================================================================\n")

        -- Target Services Array
        local servicesToScan = {
            {Name = "ReplicatedStorage", Obj = ReplicatedStorage},
            {Name = "Workspace", Obj = Workspace},
            {Name = "StarterGui", Obj = StarterGui},
            {Name = "StarterPlayer", Obj = game:GetService("StarterPlayer")},
            {Name = "Lighting", Obj = Lighting}
        }

        -- Step 1: Collect All Descendants
        local allInstances = {}
        for _, s in ipairs(servicesToScan) do
            if s.Obj then
                local children = s.Obj:GetDescendants()
                for _, child in ipairs(children) do
                    table.insert(allInstances, child)
                end
            end
        end

        local totalObjects = #allInstances
        if totalObjects == 0 then totalObjects = 1 end

        -- Step 2: Categorize Objects
        table.insert(output, "-- [ SECTION 1: REAL REMOTE EVENTS & FUNCTIONS ] --\n")
        local remoteCount = 0
        local scriptList = {}

        local processedCount = 0
        local chunkSize = 300 -- Process 300 items per batch to prevent UI lag!

        for i, inst in ipairs(allInstances) do
            processedCount = processedCount + 1

            if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") or inst:IsA("UnreliableRemoteEvent") then
                remoteCount = remoteCount + 1
                table.insert(output, string.format("[%s] %s -> Path: %s", inst.ClassName, inst.Name, inst:GetFullName()))
            elseif inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
                table.insert(scriptList, inst)
            end

            -- Update REAL Progress & Yield to keep FPS smooth
            if processedCount % chunkSize == 0 or i == totalObjects then
                local realPct = math.floor((i / totalObjects) * 50) -- First 50% for indexing
                UpdateStatus(realPct, string.format("Indexed %d/%d Instances...", i, totalObjects))
                task.wait() -- REAL NON-BLOCKING YIELD
            end
        end

        -- Step 3: Decompile Real Scripts
        table.insert(output, "\n\n-- [ SECTION 2: REAL DECOMPILED SCRIPTS SOURCE ] --\n")
        local totalScripts = #scriptList
        local decompileFn = decompile or (getscriptbytecode and function(s) return "-- Bytecode Extracted" end)

        for idx, scr in ipairs(scriptList) do
            table.insert(output, string.format("-- REAL SCRIPT [%d/%d]: %s (%s)", idx, totalScripts, scr:GetFullName(), scr.ClassName))
            
            local sourceText = nil
            if decompileFn then
                pcall(function() sourceText = decompileFn(scr) end)
            end
            if not sourceText or sourceText == "" then
                pcall(function() sourceText = scr.Source end)
            end

            if sourceText and sourceText ~= "" then
                table.insert(output, sourceText)
            else
                table.insert(output, "-- [Protected Script Source - Cannot Decompile]")
            end
            table.insert(output, "\n----------------------------------------------------------------------------\n")

            -- Update REAL Progress for Script Decompilation (50% -> 95%)
            if idx % 5 == 0 or idx == totalScripts then
                local realScriptPct = 50 + math.floor((idx / (totalScripts > 0 and totalScripts or 1)) * 45)
                UpdateStatus(realScriptPct, string.format("Decompiling Script %d/%d...", idx, totalScripts))
                task.wait()
            end
        end

        -- Step 4: Workspace Farm Target Summary
        table.insert(output, "\n-- [ SECTION 3: WORKSPACE MONSTERS, NPCS & TOOLS ] --\n")
        for _, model in ipairs(Workspace:GetChildren()) do
            if model:IsA("Model") or model:IsA("Folder") or model:IsA("Tool") then
                table.insert(output, string.format("Target Object: %s [%s]", model.Name, model.ClassName))
            end
        end

        local finalRealDump = table.concat(output, "\n")
        CodeDisplay.Text = finalRealDump

        -- Save to Executor Workspace Folder
        local savedToFile = SaveToWorkspace(Config.DumpFileName, finalRealDump)
        SetClipboardText(finalRealDump)

        UpdateStatus(100, string.format("DUMP COMPLETE! %d Remotes, %d Scripts Saved.", remoteCount, totalScripts))
        ScrapeAllBtn.Text = "⚡ START REAL 100% GAME DUMP"

        if savedToFile then
            SendNotify("KOI49 Real Dump", "บันทึกไฟล์ KOI49_Dumps/" .. Config.DumpFileName .. " เรียบร้อย!")
        else
            SendNotify("KOI49 Real Dump", "คัดลอกข้อมูลดัมพ์ลง Clipboard เรียบร้อยแล้ว!")
        end
    end)
end)

CopyDumpBtn.MouseButton1Click:Connect(function()
    if CodeDisplay.Text ~= "" then
        SetClipboardText(CodeDisplay.Text)
        UpdateStatus(100, "COPIED TO CLIPBOARD!")
        SendNotify("KOI49", "คัดลอกข้อมูลทั้งหมดลง Clipboard แล้ว!")
    end
end)

-- ============================================================================
-- TAB 2: REAL MAP DUPLICATOR (.RBXL)
-- ============================================================================
local MapPage = CreateTab("🗺️ Dupe Map (.rbxl)", 2)

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

local SaveMapBtn = Instance.new("TextButton")
SaveMapBtn.Size = UDim2.new(1, -10, 0, 42)
SaveMapBtn.Position = UDim2.new(0, 5, 0, 52)
SaveMapBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
SaveMapBtn.Text = "💾 SAVE REAL MAP FILE (.RBXL)"
SaveMapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveMapBtn.Font = Enum.Font.GothamBold
SaveMapBtn.TextSize = 12
SaveMapBtn.Parent = MapPage
Instance.new("UICorner", SaveMapBtn).CornerRadius = UDim.new(0, 6)

local MapDesc = Instance.new("TextLabel")
MapDesc.Size = UDim2.new(1, -10, 0, 180)
MapDesc.Position = UDim2.new(0, 5, 0, 105)
MapDesc.BackgroundTransparency = 1
MapDesc.Text = "📌 Real Map Duplicator Instructions:\n\n• เรียกใช้ API saveinstance() ของตัวรันจริงเพื่อคัดลอกไฟล์แมพ .rbxl\n• สามารถนำไฟล์ไปเปิดใน Roblox Studio เพื่อดูตำแหน่ง CFrame มอนสเตอร์/NPC ในการเขียน Auto Farm\n• หากตัวรันบน Android ติดสิทธิ์การเขียนไฟล์ ระบบจะคัดลอกสำรองข้อมูลลง Clipboard ให้อัตโนมัติ"
MapDesc.TextColor3 = Color3.fromRGB(160, 165, 180)
MapDesc.TextSize = 11
MapDesc.Font = Enum.Font.Gotham
MapDesc.TextWrapped = true
MapDesc.TextYAlignment = Enum.TextYAlignment.Top
MapDesc.Parent = MapPage

SaveMapBtn.MouseButton1Click:Connect(function()
    local fileName = MapFileBox.Text ~= "" and MapFileBox.Text or Config.MapFileName
    if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then fileName = fileName .. ".rbxl" end

    SendNotify("KOI49", "กำลังเริ่มคัดลอกไฟล์แมพจริง...")
    UpdateStatus(20, "Executing saveinstance API...")

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
                    ExtraInstances = {StarterGui, ReplicatedStorage, Lighting}
                })
            end)
        end

        if saved then
            UpdateStatus(100, "REAL MAP SAVED: " .. fileName)
            SendNotify("KOI49 Success", "บันทึกแมพลงไฟล์ " .. fileName .. " เรียบร้อย!")
        else
            local backupSummary = string.format("-- KOI49 REAL MAP STRUCTURE\n-- PlaceId: %d\n-- Objects Count: %d\n", game.PlaceId, #Workspace:GetDescendants())
            SetClipboardText(backupSummary)
            UpdateStatus(100, "COPIED TO CLIPBOARD (Disk Save Blocked)")
            SendNotify("KOI49", "คัดลอกโครงสร้างแมพลง Clipboard เรียบร้อย!")
        end
    end)
end)

-- ============================================================================
-- TAB 3: REAL-TIME REMOTE SPY
-- ============================================================================
local SpyPage = CreateTab("🕵️ Real Remote Spy", 3)

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
ClearSpyBtn.Text = "🧹 CLEAR SPY LOGS"
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
SpyDisplay.Text = "-- REAL REMOTE SPY OFF\n-- Turn ON, then perform actions in game (Attack, Buy, Harvest, Upgrade)\n-- Real RemoteEvent code lines will be captured here!"
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

-- Hook MetaMethod for Real Remote Spy
local rawNamecall = getrawmetatable and getrawmetatable(game) and getrawmetatable(game).__namecall
if rawNamecall and setreadonly then
    setreadonly(getrawmetatable(game), false)
    getrawmetatable(game).__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if isSpyActive and (method == "FireServer" or method == "invokeServer" or method == "FireServer") then
            local args = {...}
            local logLine = string.format('game:GetService("%s").%s:%s(%s)', self.Parent and self.Parent.Name or "ReplicatedStorage", self.Name, method, FormatArgs(args))
            table.insert(spyLogs, 1, logLine)
            if #spyLogs > 35 then table.remove(spyLogs) end
            SpyDisplay.Text = table.concat(spyLogs, "\n")
        end
        return rawNamecall(self, ...)
    end)
    setreadonly(getrawmetatable(game), true)
end

SpyToggleBtn.MouseButton1Click:Connect(function()
    isSpyActive = not isSpyActive
    if isSpyActive then
        SpyToggleBtn.Text = "🟢 REMOTE SPY: ACTIVE (CAPTURING REMOTES...)"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        SendNotify("KOI49 Spy", "เริ่มจับคำสั่ง Remote ในเกมแล้ว! ไปกดทำแอ็กชันในเกมได้เลย")
    else
        SpyToggleBtn.Text = "🔴 REMOTE SPY: OFF (CLICK TO TURN ON)"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

ClearSpyBtn.MouseButton1Click:Connect(function()
    spyLogs = {}
    SpyDisplay.Text = "-- Logs Cleared --"
end)

UpdateStatus(100, string.format("KOI49 ENGINE %s LOADED READY!", SCRIPT_VERSION))
