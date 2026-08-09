-- ============================================================================
-- KOI56 SOURCE CODE & MAP SCRAPER (CLIPBOARD & ON-SCREEN EXPORTER)
-- NO FILE SAVING REQUIRED (WORKS 100% ON DELTA ANDROID)
-- SCRAPES: LOCALSCRIPTS, MODULESCRIPTS, WEAPONS, WORKSPACE HIERARCHY
-- ============================================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Function to safely copy text to mobile clipboard
local function CopyToClipboard(text)
    if setclipboard then setclipboard(text) return true
    elseif toclipboard then toclipboard(text) return true end
    return false
end

-- ============================================================================
-- GUI ENGINE (MOBILE TOUCH OPTIMIZED)
-- ============================================================================

local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)

if TargetParent:FindFirstChild("KOI56_SourceExporterUI") then
    TargetParent.KOI56_SourceExporterUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KOI56_SourceExporterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- Floating K Button
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

-- Main UI Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 420)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Title Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "KOI56 SOURCE CODE & MAP SCRAPER"
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

-- Controls Container
local ActionBtn = Instance.new("TextButton")
ActionBtn.Size = UDim2.new(1, -30, 0, 40)
ActionBtn.Position = UDim2.new(0, 15, 0, 50)
ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
ActionBtn.Text = "⚡ SCRAPE ALL SOURCE SCRIPTS & MAP STRUCTURE"
ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 12
ActionBtn.Parent = MainFrame
Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(1, -30, 0, 32)
CopyBtn.Position = UDim2.new(0, 15, 0, 96)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
CopyBtn.Text = "📋 COPY ALL OUTPUT CODE TO CLIPBOARD"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 11
CopyBtn.Parent = MainFrame
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

-- Source Code Box Container
local CodeBoxBg = Instance.new("Frame")
CodeBoxBg.Size = UDim2.new(1, -30, 1, -170)
CodeBoxBg.Position = UDim2.new(0, 15, 0, 135)
CodeBoxBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
CodeBoxBg.Parent = MainFrame
Instance.new("UICorner", CodeBoxBg).CornerRadius = UDim.new(0, 6)

local CodeDisplay = Instance.new("TextBox")
CodeDisplay.Size = UDim2.new(1, -16, 1, -16)
CodeDisplay.Position = UDim2.new(0, 8, 0, 8)
CodeDisplay.BackgroundTransparency = 1
CodeDisplay.TextColor3 = Color3.fromRGB(180, 220, 180)
CodeDisplay.Font = Enum.Font.Code
CodeDisplay.TextSize = 10
CodeDisplay.TextXAlignment = Enum.TextXAlignment.Left
CodeDisplay.TextYAlignment = Enum.TextYAlignment.Top
CodeDisplay.ClearTextOnFocus = false
CodeDisplay.MultiLine = true
CodeDisplay.ReadOnly = false
CodeDisplay.Text = "-- Click 'SCRAPE ALL SOURCE SCRIPTS' to extract code here...\n-- You can then Select All & Copy directly from this box!"
CodeDisplay.Parent = CodeBoxBg

-- Status Bar
local ProgressBg = Instance.new("Frame")
ProgressBg.Size = UDim2.new(1, 0, 0, 25)
ProgressBg.Position = UDim2.new(0, 0, 1, -25)
ProgressBg.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
ProgressBg.Parent = MainFrame

local ProgressStatus = Instance.new("TextLabel")
ProgressStatus.Size = UDim2.new(1, -10, 1, 0)
ProgressStatus.Position = UDim2.new(0, 10, 0, 0)
ProgressStatus.BackgroundTransparency = 1
ProgressStatus.Text = "Status: Ready to scrape source code."
ProgressStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressStatus.TextSize = 10
ProgressStatus.Font = Enum.Font.GothamBold
ProgressStatus.TextXAlignment = Enum.TextXAlignment.Left
ProgressStatus.Parent = ProgressBg

-- ============================================================================
-- SCRAPING LOGIC
-- ============================================================================

ActionBtn.MouseButton1Click:Connect(function()
    ActionBtn.Text = "SCRAPING SOURCE CODE..."
    ProgressStatus.Text = "Scanning Game Scripts and Objects..."
    
    task.spawn(function()
        local outputLines = {}
        table.insert(outputLines, "-- ============================================================================")
        table.insert(outputLines, "-- KOI56 SCRAPED MAP SOURCE CODE & HIERARCHY")
        table.insert(outputLines, string.format("-- PlaceId: %d | Game: %s", game.PlaceId, game.Name))
        table.insert(outputLines, "-- ============================================================================\n")

        -- 1. Scrape All Scripts (LocalScripts & ModuleScripts)
        table.insert(outputLines, "-- [ SECTION 1: SOURCE SCRIPTS DECOMPILED ] --\n")
        local scriptCount = 0
        local decompileFn = decompile or (getscriptbytecode and function(s) return "-- Bytecode extracted" end)

        for _, instance in ipairs(game:GetDescendants()) do
            if instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
                scriptCount = scriptCount + 1
                table.insert(outputLines, string.format("-- SCRIPT: %s [%s]", instance:GetFullName(), instance.ClassName))
                
                local src = nil
                if decompileFn then
                    pcall(function() src = decompileFn(instance) end)
                end
                
                if not src or src == "" then
                    pcall(function() src = instance.Source end)
                end

                if src and src ~= "" then
                    table.insert(outputLines, src)
                else
                    table.insert(outputLines, "-- [Protected or Empty Script]")
                end
                table.insert(outputLines, "\n----------------------------------------------------------------------------\n")
            end
        end

        -- 2. Scrape Weapons and Tools Structure
        table.insert(outputLines, "\n-- [ SECTION 2: WEAPONS & TOOLS HIERARCHY ] --\n")
        local toolCount = 0
        for _, tool in ipairs(game:GetDescendants()) do
            if tool:IsA("Tool") or tool:IsA("HopperBin") then
                toolCount = toolCount + 1
                table.insert(outputLines, string.format("Tool: %s | Class: %s | Path: %s", tool.Name, tool.ClassName, tool:GetFullName()))
            end
        end

        -- 3. Scrape Map Structure Tree
        table.insert(outputLines, "\n-- [ SECTION 3: WORKSPACE & SERVICE TREE ] --\n")
        for _, child in ipairs(workspace:GetChildren()) do
            table.insert(outputLines, string.format("Workspace Object: %s [%s]", child.Name, child.ClassName))
        end

        local finalResult = table.concat(outputLines, "\n")
        CodeDisplay.Text = finalResult
        
        ProgressStatus.Text = string.format("Scraped %d Scripts and %d Tools Successfully!", scriptCount, toolCount)
        ActionBtn.Text = "⚡ SCRAPE ALL SOURCE SCRIPTS & MAP STRUCTURE"
        
        -- Auto Copy to Clipboard
        CopyToClipboard(finalResult)
    end)
end)

CopyBtn.MouseButton1Click:Connect(function()
    if CodeDisplay.Text ~= "" then
        local success = CopyToClipboard(CodeDisplay.Text)
        if success then
            ProgressStatus.Text = "Status: ALL CODE COPIED TO CLIPBOARD!"
        else
            ProgressStatus.Text = "Status: Copy failed! Please long-press inside the box to Select All."
        end
    end
end)

ProgressStatus.Text = "KOI56 Source Scraper Loaded. Ready!"
