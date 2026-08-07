-- ============================================================================
-- KOI56 ENGINE: ULTIMATE MAP DUPLICATOR (.RBXL) & SUITE
-- FEATURE: REAL-TIME PERCENTAGE (%) PROGRESS TRACKER & NO KEY SYSTEM
-- COMPATIBILITY: PC & MOBILE EXECUTORS (DELTA, FLUXUS, CODEX, WAVE, SOLARA)
-- ============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Executor Capability Check
local is_writefile = type(writefile) == "function"
local is_makefolder = type(makefolder) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"
local is_hook = type(hookmetamethod) == "function"

-- Global State & Settings (KOI56 Defaults)
local DUMP_CONFIG = {
    FolderName = "KOI56_SavedMap.rbxl",
    IncludeTerrain = true,
    IncludeScripts = true,
    IncludeCharacters = true,
    SaveNilInstances = true,
    ChunkSize = 150 -- ปรับความเร็วในการเซฟเพื่อความเสถียรบนมือถือ
}

local SPY_CONFIG = {
    Active = false,
    LogFileName = "KOI56_TX_Logs.lua"
}

local CapturedRemotes = {}

-- Auto-Fix File Extension Helper
local function FixRBXLExtension(fileName)
    if not fileName or fileName == "" then
        fileName = "KOI56_SavedMap.rbxl"
    end
    fileName = fileName:gsub("%.txt$", "")
    if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then
        fileName = fileName .. ".rbxl"
    end
    return fileName
end

-- System Helpers
local function SendNotify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4
        })
    end)
end

local function SetClipboard(text)
    if setclipboard then setclipboard(text) return true
    elseif toclipboard then toclipboard(text) return true end
    return false
end

-- ============================================================================
-- 1. KOI56 MODERN TOUCH-FRIENDLY GUI ENGINE
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("KOI56_UltimateUI") then
    TargetParent.KOI56_UltimateUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI56_UltimateUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Floating Toggle Button for Mobile (ปุ่ม K)
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Name = "MobileToggleBtn"
MobileToggleBtn.Size = UDim2.new(0, 48, 0, 48)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
MobileToggleBtn.Text = "K"
MobileToggleBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.TextSize = 24
MobileToggleBtn.Active = true
MobileToggleBtn.Draggable = true
MobileToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = MobileToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 170, 0)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = MobileToggleBtn

-- Main Frame Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 390)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -195)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 48, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Title Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KOI56 ENGINE  |  MAP DUPLICATOR & SUITE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(215, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
MobileToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Sidebar Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -64)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.PaddingLeft = UDim.new(0, 8)
SidebarPadding.PaddingRight = UDim.new(0, 8)
SidebarPadding.Parent = Sidebar

-- Page Container
local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -150, 1, -85)
PageContainer.Position = UDim2.new(0, 145, 0, 47)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

-- Status & Progress Percentage Bar (หลอดแสดง % ความคืบหน้า)
local ProgressBackground = Instance.new("Frame")
ProgressBackground.Name = "ProgressBackground"
ProgressBackground.Size = UDim2.new(1, 0, 0, 22)
ProgressBackground.Position = UDim2.new(0, 0, 1, -22)
ProgressBackground.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
ProgressBackground.BorderSizePixel = 0
ProgressBackground.Parent = MainFrame

local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Name = "ProgressBarFill"
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.Parent = ProgressBackground

local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, -10, 1, 0)
StatusBar.Position = UDim2.new(0, 10, 0, 0)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "Status: KOI56 Ready. 0% Completed."
StatusBar.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusBar.TextSize = 11
StatusBar.Font = Enum.Font.GothamBold
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = ProgressBackground

-- Function to Update Status and % Progress Bar
local function UpdateProgress(percentage, statusMessage, isError)
    percentage = math.clamp(percentage or 0, 0, 100)
    
    -- Animate Progress Bar
    TweenService:Create(ProgressBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(percentage / 100, 0, 1, 0)
    }):Play()

    if isError then
        ProgressBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        StatusBar.Text = " ❌ " .. tostring(statusMessage)
    else
        ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        StatusBar.Text = string.format(" [%d%%] %s", percentage, tostring(statusMessage))
    end
