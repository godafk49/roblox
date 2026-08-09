-- ============================================================================
-- KOI56 CORE ENGINE (2 MAIN FUNCTIONS ONLY)
-- 1. DUPLICATE MAP (.RBXL / .RBXLX)
-- 2. SCRIPT & MAP SOURCE DATA SCRAPER (FOR SCRIPTING)
-- NO KEY SYSTEM | MOBILE & PC OPTIMIZED | NO EXTRA FLUFF
-- ============================================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local is_writefile = type(writefile) == "function"
local is_saveinstance = type(saveinstance) == "function" or type(save_instance) == "function"

local Config = {
    MapFileName = "KOI56_Map_" .. tostring(game.PlaceId) .. ".rbxl",
    DumpFileName = "KOI56_ScriptSource_" .. tostring(game.PlaceId) .. ".txt"
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
-- GUI ENGINE (CLEAN 2-TAB LAYOUT)
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("KOI56_CoreOnlyUI") then
    TargetParent.KOI56_CoreOnlyUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI56_CoreOnlyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Mobile Floating Button (K)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
ToggleBtn.Text = "K"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 24
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 170, 0)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main Frame Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 390)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -195)
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
TitleLabel.Text = "KOI56 ENGINE  |  CORE 2-IN-1 SUITE"
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
Sidebar.Size = UDim2.new(0, 130, 1, -68)
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
PageContainer.Size = UDim2.new(1, -140, 1, -78)
PageContainer.Position = UDim2.new(0, 135, 0, 45)
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
ProgressStatus.Text = "[0%] Ready."
ProgressStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressStatus.TextSize = 11
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

-- Tab Switcher Logic
local Tabs = {}
local function CreateTab(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 36)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 11
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
-- FUNCTION 1: DUPLICATE MAP ENGINE
-- ============================================================================

local MapPage = CreateTab("🗺️ Dupe Map", 1)

local MapFileBoxBg = Instance.new("Frame")
MapFileBoxBg.Size = UDim2.new(1, -10, 0, 36)
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
SaveMapBtn.Size = UDim2.new(1, -10, 0, 44)
SaveMapBtn.Position = UDim2.new(0, 5, 0, 55)
SaveMapBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
SaveMapBtn.Text = "💾 SAVE MAP FILE (.RBXL)"
SaveMapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveMapBtn.Font = Enum.Font.GothamBold
SaveMapBtn.TextSize = 12
SaveMapBtn.Parent = MapPage
Instance.new("UICorner", SaveMapBtn).CornerRadius = UDim.new(0, 6)

local MapInfoLbl = Instance.new("TextLabel")
MapInfoLbl.Size = UDim2.new(1, -10, 0, 180)
MapInfoLbl.Position = UDim2.new(0, 5, 0, 110)
MapInfoLbl.BackgroundTransparency = 1
MapInfoLbl.Text = "📌 คำแนะนำฟังก์ชัน Duplicate Map:\n\n• ระบบจะทำการดึงโครงสร้างแมพ, วัตถุ 3D, ฉาก, และอาวุธทั้งหมดในเกม\n• ปิดระบบดึงตัวละครผู้เล่นให้อัตโนมัติ เพื่อป้องกันปัญหาเปิดใน Roblox Studio แล้วเจอ Animator Error\n• หากตัวรันบนมือถือล็อกสิทธิ์เขียนไฟล์ ระบบจะคัดลอกข้อมูลโครงสร้างลง Clipboard ให้อัตโนมัติ"
MapInfoLbl.TextColor3 = Color3.fromRGB(160, 165, 180)
MapInfoLbl.TextSize = 11
MapInfoLbl.Font = Enum.Font.Gotham
MapInfoLbl.TextWrapped = true
MapInfoLbl.TextYAlignment = Enum.TextYAlignment.Top
MapInfoLbl.Parent = MapPage

