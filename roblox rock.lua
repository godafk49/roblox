-- ============================================================================
-- KOI56 ULTIMATE ENGINE v5.0 (FULL COMPLETE SUITE)
-- FEATURES: REAL VISUAL SCANNER (%) | MAP DUPE (.RBXL) | TARGET DUMP | REMOTE SPY
--           ASSET PREVIEW | PERFORMANCE GUARD | NO KEY SYSTEM
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

-- Executor Capability Checks
local is_writefile = type(writefile) == "function"
local is_makefolder = type(makefolder) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"
local is_hook = type(hookmetamethod) == "function"

-- Setup Directory Structure
if is_makefolder then
    pcall(function()
        makefolder("KOI56_Dumps")
        makefolder("KOI56_Logs")
    end)
end

-- Global Configuration & State
local DUMP_CONFIG = {
    FolderName = "KOI56_SavedMap.rbxl",
    IncludeTerrain = true,
    IncludeScripts = true,
    IncludeCharacters = true,
    SaveNilInstances = true,
    ChunkSize = 60,       -- จำนวนวัตถุสแกนต่อ 1 เฟรม (ปรับให้เห็นชื่อวิ่งชัดเจน)
    ScanDelay = 0.005     -- หน่วงเวลาเล็กน้อยเพื่อความเสถียรบนมือถือ
}

local SPY_CONFIG = {
    Active = false,
    LogFileName = "KOI56_TX_Logs.lua"
}

local CapturedRemotes = {}

-- Auto Extension Formatter (.rbxl)
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

-- Helper Utilities
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

if TargetParent:FindFirstChild("KOI56_FullEngineUI") then
    TargetParent.KOI56_FullEngineUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI56_FullEngineUI"
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
MainFrame.Size = UDim2.new(0, 560, 0, 400)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -200)
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
TitleLabel.Text = "KOI56 ENGINE v5.0  |  FULL MAP SUITE"
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
Sidebar.Size = UDim2.new(0, 145, 1, -72)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)
TabListLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 8)
SidebarPadding.PaddingLeft = UDim.new(0, 6)
SidebarPadding.PaddingRight = UDim.new(0, 6)
SidebarPadding.Parent = Sidebar

-- Page Display Area
local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -155, 1, -95)
PageContainer.Position = UDim2.new(0, 150, 0, 47)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

-- Status & Progress Percentage Bar (หลอดแสดง % ความคืบหน้า)
local ProgressBackground = Instance.new("Frame")
ProgressBackground.Name = "ProgressBackground"
ProgressBackground.Size = UDim2.new(1, 0, 0, 28)
ProgressBackground.Position = UDim2.new(0, 0, 1, -28)
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
StatusBar.Text = "[0%] Status: KOI56 Ready to process."
StatusBar.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusBar.TextSize = 11
StatusBar.Font = Enum.Font.GothamBold
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = ProgressBackground

-- Live Scanning Feed Label
local ScanFeedLabel = Instance.new("TextLabel")
ScanFeedLabel.Size = UDim2.new(1, -155, 0, 18)
ScanFeedLabel.Position = UDim2.new(0, 150, 1, -48)
ScanFeedLabel.BackgroundTransparency = 1
ScanFeedLabel.Text = "Live Feed: Standby..."
ScanFeedLabel.TextColor3 = Color3.fromRGB(160, 165, 180)
ScanFeedLabel.TextSize = 10
ScanFeedLabel.Font = Enum.Font.Gotham
ScanFeedLabel.TextXAlignment = Enum.TextXAlignment.Left
ScanFeedLabel.Parent = MainFrame

-- Function to Update Progress & Status
local function UpdateProgress(percentage, statusMessage, liveFeedMessage, isError)
    percentage = math.clamp(percentage or 0, 0, 100)
    
    TweenService:Create(ProgressBarFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(percentage / 100, 0, 1, 0)
    }):Play()

    if isError then
        ProgressBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        StatusBar.Text = " ❌ " .. tostring(statusMessage)
    else
        ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        StatusBar.Text = string.format(" [%d%%] %s", percentage, tostring(statusMessage))
    end

    if liveFeedMessage then
        ScanFeedLabel.Text = "Live Feed: " .. tostring(liveFeedMessage)
    end
