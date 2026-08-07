-- ============================================================================
-- VALEN HUB: ULTIMATE EDITION (FULL UNLOCKED / NO KEY SYSTEM)
-- FULLY FEATURED: DUPE MAP (.RBXL) | TARGET DUMP | REMOTE SPY | PREVIEW
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

-- Global State & Settings
local DUMP_CONFIG = {
    FolderName = "ValenHub_SavedMap.rbxl",
    IncludeTerrain = true,
    IncludeScripts = true,
    IncludeCharacters = true,
    SaveNilInstances = true,
    ChunkSize = 250
}

local SPY_CONFIG = {
    Active = false,
    LogFileName = "TX_Remote_Logs.lua"
}

local CapturedRemotes = {}

-- Auto-Fix File Extension Helper
local function FixRBXLExtension(fileName)
    if not fileName or fileName == "" then
        fileName = "ValenHub_SavedMap.rbxl"
    end
    fileName = fileName:gsub("%.txt$", "")
    if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then
        fileName = fileName .. ".rbxl"
    end
    return fileName
end

-- Helper: System Notification
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
-- 1. MODERN TOUCH-FRIENDLY GUI ENGINE
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("ValenHub_UltimateUI") then
    TargetParent.ValenHub_UltimateUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValenHub_UltimateUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Floating Action Button (สำหรับกดซ่อน/แสดงบนมือถือ)
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Name = "MobileToggleBtn"
MobileToggleBtn.Size = UDim2.new(0, 45, 0, 45)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 27, 36)
MobileToggleBtn.Text = "V"
MobileToggleBtn.TextColor3 = Color3.fromRGB(0, 170, 255)
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.TextSize = 22
MobileToggleBtn.Active = true
MobileToggleBtn.Draggable = true
MobileToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = MobileToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = MobileToggleBtn

-- Main GUI Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 370)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -185)
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
MainStroke.Color = Color3.fromRGB(35, 38, 50)
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
TitleLabel.Text = "VALEN HUB  |  ULTIMATE DUMPER & SUITE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

MobileToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Sidebar Menu Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -42)
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

-- Tab Pages Display Container
local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -150, 1, -65)
PageContainer.Position = UDim2.new(0, 145, 0, 47)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

-- Status Bar (แถบสถานะล่างสุด)
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, 0, 0, 22)
StatusBar.Position = UDim2.new(0, 0, 1, -22)
StatusBar.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
StatusBar.Text = " Status: Ready. Unlocked & Loaded."
StatusBar.TextColor3 = Color3.fromRGB(100, 220, 140)
StatusBar.TextSize = 11
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = MainFrame

local function SetStatus(msg, isError)
    StatusBar.Text = " " .. tostring(msg)
    StatusBar.TextColor3 = isError and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(100, 220, 140)
end

-- Tab Router Logic
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
    Page.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
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
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    table.insert(Tabs, {Btn = TabBtn, Page = Page})
    if #Tabs == 1 then
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return Page
end

-- Custom Component Generators
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
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(55, 58, 70)
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
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(55, 58, 70)
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
-- 2. TAB CREATION (Main, Map Dump, Target Dump, Remote Spy, Preview, Settings)
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
AddButton(MainPage, "🚀 QUICK DUMP ENTIRE MAP (.RBXL)", Color3.fromRGB(0, 120, 215), function()
    SetStatus("Executing Quick Map Duplication...", false)
    SendNotify("Valen Hub", "เริ่มกระบวนการคัดลอกแมพด่วน...", 3)
    
    if is_saveinstance then
        local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
        local ok = pcall(function()
            saveFn({FilePath = FixRBXLExtension(DUMP_CONFIG.FolderName)})
        end)
        if ok then
            SetStatus("Success! Saved map to workspace folder.", false)
            SendNotify("Valen Hub", "บันทึกแมพเป็น .rbxl สำเร็จ!", 4)
            return
        end
    end

    -- Universal Loader Fallback
    task.spawn(function()
        local Params = {
            RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
            FileName = FixRBXLExtension(DUMP_CONFIG.FolderName),
            ReadMe = false
        }
        local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
        usi(Params)
        SetStatus("Map Duplication Completed!", false)
    end)
end)

AddButton(MainPage, "📋 COPY PLACE ID & JOB ID", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(tostring(game.PlaceId) .. " | " .. tostring(game.JobId))
    SetStatus("Copied Place ID and Job ID to clipboard.", false)
end)

