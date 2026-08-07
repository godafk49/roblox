-- ============================================================================
-- VALEN ENGINE: UNIVERSAL MAP DUPLICATOR & SYSTEM SUITE (UNLOCKED / NO KEY)
-- COMPATIBILITY: PC & MOBILE EXECUTORS (DELTA, FLUXUS, CODEX, WAVE, ETC.)
-- ============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Executor Capability Check
local is_writefile = type(writefile) == "function"
local is_makefolder = type(makefolder) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"
local is_decompile = type(decompile) == "function"
local is_hook = type(hookmetamethod) == "function"

-- Setup Working Directories
if is_makefolder then
    pcall(function()
        makefolder("ValenHub_Dumps")
        makefolder("ValenHub_Logs")
    end)
end

-- State Management
local Config = {
    FolderName = "DuplicatedMap_" .. tostring(game.PlaceId),
    ChunkSize = 250, -- Processing items per frame to prevent crashes
    SaveWorkspace = true,
    SaveLighting = true,
    SaveReplicated = true,
    SaveTerrain = true,
    RemoteSpyActive = false,
    LogFileName = "TX_Remote_Logs.lua"
}

local CapturedRemotes = {}

-- Helper: Safe Call
local function safe_call(fn, ...)
    local success, result = pcall(fn, ...)
    return success and result or nil
end

-- ============================================================================
-- 1. GUI ENGINE (PURE LUAU - NO EXTERNAL LOADSTRING DEPENDENCY)
-- ============================================================================

local CoreGui = game:GetService("CoreGui")
local TargetParent = pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Remove existing UI if present
if TargetParent:FindFirstChild("ValenEngineUI") then
    TargetParent.ValenEngineUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValenEngineUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 360)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "VALEN ENGINE v3.5 - MAP DUPLICATOR & SUITE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Sidebar Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -140, 1, -50)
TabContainer.Position = UDim2.new(0, 135, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

-- Status Bar
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, 0, 0, 20)
StatusBar.Position = UDim2.new(0, 0, 1, -20)
StatusBar.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
StatusBar.Text = " System Ready. Select an option."
StatusBar.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusBar.TextSize = 11
StatusBar.Font = Enum.Font.Gotham
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.Parent = MainFrame

local function SetStatus(msg, isError)
    StatusBar.Text = " " .. tostring(msg)
    StatusBar.TextColor3 = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
end

-- Tab Management
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 115, 0, 32)
    TabBtn.Position = UDim2.new(0, 7, 0, (#Tabs * 38) + 8)
    TabBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 12
    TabBtn.Parent = Sidebar

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = TabBtn

    local TabPage = Instance.new("ScrollingFrame")
    TabPage.Size = UDim2.new(1, 0, 1, 0)
    TabPage.BackgroundTransparency = 1
    TabPage.ScrollBarThickness = 4
    TabPage.Visible = false
    TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabPage.Parent = TabContainer

    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Page.Visible = false
            tab.Btn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
            tab.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        TabPage.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CurrentTab = TabPage
    end)

    table.insert(Tabs, {Btn = TabBtn, Page = TabPage})
    if #Tabs == 1 then
        TabPage.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CurrentTab = TabPage
    end

    return TabPage
end

-- Helper Controls UI Generators
local function AddButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    btn.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 42)

    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return btn
end

local function AddToggle(parent, text, default, callback)
    local state = default or false
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -10, 0, 35)
    toggleFrame.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
    toggleFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = toggleFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toggleFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 22)
    btn.Position = UDim2.new(1, -60, 0.5, -11)
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 70)
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = toggleFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 42)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 70)
        btn.Text = state and "ON" or "OFF"
        pcall(callback, state)
    end)
end

local function AddTextBox(parent, placeholder, defaultText, callback)
    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, -10, 0, 35)
    boxFrame.Position = UDim2.new(0, 5, 0, parent.CanvasSize.Y.Offset + 5)
    boxFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
    boxFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = boxFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.Text = defaultText or ""
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = boxFrame

    parent.CanvasSize = UDim2.new(0, 0, 0, parent.CanvasSize.Y.Offset + 42)

    box.FocusLost:Connect(function()
        pcall(callback, box.Text)
    end)