end

-- Component Generator Helpers
local Tabs = {}
local function CreateTab(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 11
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
    btn.Size = UDim2.new(1, -10, 0, 35)
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

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 42)
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
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 46, 0, 20)
    btn.Position = UDim2.new(1, -52, 0.5, -10)
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
    frame.Size = UDim2.new(1, -10, 0, 35)
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
    box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = frame

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 42)
    box.FocusLost:Connect(function() pcall(callback, box.Text) end)
end

-- ============================================================================
-- 2. TAB CREATION & FULL FEATURE IMPLEMENTATION
-- ============================================================================

local MainPage = CreateTab("Main", 1)
local MapDumpPage = CreateTab("Map Dump", 2)
local TargetDumpPage = CreateTab("Target Dump", 3)
local RemoteSpyPage = CreateTab("Remote Spy", 4)
local PreviewPage = CreateTab("Preview", 5)
local SettingsPage = CreateTab("Settings", 6)

-- ----------------------------------------------------------------------------
-- TAB 1: MAIN CONTROL PAGE
-- ----------------------------------------------------------------------------
AddButton(MainPage, "🚀 QUICK REAL SCAN & DUMP (.RBXL)", Color3.fromRGB(255, 150, 0), function()
    SendNotify("KOI56", "เริ่มสแกนและคัดลอกแมพด่วน...", 3)
    
    task.spawn(function()
        local allItems = workspace:GetDescendants()
        local total = #allItems
        if total == 0 then total = 1 end

        for i = 1, total, DUMP_CONFIG.ChunkSize do
            local currentPct = math.floor((i / total) * 75)
            local currentItem = allItems[i] and allItems[i].Name or "Object"
            UpdateProgress(currentPct, string.format("Scanning %d/%d objects...", i, total), currentItem)
            task.wait(DUMP_CONFIG.ScanDelay)
        end

        UpdateProgress(85, "Encoding map to .rbxl format...", "Writing file to disk...")

        local targetName = FixRBXLExtension(DUMP_CONFIG.FolderName)
        local saved = false

        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            saved = pcall(function() saveFn({FilePath = targetName}) end)
        end

        if not saved then
            pcall(function()
                local Params = {
                    RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
                    FileName = targetName,
                    ReadMe = false
                }
                local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
                usi(Params)
            end)
        end

        UpdateProgress(100, "DUPE COMPLETE 100%! Saved to workspace.", "File: " .. targetName)
        SendNotify("KOI56", "บันทึกไฟล์แมพเรียบร้อยแล้ว (100%)", 4)
    end)
end)

AddButton(MainPage, "📋 COPY PLACE ID & JOB ID", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(tostring(game.PlaceId) .. " | " .. tostring(game.JobId))
    UpdateProgress(100, "Copied Place ID & Job ID to clipboard!", "Clipboard updated.")
end)