-- ----------------------------------------------------------------------------
-- TAB 2: MAP DUMP (Reconstructor Engine - 100% Video Features)
-- ----------------------------------------------------------------------------
AddTextBox(MapDumpPage, "Folder/File Name (.rbxl)...", DUMP_CONFIG.FolderName, function(txt)
    DUMP_CONFIG.FolderName = FixRBXLExtension(txt)
end)

AddToggle(MapDumpPage, "Include Terrain", DUMP_CONFIG.IncludeTerrain, function(v) DUMP_CONFIG.IncludeTerrain = v end)
AddToggle(MapDumpPage, "Include Scripts", DUMP_CONFIG.IncludeScripts, function(v) DUMP_CONFIG.IncludeScripts = v end)
AddToggle(MapDumpPage, "Include Characters (Humanoid, Animator)", DUMP_CONFIG.IncludeCharacters, function(v) DUMP_CONFIG.IncludeCharacters = v end)
AddToggle(MapDumpPage, "Save Hidden Nil Instances", DUMP_CONFIG.SaveNilInstances, function(v) DUMP_CONFIG.SaveNilInstances = v end)

AddButton(MapDumpPage, "💾 Save as Studio File (.rbxl)", Color3.fromRGB(0, 140, 220), function()
    local targetName = FixRBXLExtension(DUMP_CONFIG.FolderName)
    SetStatus("Processing map save: " .. targetName, false)
    SendNotify("Map Reconstructor", "กำลังเซฟแมพเป็นไฟล์ Roblox Studio...", 4)

    task.spawn(function()
        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            local success, err = pcall(function()
                saveFn({
                    FilePath = targetName,
                    Decompile = DUMP_CONFIG.IncludeScripts,
                    NilInstances = DUMP_CONFIG.SaveNilInstances,
                    RemovePlayer = not DUMP_CONFIG.IncludeCharacters
                })
            end)
            if success then
                SetStatus("SAVED SUCCESS: " .. targetName, false)
                SendNotify("Map Dump Success", "เซฟไฟล์ " .. targetName .. " ลงโฟลเดอร์ workspace เรียบร้อยแล้ว!", 5)
                return
            end
        end

        -- Fallback Engine
        pcall(function()
            local Params = {
                RepoURL = "https://raw.githubusercontent.com/Luau-SaveInstance/saveinstance/main/",
                FileName = targetName,
                ReadMe = false
            }
            local usi = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau", true))()
            usi(Params)
        end)
        SetStatus("Saved via Universal Engine to workspace/", false)
    end)
end)