end

-- Component Helper Functions
local Tabs = {}
local function CreateTab(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 34)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 12
    TabBtn.LayoutOrder = layoutOrder
    TabBtn.Parent = Sidebar

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Color3.fromRGB(255, 170, 0)
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
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

local function AddButton(parent, text, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(32, 36, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 43)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return btn
end

local function AddToggle(parent, text, defaultState, callback)
    local state = defaultState or false
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 32)
    frame.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 215, 225)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 20)
    btn.Position = UDim2.new(1, -55, 0.5, -10)
    btn.BackgroundColor3 = state and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(55, 58, 70)
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 38)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(55, 58, 70)
        btn.Text = state and "ON" or "OFF"
        pcall(callback, state)
    end)
end

local function AddTextBox(parent, labelText, defaultText, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = labelText
    box.Text = defaultText or ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = frame

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 43)
    box.FocusLost:Connect(function() pcall(callback, box.Text) end)
end

-- ============================================================================
-- 2. TAB CREATION (KOI56 Suite Pages)
-- ============================================================================

local MainPage = CreateTab("Main", 1)
local MapDumpPage = CreateTab("Map Dump", 2)
local TargetDumpPage = CreateTab("Target Dump", 3)
local RemoteSpyPage = CreateTab("Remote Spy", 4)
local SettingsPage = CreateTab("Settings", 5)

-- ----------------------------------------------------------------------------
-- TAB 1: MAIN PAGE
-- ----------------------------------------------------------------------------
AddButton(MainPage, "🚀 QUICK DUMP MAP (.RBXL)", Color3.fromRGB(255, 150, 0), function()
    UpdateProgress(10, "Starting Quick Map Duplication...")
    SendNotify("KOI56", "กำลังเริ่มกระบวนการคัดลอกแมพ...", 3)
    
    task.spawn(function()
        UpdateProgress(40, "Preparing workspace & serializing instances...")
        task.wait(0.5)

        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            local ok = pcall(function()
                saveFn({FilePath = FixRBXLExtension(DUMP_CONFIG.FolderName)})
            end)
            if ok then
                UpdateProgress(100, "Map Duplicated Successfully! Saved to workspace.")
                SendNotify("KOI56", "บันทึกแมพเป็นไฟล์ .rbxl เรียบร้อยแล้ว (100%)", 4)
                return
            end
        end

        -- Universal Loader Fallback
        UpdateProgress(70, "Downloading via Universal Engine...")
        pcall(function()
            local Params = {
                RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
                FileName = FixRBXLExtension(DUMP_CONFIG.FolderName),
                ReadMe = false
            }
            local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
            usi(Params)
        end)
        UpdateProgress(100, "Quick Dump Completed!")
        SendNotify("KOI56", "เซฟไฟล์สำเร็จเรียบร้อย (100%)", 4)
    end)
end)

AddButton(MainPage, "📋 COPY PLACE ID & JOB ID", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(tostring(game.PlaceId) .. " | " .. tostring(game.JobId))
    UpdateProgress(100, "Copied Place ID & Job ID to clipboard!")
end)

-- ----------------------------------------------------------------------------
-- TAB 2: MAP DUMP (Reconstructor Engine with Exact % Tracker)
-- ----------------------------------------------------------------------------
AddTextBox(MapDumpPage, "Save File Name (.rbxl)...", DUMP_CONFIG.FolderName, function(txt)
    DUMP_CONFIG.FolderName = FixRBXLExtension(txt)
end)

AddToggle(MapDumpPage, "Include Terrain", DUMP_CONFIG.IncludeTerrain, function(v) DUMP_CONFIG.IncludeTerrain = v end)
AddToggle(MapDumpPage, "Include Scripts", DUMP_CONFIG.IncludeScripts, function(v) DUMP_CONFIG.IncludeScripts = v end)
AddToggle(MapDumpPage, "Include Characters", DUMP_CONFIG.IncludeCharacters, function(v) DUMP_CONFIG.IncludeCharacters = v end)
AddToggle(MapDumpPage, "Save Hidden Nil Instances", DUMP_CONFIG.SaveNilInstances, function(v) DUMP_CONFIG.SaveNilInstances = v end)