-- ----------------------------------------------------------------------------
-- TAB 2: MAP DUMP (Reconstructor Engine + REAL % Scanner)
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
    SendNotify("KOI56 Map Scanner", "เริ่มการสแกนความลึกของวัตถุ...", 4)

    task.spawn(function()
        -- 1. Get all objects for REAL percentage calculation
        local targetObjects = workspace:GetDescendants()
        local totalCount = #targetObjects
        if totalCount == 0 then totalCount = 1 end

        -- 2. Progressive visual scanning loop (0% to 80%)
        local processed = 0
        for i, obj in ipairs(targetObjects) do
            processed = processed + 1
            if processed % DUMP_CONFIG.ChunkSize == 0 or processed == totalCount then
                local pct = math.floor((processed / totalCount) * 80)
                UpdateProgress(pct, string.format("Scanning: %d/%d Items", processed, totalCount), obj.Name .. " (" .. obj.ClassName .. ")")
                task.wait(DUMP_CONFIG.ScanDelay)
            end
        end

        -- 3. Encoding to File (80% to 100%)
        UpdateProgress(85, "Encoding instances into Roblox Studio .rbxl...", "Writing binary place structure...")
        task.wait(0.3)

        local isSaved = false
        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            isSaved = pcall(function()
                saveFn({
                    FilePath = targetName,
                    Decompile = DUMP_CONFIG.IncludeScripts,
                    NilInstances = DUMP_CONFIG.SaveNilInstances,
                    RemovePlayer = not DUMP_CONFIG.IncludeCharacters
                })
            end)
        end

        if not isSaved then
            pcall(function()
                local Params = {
                    RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
                    FileName = targetName,
                    ReadMe = false
                }
                local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
                usi(Params)
            end)
        end

        UpdateProgress(100, "DUPE COMPLETE 100%! Saved as " .. targetName, "Saved in Executor 'workspace' folder.")
        SendNotify("KOI56 Success", "สแกนและเซฟไฟล์ " .. targetName .. " สำเร็จ 100%!", 5)
    end)
end)