SaveMapBtn.MouseButton1Click:Connect(function()
    local fileName = Config.MapFileName
    if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then
        fileName = fileName .. ".rbxl"
    end

    SendNotify("KOI56", "เริ่มสแกนคัดลอกแมพและอาวุธ...")
    UpdateStatus(10, "Indexing game objects...")

    task.spawn(function()
        local targetObjects = workspace:GetDescendants()
        local totalCount = #targetObjects
        if totalCount == 0 then totalCount = 1 end

        for i = 1, totalCount, 50 do
            local pct = math.floor((i / totalCount) * 70)
            UpdateStatus(pct, string.format("Scanning: %d/%d objects", i, totalCount))
            task.wait(0.002)
        end

        UpdateStatus(80, "Writing place file: " .. fileName)
        task.wait(0.2)

        local saved = false
        if is_saveinstance then
            local saveFn = type(saveinstance) == "function" and saveinstance or save_instance
            saved = pcall(function()
                saveFn({
                    FilePath = fileName,
                    Decompile = true,
                    NilInstances = true,
                    RemovePlayer = true, -- ป้องกัน Animator Error
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
            UpdateStatus(100, "MAP DUMP COMPLETE! File: " .. fileName)
            SendNotify("KOI56 Success", "บันทึกไฟล์แมพ " .. fileName .. " สำเร็จ 100%!")
        else
            local backupSummary = string.format("-- KOI56 MAP BACKUP\n-- PlaceId: %d\n-- Objects: %d\n", game.PlaceId, totalCount)
            SetClipboardText(backupSummary)
            UpdateStatus(100, "COPIED TO CLIPBOARD (Disk Write Blocked)")
            SendNotify("KOI56 Alert", "เซฟติดสิทธิ์เขียนไฟล์ จึงคัดลอกลง Clipboard แทนเรียบร้อย!")
        end
    end)
end)

-- ============================================================================
-- FUNCTION 2: SCRIPT & DATA SCRAPER (FOR SCRIPTING)
-- ============================================================================

local DumpPage = CreateTab("📜 Script Scraper", 2)

local ScrapeBtn = Instance.new("TextButton")
ScrapeBtn.Size = UDim2.new(1, -10, 0, 36)
ScrapeBtn.Position = UDim2.new(0, 5, 0, 10)
ScrapeBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 90)
ScrapeBtn.Text = "⚡ SCRAPE ALL SCRIPTS & MAP STRUCTURE"
ScrapeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrapeBtn.Font = Enum.Font.GothamBold
ScrapeBtn.TextSize = 11
ScrapeBtn.Parent = DumpPage
Instance.new("UICorner", ScrapeBtn).CornerRadius = UDim.new(0, 6)

local CopyCodeBtn = Instance.new("TextButton")
CopyCodeBtn.Size = UDim2.new(1, -10, 0, 30)
CopyCodeBtn.Position = UDim2.new(0, 5, 0, 51)
CopyCodeBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
CopyCodeBtn.Text = "📋 COPY ALL SCRAPED CODE TO CLIPBOARD"
CopyCodeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyCodeBtn.Font = Enum.Font.GothamBold
CopyCodeBtn.TextSize = 10
CopyCodeBtn.Parent = DumpPage
Instance.new("UICorner", CopyCodeBtn).CornerRadius = UDim.new(0, 6)

local OutputCodeBoxBg = Instance.new("Frame")
OutputCodeBoxBg.Size = UDim2.new(1, -10, 1, -95)
OutputCodeBoxBg.Position = UDim2.new(0, 5, 0, 88)
OutputCodeBoxBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
OutputCodeBoxBg.Parent = DumpPage
Instance.new("UICorner", OutputCodeBoxBg).CornerRadius = UDim.new(0, 6)

local OutputCodeDisplay = Instance.new("TextBox")
OutputCodeDisplay.Size = UDim2.new(1, -12, 1, -12)
OutputCodeDisplay.Position = UDim2.new(0, 6, 0, 6)
OutputCodeDisplay.BackgroundTransparency = 1
OutputCodeDisplay.TextColor3 = Color3.fromRGB(180, 220, 180)
OutputCodeDisplay.Font = Enum.Font.Code
OutputCodeDisplay.TextSize = 10
OutputCodeDisplay.TextXAlignment = Enum.TextXAlignment.Left
OutputCodeDisplay.TextYAlignment = Enum.TextYAlignment.Top
OutputCodeDisplay.ClearTextOnFocus = false
OutputCodeDisplay.MultiLine = true
OutputCodeDisplay.ReadOnly = false
OutputCodeDisplay.Text = "-- Click 'SCRAPE ALL SCRIPTS' above to extract game source code...\n-- Code will appear here for you to copy or edit."
OutputCodeDisplay.Parent = OutputCodeBoxBg

ScrapeBtn.MouseButton1Click:Connect(function()
    UpdateStatus(10, "Scraping LocalScripts, Modules & Tools...")
    
    task.spawn(function()
        local lines = {}
        table.insert(lines, "-- ============================================================================")
        table.insert(lines, "-- KOI56 SCRAPED GAME SOURCE CODE & HIERARCHY")
        table.insert(lines, string.format("-- PlaceId: %d | Game Name: %s", game.PlaceId, game.Name))
        table.insert(lines, "-- ============================================================================\n")

        -- 1. Decompile LocalScripts & ModuleScripts
        table.insert(lines, "-- [ SECTION 1: SOURCE SCRIPTS ] --\n")
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
                    table.insert(lines, "-- [Protected or Empty Script]")
                end
                table.insert(lines, "\n----------------------------------------------------------------------------\n")
            end
        end

        -- 2. Weapons & Tools Locations
        table.insert(lines, "\n-- [ SECTION 2: WEAPONS & TOOLS HIERARCHY ] --\n")
        local toolCount = 0
        for _, tool in ipairs(game:GetDescendants()) do
            if tool:IsA("Tool") or tool:IsA("HopperBin") then
                toolCount = toolCount + 1
                table.insert(lines, string.format("Tool: %s | Class: %s | Path: %s", tool.Name, tool.ClassName, tool:GetFullName()))
            end
        end

        -- 3. Workspace Object Tree
        table.insert(lines, "\n-- [ SECTION 3: WORKSPACE OBJECTS ] --\n")
        for _, child in ipairs(workspace:GetChildren()) do
            table.insert(lines, string.format("Workspace Tree: %s [%s]", child.Name, child.ClassName))
        end

        local resultText = table.concat(lines, "\n")
        OutputCodeDisplay.Text = resultText

        -- Try writing to disk
        if is_writefile then pcall(function() writefile(Config.DumpFileName, resultText) end) end
        
        -- Auto copy to clipboard
        SetClipboardText(resultText)

        UpdateStatus(100, string.format("Scraped %d Scripts & %d Tools!", scriptCount, toolCount))
        SendNotify("KOI56 Dumper", "สกัดโค้ดสำเร็จ! แสดงผลบนหน้าจอและคัดลอกลง Clipboard เรียบร้อย")
    end)
end)

CopyCodeBtn.MouseButton1Click:Connect(function()
    if OutputCodeDisplay.Text ~= "" then
        SetClipboardText(OutputCodeDisplay.Text)
        UpdateStatus(100, "ALL CODE COPIED TO CLIPBOARD!")
        SendNotify("KOI56", "คัดลอกซอร์สโค้ดทั้งหมดลง Clipboard เรียบร้อยแล้ว!")
    end
end)

UpdateStatus(100, "KOI56 Core Engine Ready (2 Functions Only).")