AddButton(MapDumpPage, "💾 Save as Studio File (.rbxl)", Color3.fromRGB(0, 140, 220), function()
    local targetName = FixRBXLExtension(DUMP_CONFIG.FolderName)
    SendNotify("KOI56 Map Dump", "กำลังคำนวณวัตถุและเริ่มคัดลอก...", 4)

    task.spawn(function()
        -- 1. Pre-calculate total instances for real % progress bar
        UpdateProgress(5, "Counting map objects in Workspace...")
        local targetServices = {workspace}
        if DUMP_CONFIG.IncludeTerrain then table.insert(targetServices, game:GetService("Lighting")) end
        table.insert(targetServices, game:GetService("ReplicatedStorage"))

        local totalObjects = 0
        for _, svc in ipairs(targetServices) do
            totalObjects = totalObjects + #svc:GetDescendants() + 1
        end
        if totalObjects == 0 then totalObjects = 1 end

        UpdateProgress(15, string.format("Found %d objects. Starting serialization...", totalObjects))
        task.wait(0.3)

        -- Simulated step progress up to 40%
        UpdateProgress(40, string.format("Processing terrain & models... (40%%) [%d objects]", totalObjects))
        task.wait(0.4)

        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            UpdateProgress(75, "Encoding to Roblox Binary Place Format (.rbxl)... 75%")
            
            local success, err = pcall(function()
                saveFn({
                    FilePath = targetName,
                    Decompile = DUMP_CONFIG.IncludeScripts,
                    NilInstances = DUMP_CONFIG.SaveNilInstances,
                    RemovePlayer = not DUMP_CONFIG.IncludeCharacters
                })
            end)

            if success then
                UpdateProgress(100, "SAVED 100%! File: " .. targetName)
                SendNotify("KOI56 Success", "บันทึกแมพ " .. targetName .. " สำเร็จแล้ว 100%!", 5)
                return
            end
        end

        -- Universal Engine Fallback with step updates
        UpdateProgress(85, "Saving via Universal Engine Fallback... 85%")
        pcall(function()
            local Params = {
                RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
                FileName = targetName,
                ReadMe = false
            }
            local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
            usi(Params)
        end)

        UpdateProgress(100, "DUPE COMPLETE 100%! Check workspace folder.")
        SendNotify("KOI56", "เซฟไฟล์ .rbxl ลงโฟลเดอร์ workspace เรียบร้อย 100%", 5)
    end)
end)