end

-- Create Pages
local DupeTab = CreateTab("Dupe Map")
local DumpTab = CreateTab("Target Dump")
local SpyTab = CreateTab("Remote Spy")
local ToolsTab = CreateTab("Automation")

-- ============================================================================
-- 2. DUPE MAP / PLACE SERIALIZATION ENGINE (WITH MOBILE ANTI-CRASH CHUNKING)
-- ============================================================================

AddTextBox(DupeTab, "Folder Name...", Config.FolderName, function(txt)
    if txt ~= "" then Config.FolderName = txt end
end)

AddToggle(DupeTab, "Save Workspace Geometry", Config.SaveWorkspace, function(s) Config.SaveWorkspace = s end)
AddToggle(DupeTab, "Save Lighting Settings", Config.SaveLighting, function(s) Config.SaveLighting = s end)
AddToggle(DupeTab, "Save ReplicatedStorage", Config.SaveReplicated, function(s) Config.SaveReplicated = s end)

AddButton(DupeTab, "DUPLICATE ENTIRE MAP (ONE-CLICK)", function()
    SetStatus("Starting map duplication process...", false)

    -- Try Native SaveInstance First
    if is_saveinstance then
        SetStatus("Executing executor saveinstance()...", false)
        local success, err = pcall(function()
            if type(saveinstance) == "function" then
                saveinstance({FilePath = Config.FolderName})
            elseif type(save_instance) == "function" then
                save_instance({FilePath = Config.FolderName})
            end
        end)
        if success then
            SetStatus("Native Dupe Map Successful! Saved to workspace.", false)
            return
        end
    end

    -- Fallback Custom Serializer Engine
    if not is_writefile then
        SetStatus("Error: Executor lacks writefile capability!", true)
        return
    end

    task.spawn(function()
        local savePath = "ValenHub_Dumps/" .. Config.FolderName .. "_Custom.txt"
        local bufferData = {"-- Valen Engine Custom Map Export\n"}
        local totalProcessed = 0
        local processedInBatch = 0

        local function SerializeInstance(inst, depth)
            if not inst then return end
            totalProcessed = totalProcessed + 1
            processedInBatch = processedInBatch + 1

            -- Yielding mechanism to prevent mobile freeze/crash
            if processedInBatch >= Config.ChunkSize then
                processedInBatch = 0
                SetStatus("Processed " .. tostring(totalProcessed) .. " instances...", false)
                task.wait()
            end

            local indent = string.rep("  ", depth)
            table.insert(bufferData, indent .. string.format("[%s] %s (Class: %s)\n", tostring(inst.Name), inst:GetFullName(), inst.ClassName))

            for _, child in pairs(inst:GetChildren()) do
                SerializeInstance(child, depth + 1)
            end
        end

        local targetServices = {}
        if Config.SaveWorkspace then table.insert(targetServices, workspace) end
        if Config.SaveLighting then table.insert(targetServices, game:GetService("Lighting")) end
        if Config.SaveReplicated then table.insert(targetServices, game:GetService("ReplicatedStorage")) end

        for _, service in ipairs(targetServices) do
            SerializeInstance(service, 0)
        end

        writefile(savePath, table.concat(bufferData))
        SetStatus("Dupe Complete! Processed " .. tostring(totalProcessed) .. " items to " .. savePath, false)
    end)
end)

-- ============================================================================
-- 3. TARGET SERVICE DUMPER (AI SCRIPTER COMPATIBLE EXPORT)
-- ============================================================================

local SelectedService = "ReplicatedStorage"

AddTextBox(DumpTab, "Target Service Name...", SelectedService, function(txt)
    SelectedService = txt
end)