AddButton(MapDumpPage, "📋 Dump Map & Copy to Clipboard", Color3.fromRGB(40, 44, 58), function()
    local dumpSummary = string.format("-- Valen Hub Map Summary\n-- PlaceId: %d\n-- Folder: %s\n-- Instances: %d Objects in Workspace", game.PlaceId, DUMP_CONFIG.FolderName, #workspace:GetDescendants())
    SetClipboard(dumpSummary)
    SetStatus("Map structure summary copied to clipboard!", false)
end)

-- ----------------------------------------------------------------------------
-- TAB 3: TARGET SERVICE DUMPER (AI SCRIPTER EXPORTER)
-- ----------------------------------------------------------------------------
local SelectedService = "ReplicatedStorage"
AddTextBox(TargetDumpPage, "Target Service Name...", SelectedService, function(txt) SelectedService = txt end)

AddButton(TargetDumpPage, "📄 DUMP SERVICE DATA FOR AI (.TXT)", Color3.fromRGB(35, 130, 90), function()
    if not is_writefile then SetStatus("Error: writefile missing!", true) return end
    local service = pcall(function() return game:GetService(SelectedService) end) and game:GetService(SelectedService) or nil
    if not service then SetStatus("Invalid Service!", true) return end

    task.spawn(function()
        SetStatus("Exporting " .. SelectedService .. " structure...", false)
        local dumpLines = {"-- TARGET SERVICE DUMP FOR AI PROMPT (" .. SelectedService .. ")\n"}
        local count = 0

        local function Traverse(obj, depth)
            count = count + 1
            if count % 300 == 0 then task.wait() end
            local indent = string.rep("  ", depth)
            table.insert(dumpLines, string.format("%s- %s [%s]\n", indent, obj.Name, obj.ClassName))
            for _, child in pairs(obj:GetChildren()) do Traverse(child, depth + 1) end
        end

        Traverse(service, 0)
        local filePath = "ValenHub_Dump_" .. SelectedService .. ".txt"
        writefile(filePath, table.concat(dumpLines))
        SetStatus("Dump saved to: " .. filePath .. " (" .. tostring(count) .. " items)", false)
        SendNotify("Target Dumper", "สร้างไฟล์โครงสร้างสำหรับส่งให้ AI เรียบร้อยแล้ว!", 4)
    end)
end)

-- ----------------------------------------------------------------------------
-- TAB 4: REMOTE SPY (NETWORK PROTOCOL LOGGER)
-- ----------------------------------------------------------------------------
AddToggle(RemoteSpyPage, "Enable Remote Spy (TX Hook)", SPY_CONFIG.Active, function(state)
    SPY_CONFIG.Active = state
    SetStatus(state and "Remote Spy Active. Recording Network Calls..." or "Remote Spy Standby.", false)
end)

AddTextBox(RemoteSpyPage, "Log File Name...", SPY_CONFIG.LogFileName, function(txt) if txt ~= "" then SPY_CONFIG.LogFileName = txt end end)

AddButton(RemoteSpyPage, "💾 SAVE LOGS TO FILE (.LUA)", Color3.fromRGB(0, 130, 180), function()
    if not is_writefile then SetStatus("writefile unsupported!", true) return end
    writefile(SPY_CONFIG.LogFileName, table.concat(CapturedRemotes, "\n"))
    SetStatus("Saved " .. #CapturedRemotes .. " logs to " .. SPY_CONFIG.LogFileName, false)
    SendNotify("Remote Spy", "บันทึกสคริปต์ Remote ลงไฟล์เรียบร้อย!", 4)
end)

AddButton(RemoteSpyPage, "📋 COPY ALL REMOTES TO CLIPBOARD", Color3.fromRGB(45, 48, 62), function()
    SetClipboard(table.concat(CapturedRemotes, "\n"))
    SetStatus("Copied " .. #CapturedRemotes .. " remotes to clipboard!", false)
end)

AddButton(RemoteSpyPage, "🗑️ CLEAR LOG BUFFER", Color3.fromRGB(180, 50, 50), function()
    CapturedRemotes = {}
    SetStatus("Remote log buffer cleared.", false)
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
                local scriptLine = string.format("game.%s:%s(%s)", remotePath, method, table.concat(formattedArgs, ", "))
                table.insert(CapturedRemotes, scriptLine)
            end)
        end
        return raw_namecall(self, ...)
    end)
end

-- ----------------------------------------------------------------------------
-- TAB 5: PREVIEW & ASSET INSPECTOR
-- ----------------------------------------------------------------------------
AddButton(PageContainer and PreviewPage or MainPage, "🔍 COUNT WORKSPACE OBJECTS", Color3.fromRGB(40, 44, 58), function()
    local instances = #workspace:GetDescendants()
    SetStatus("Workspace contains " .. tostring(instances) .. " instances.", false)
    SendNotify("Workspace Inspector", "จำนวนวัตถุในแมพปัจจุบัน: " .. tostring(instances) .. " ชิ้น", 4)
end)

AddButton(PreviewPage, "📜 SCAN LOCAL SCRIPTS IN GAME", Color3.fromRGB(40, 44, 58), function()
    local scriptCount = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            scriptCount = scriptCount + 1
        end
    end
    SetStatus("Found " .. tostring(scriptCount) .. " client-side scripts.", false)
    SendNotify("Script Inspector", "พบสคริปต์ฝั่ง Client ทั้งหมด: " .. tostring(scriptCount) .. " ตัว", 4)
end)

-- ----------------------------------------------------------------------------
-- TAB 6: SETTINGS & PERFORMANCE GUARD
-- ----------------------------------------------------------------------------
AddButton(SettingsPage, "⚡ UNLOCK FPS & CLEAN MEMORY", Color3.fromRGB(0, 160, 100), function()
    pcall(function()
        if setfpscap then setfpscap(120) end
        collectgarbage("collect")
    end)
    SetStatus("Memory cleaned & FPS set to high performance.", false)
    SendNotify("Performance Guard", "ล้างความจำ RAM และปรับ FPS เรียบร้อย!", 3)
end)

AddButton(SettingsPage, "❌ UNLOAD VALEN HUB UI", Color3.fromRGB(180, 40, 40), function()
    ScreenGui:Destroy()
end)

SetStatus("Valen Hub Ultimate Loaded! Status: 100% Unlocked.", false)
SendNotify("Valen Hub", "โหลดสคริปต์สำเร็จ! พร้อมใช้งานโดยไม่ต้องใส่คีย์", 4)