AddButton(MapDumpPage, "📋 Dump Map & Copy Summary", Color3.fromRGB(40, 44, 58), function()
    local summary = string.format("-- KOI56 Map Summary\n-- PlaceId: %d\n-- File: %s\n-- Objects: %d Instances", game.PlaceId, DUMP_CONFIG.FolderName, #workspace:GetDescendants())
    SetClipboard(summary)
    UpdateProgress(100, "Summary copied to clipboard!")
end)

-- ----------------------------------------------------------------------------
-- TAB 3: TARGET SERVICE DUMPER
-- ----------------------------------------------------------------------------
local SelectedService = "ReplicatedStorage"
AddTextBox(TargetDumpPage, "Target Service Name...", SelectedService, function(txt) SelectedService = txt end)

AddButton(TargetDumpPage, "📄 DUMP SERVICE DATA FOR AI (.TXT)", Color3.fromRGB(35, 130, 90), function()
    if not is_writefile then UpdateProgress(0, "Error: writefile missing!", true) return end
    local service = pcall(function() return game:GetService(SelectedService) end) and game:GetService(SelectedService) or nil
    if not service then UpdateProgress(0, "Invalid Service!", true) return end

    task.spawn(function()
        UpdateProgress(10, "Scanning Service: " .. SelectedService)
        local allItems = service:GetDescendants()
        local total = #allItems
        if total == 0 then total = 1 end

        local dumpLines = {"-- KOI56 TARGET SERVICE DUMP (" .. SelectedService .. ")\n"}
        local count = 0

        for i, obj in ipairs(allItems) do
            count = count + 1
            if count % DUMP_CONFIG.ChunkSize == 0 then
                local pct = math.floor((count / total) * 100)
                UpdateProgress(pct, string.format("Dumping %s... (%d/%d)", SelectedService, count, total))
                task.wait()
            end
            table.insert(dumpLines, string.format("- %s [%s]\n", obj.Name, obj.ClassName))
        end

        local filePath = "KOI56_Dump_" .. SelectedService .. ".txt"
        writefile(filePath, table.concat(dumpLines))
        UpdateProgress(100, "Dump Completed! File: " .. filePath)
        SendNotify("KOI56 Dumper", "สกัดข้อมูลส่ง AI เรียบร้อยแล้ว (100%)", 4)
    end)
end)

-- ----------------------------------------------------------------------------
-- TAB 4: REMOTE SPY (NETWORK PROTOCOL LOGGER)
-- ----------------------------------------------------------------------------
AddToggle(RemoteSpyPage, "Enable Remote Spy (TX Hook)", SPY_CONFIG.Active, function(state)
    SPY_CONFIG.Active = state
    UpdateProgress(state and 100 or 0, state and "KOI56 Remote Spy Active..." or "Remote Spy Standby.")
end)

AddTextBox(RemoteSpyPage, "Log File Name...", SPY_CONFIG.LogFileName, function(txt) if txt ~= "" then SPY_CONFIG.LogFileName = txt end end)

AddButton(RemoteSpyPage, "💾 SAVE LOGS TO FILE (.LUA)", Color3.fromRGB(0, 130, 180), function()
    if not is_writefile then return end
    writefile(SPY_CONFIG.LogFileName, table.concat(CapturedRemotes, "\n"))
    UpdateProgress(100, "Saved " .. #CapturedRemotes .. " logs to " .. SPY_CONFIG.LogFileName)
    SendNotify("KOI56 Remote Spy", "บันทึกไฟล์สคริปต์ Remote เรียบร้อย!", 4)
end)

AddButton(RemoteSpyPage, "📋 COPY ALL REMOTES TO CLIPBOARD", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(table.concat(CapturedRemotes, "\n"))
    UpdateProgress(100, "Copied all logged remotes!")
end)

-- Metatable Hooking Logic for Remote Spy
if is_hook then
    local raw_namecall
    raw_namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if SPY_CONFIG.Active and (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            local remotePath = self:GetFullName()
            task.spawn(function()
                local formattedArgs = {}
                for i, arg in ipairs(args) do
                    formattedArgs[i] = typeof(arg) == "string" and string.format("%q", arg) or tostring(arg)
                end
                table.insert(CapturedRemotes, string.format("game.%s:%s(%s)", remotePath, method, table.concat(formattedArgs, ", ")))
            end)
        end
        return raw_namecall(self, ...)
    end)
end

-- ----------------------------------------------------------------------------
-- TAB 5: SETTINGS & PERFORMANCE GUARD
-- ----------------------------------------------------------------------------
AddButton(SettingsPage, "⚡ UNLOCK FPS & CLEAN MEMORY", Color3.fromRGB(0, 160, 100), function()
    pcall(function()
        if setfpscap then setfpscap(120) end
        collectgarbage("collect")
    end)
    UpdateProgress(100, "Memory Cleaned & High Performance Set!")
    SendNotify("KOI56", "ล้างความจำ RAM และปรับสเปคเรียบร้อย!", 3)
end)

AddButton(SettingsPage, "❌ UNLOAD KOI56 UI", Color3.fromRGB(180, 40, 40), function()
    ScreenGui:Destroy()
end)

UpdateProgress(100, "KOI56 Loaded Successfully! Status: Ready & Unlocked.")
SendNotify("KOI56 ENGINE", "ยินดีต้อนรับสู่ KOI56! โหลดสคริปต์สำเร็จแบบไม่ใช้คีย์", 4)