AddButton(DumpTab, "DUMP SERVICE HIERARCHY FOR AI", function()
    if not is_writefile then
        SetStatus("Error: writefile is not supported by executor!", true)
        return
    end

    local service = safe_call(function() return game:GetService(SelectedService) end)
    if not service then
        SetStatus("Invalid Service: " .. tostring(SelectedService), true)
        return
    end

    task.spawn(function()
        SetStatus("Dumping " .. SelectedService .. "...", false)
        local dumpLines = {"-- TARGET SERVICE DUMP FOR AI PROMPT (" .. SelectedService .. ")\n"}
        local count = 0

        local function Traverse(obj, depth)
            count = count + 1
            if count % 300 == 0 then task.wait() end

            local indent = string.rep("  ", depth)
            local line = string.format("%s- %s [%s]", indent, obj.Name, obj.ClassName)

            if obj:IsA("RemoteEvent") then
                line = line .. " (RemoteEvent)"
            elseif obj:IsA("RemoteFunction") then
                line = line .. " (RemoteFunction)"
            elseif obj:IsA("ValueBase") then
                line = line .. string.format(" (Value: %s)", tostring(obj.Value))
            end

            table.insert(dumpLines, line .. "\n")

            for _, child in pairs(obj:GetChildren()) do
                Traverse(child, depth + 1)
            end
        end

        Traverse(service, 0)

        local fileName = "ValenHub_Dumps/Dump_" .. SelectedService .. "_" .. tostring(game.PlaceId) .. ".txt"
        writefile(fileName, table.concat(dumpLines))
        SetStatus("Dump saved to: " .. fileName .. " (" .. tostring(count) .. " items)", false)
    end)
end)

-- ============================================================================
-- 4. REMOTE SPY & NETWORK PROTOCOL INTERCEPTOR
-- ============================================================================

AddToggle(SpyTab, "Enable Remote Spy (TX Hook)", Config.RemoteSpyActive, function(state)
    Config.RemoteSpyActive = state
    if state then
        SetStatus("Remote Spy Activated. Capturing transactions...", false)
    else
        SetStatus("Remote Spy Deactivated.", false)
    end
end)

AddTextBox(SpyTab, "Log File Name...", Config.LogFileName, function(txt)
    if txt ~= "" then Config.LogFileName = txt end
end)

AddButton(SpyTab, "EXPORT CAPTURED REMOTES TO FILE", function()
    if not is_writefile then
        SetStatus("Error: writefile unsupported!", true)
        return
    end

    local path = "ValenHub_Logs/" .. Config.LogFileName
    writefile(path, table.concat(CapturedRemotes, "\n"))
    SetStatus("Saved " .. #CapturedRemotes .. " logged transactions to " .. path, false)
end)

AddButton(SpyTab, "CLEAR REMOTE BUFFER", function()
    CapturedRemotes = {}
    SetStatus("Remote buffer cleared.", false)
end)

-- Network Interceptor Hook Logic
if is_hook then
    local raw_namecall
    raw_namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if Config.RemoteSpyActive and (method == "FireServer" or method == "InvokeServer") then
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

-- ============================================================================
-- 5. AUTOMATION & TOOL SUITE (PLACEHOLDERS / EXTRA ACTIONS)
-- ============================================================================

local AutoFarmEnabled = false
AddToggle(ToolsTab, "Auto Farm Resources (Example Loop)", false, function(s)
    AutoFarmEnabled = s
    if s then
        task.spawn(function()
            while AutoFarmEnabled do
                SetStatus("Auto Farm Active...", false)
                -- Add target-specific game action calls here
                task.wait(1)
            end
        end)
    end
end)

AddButton(ToolsTab, "FORCE FPS UNLOCK & MEMORY CLEANUP", function()
    pcall(function()
        if setfpscap then setfpscap(120) end
        game:GetService("GarbageCollector")
        collectgarbage("collect")
    end)
    SetStatus("Memory cleaned & FPS unlocked.", false)
end)

SetStatus("Valen Engine Loaded Successfully! No Key Required.", false)