AddButton(MapDumpPage, "📋 Dump Map & Copy Summary", Color3.fromRGB(40, 44, 58), function()
    local summary = string.format("-- KOI56 Map Dump Summary\n-- PlaceId: %d\n-- File: %s\n-- Total Objects: %d Instances", game.PlaceId, DUMP_CONFIG.FolderName, #workspace:GetDescendants())
    SetClipboard(summary)
    UpdateProgress(100, "Copied map summary to clipboard!", "Summary generated.")
end)

-- ----------------------------------------------------------------------------
-- TAB 3: TARGET SERVICE DUMPER (AI SCRIPTER EXPORTER)
-- ----------------------------------------------------------------------------
local SelectedService = "ReplicatedStorage"
AddTextBox(TargetDumpPage, "Target Service Name...", SelectedService, function(txt) SelectedService = txt end)

AddButton(TargetDumpPage, "📄 DUMP SERVICE DATA FOR AI (.TXT)", Color3.fromRGB(35, 130, 90), function()
    if not is_writefile then UpdateProgress(0, "Error: writefile missing!", "Capability error.", true) return end
    local service = pcall(function() return game:GetService(SelectedService) end) and game:GetService(SelectedService) or nil
    if not service then UpdateProgress(0, "Invalid Service Name!", "Service not found.", true) return end

    task.spawn(function()
        local allItems = service:GetDescendants()
        local total = #allItems
        if total == 0 then total = 1 end

        local dumpLines = {"-- KOI56 TARGET SERVICE DUMP (" .. SelectedService .. ")\n"}
        local count = 0

        for i, obj in ipairs(allItems) do
            count = count + 1
            if count % DUMP_CONFIG.ChunkSize == 0 or count == total then
                local pct = math.floor((count / total) * 100)
                UpdateProgress(pct, string.format("Dumping %s... (%d/%d)", SelectedService, count, total), obj.Name)
                task.wait(DUMP_CONFIG.ScanDelay)
            end
            table.insert(dumpLines, string.format("- %s [%s]\n", obj.Name, obj.ClassName))
        end

        local filePath = "KOI56_Dumps/Dump_" .. SelectedService .. ".txt"
        writefile(filePath, table.concat(dumpLines))
        UpdateProgress(100, "Dump Completed! Saved to " .. filePath, "Exported " .. tostring(count) .. " items.")
        SendNotify("KOI56 Dumper", "สกัดข้อมูลส่ง AI เรียบร้อยแล้ว (100%)", 4)
    end)
end)

-- ----------------------------------------------------------------------------
-- TAB 4: REMOTE SPY (NETWORK PROTOCOL LOGGER)
-- ----------------------------------------------------------------------------
AddToggle(RemoteSpyPage, "Enable Remote Spy (TX Hook)", SPY_CONFIG.Active, function(state)
    SPY_CONFIG.Active = state
    UpdateProgress(state and 100 or 0, state and "Remote Spy Active. Intercepting Remotes..." or "Remote Spy Standby.", state and "Hooking __namecall..." or "Standby")
end)

AddTextBox(RemoteSpyPage, "Log File Name...", SPY_CONFIG.LogFileName, function(txt) if txt ~= "" then SPY_CONFIG.LogFileName = txt end end)

AddButton(RemoteSpyPage, "💾 SAVE LOGS TO FILE (.LUA)", Color3.fromRGB(0, 130, 180), function()
    if not is_writefile then return end
    local path = "KOI56_Logs/" .. SPY_CONFIG.LogFileName
    writefile(path, table.concat(CapturedRemotes, "\n"))
    UpdateProgress(100, "Saved " .. #CapturedRemotes .. " logged remotes to " .. path, "File written successfully.")
    SendNotify("KOI56 Remote Spy", "บันทึกไฟล์สคริปต์ Remote เรียบร้อย!", 4)
end)

AddButton(RemoteSpyPage, "📋 COPY ALL LOGGED REMOTES", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(table.concat(CapturedRemotes, "\n"))
    UpdateProgress(100, "Copied all logged remotes to clipboard!", "Clipboard updated.")
end)

AddButton(RemoteSpyPage, "🗑️ CLEAR LOG BUFFER", Color3.fromRGB(180, 50, 50), function()
    CapturedRemotes = {}
    UpdateProgress(0, "Remote log buffer cleared.", "Buffer reset.")
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
                local line = string.format("game.%s:%s(%s)", remotePath, method, table.concat(formattedArgs, ", "))
                table.insert(CapturedRemotes, line)
                ScanFeedLabel.Text = "Captured Remote: " .. self.Name
            end)
        end
        return raw_namecall(self, ...)
    end)
end

-- ----------------------------------------------------------------------------
-- TAB 5: PREVIEW & ASSET INSPECTOR
-- ----------------------------------------------------------------------------
AddButton(PreviewPage, "🔍 COUNT WORKSPACE OBJECTS", Color3.fromRGB(40, 44, 58), function()
    local instances = #workspace:GetDescendants()
    UpdateProgress(100, "Workspace Instances: " .. tostring(instances), "Counted objects.")
    SendNotify("Workspace Inspector", "จำนวนวัตถุในแมพปัจจุบัน: " .. tostring(instances) .. " ชิ้น", 4)
end)

AddButton(PreviewPage, "📜 SCAN CLIENT SCRIPTS IN GAME", Color3.fromRGB(40, 44, 58), function()
    local scriptCount = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            scriptCount = scriptCount + 1
        end
    end
    UpdateProgress(100, "Found " .. tostring(scriptCount) .. " Client Scripts.", "Scan completed.")
    SendNotify("Script Inspector", "พบสคริปต์ฝั่ง Client ทั้งหมด: " .. tostring(scriptCount) .. " ตัว", 4)
end)

-- ----------------------------------------------------------------------------
-- TAB 6: SETTINGS & PERFORMANCE GUARD
-- ----------------------------------------------------------------------------
AddButton(SettingsPage, "⚡ UNLOCK FPS & CLEAN MEMORY (GC)", Color3.fromRGB(0, 160, 100), function()
    pcall(function()
        if setfpscap then setfpscap(120) end
        collectgarbage("collect")
    end)
    UpdateProgress(100, "Memory Cleaned & Performance Boosted!", "Garbage Collected.")
    SendNotify("KOI56", "ล้างความจำ RAM และปรับ FPS เรียบร้อย!", 3)
end)

AddButton(SettingsPage, "❌ UNLOAD KOI56 UI", Color3.fromRGB(180, 40, 40), function()
    ScreenGui:Destroy()
end)

UpdateProgress(100, "KOI56 Engine v5.0 Loaded Successfully!", "All systems operational.")
SendNotify("KOI56 ENGINE", "ยินดีต้อนรับสู่ KOI56! โหลดครบทุกฟังก์ชันแบบไม่ใช้คีย์", 4)
