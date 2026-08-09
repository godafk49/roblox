-- ============================================================================
-- SCRIPT NAME: โคย 5 6 (KOY 5 6)
-- FEATURE: AUTO FOLDER CREATION & AUTOMATIC MAP / SCRIPT DUMPER
-- NO KEY SYSTEM | SUPPORT MOBILE EXECUTORS (DELTA / HYDROGEN)
-- ============================================================================

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGuiService = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

-- 📁 กำหนดชื่อโฟลเดอร์หลัก และชื่อไฟล์
local TARGET_FOLDER = "โคย 5 6"
local DEFAULT_FILE_NAME = "โคย 5 6.txt"

-- ฟังก์ชันแจ้งเตือนในเกม
local function SendNotify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
end

-- ฟังก์ชันตรวจสอบและสร้างโฟลเดอร์ "โคย 5 6" อัตโนมัติ
local function EnsureDirectoryExists()
    if makefolder then
        pcall(function()
            if isfolder and not isfolder(TARGET_FOLDER) then
                makefolder(TARGET_FOLDER)
            elseif not isfolder then
                makefolder(TARGET_FOLDER)
            end
        end)
    end
end

-- สร้างโฟลเดอร์เตรียมไว้ทันทีที่รันสคริปต์
EnsureDirectoryExists()

-- เคลียร์ GUI เก่าถ้ามี
local TargetParent = gethui and gethui() or (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui) or CoreGui)
if TargetParent:FindFirstChild("Koy56_Hub") then
    TargetParent.Koy56_Hub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Koy56_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetParent

-- 🔘 ปุ่มลอยสีส้ม/ทอง สำหรับมือถือ (Floating Action Button)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 60, 0, 60)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
ToggleBtn.Text = "โคย 5 6"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- 🖼️ หน้าต่างหลัก (Main Window)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- แถบหัวข้อด้านบน
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "สคริปต์ โคย 5 6  |  MAP DUMPER & SCRIPT EXTRACTOR"
TitleLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- แถบเมนูด้านข้าง
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Sidebar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = Sidebar

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -150, 1, -50)
PageContainer.Position = UDim2.new(0, 145, 0, 45)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

local Pages = {}
local function AddTab(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 35)
    Btn.Position = UDim2.new(0, 5, 0, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 11
    Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = PageContainer

    Btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do
            p.Page.Visible = false
            p.Btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            p.Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        Page.Visible = true
        Btn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    table.insert(Pages, {Btn = Btn, Page = Page})
    if #Pages == 1 then
        Page.Visible = true
        Btn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    return Page
end

local DumpPage = AddTab("📁 Dump & Extract")
local SpyPage = AddTab("🕵️ Remote Logger")

-- ============================================================================
-- TAB 1: FULL DUMP & SCRIPT COLLECTOR (บันทึกเข้าโฟลเดอร์ "โคย 5 6")
-- ============================================================================
local FileLabel = Instance.new("TextLabel")
FileLabel.Size = UDim2.new(1, 0, 0, 18)
FileLabel.BackgroundTransparency = 1
FileLabel.Text = "บันทึกไปที่โฟลเดอร์: workspace/โคย 5 6/"
FileLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
FileLabel.Font = Enum.Font.GothamMedium
FileLabel.TextSize = 10
FileLabel.TextXAlignment = Enum.TextXAlignment.Left
FileLabel.Parent = DumpPage

local FileNameBoxBg = Instance.new("Frame")
FileNameBoxBg.Size = UDim2.new(1, 0, 0, 32)
FileNameBoxBg.Position = UDim2.new(0, 0, 0, 20)
FileNameBoxBg.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
FileNameBoxBg.Parent = DumpPage
Instance.new("UICorner", FileNameBoxBg).CornerRadius = UDim.new(0, 6)

local FileNameBox = Instance.new("TextBox")
FileNameBox.Size = UDim2.new(1, -20, 1, 0)
FileNameBox.Position = UDim2.new(0, 10, 0, 0)
FileNameBox.BackgroundTransparency = 1
FileNameBox.Text = DEFAULT_FILE_NAME
FileNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FileNameBox.Font = Enum.Font.Code
FileNameBox.TextSize = 11
FileNameBox.TextXAlignment = Enum.TextXAlignment.Left
FileNameBox.Parent = FileNameBoxBg

local DumpBtn = Instance.new("TextButton")
DumpBtn.Size = UDim2.new(1, 0, 0, 38)
DumpBtn.Position = UDim2.new(0, 0, 0, 58)
DumpBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
DumpBtn.Text = "⚡ เริ่มดัมพ์ไฟล์แมพและโค้ดทั้งหมด (Save to โคย 5 6)"
DumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpBtn.Font = Enum.Font.GothamBold
DumpBtn.TextSize = 11
DumpBtn.Parent = DumpPage
Instance.new("UICorner", DumpBtn).CornerRadius = UDim.new(0, 6)

local DisplayBox = Instance.new("TextBox")
DisplayBox.Size = UDim2.new(1, 0, 1, -108)
DisplayBox.Position = UDim2.new(0, 0, 0, 102)
DisplayBox.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
DisplayBox.TextColor3 = Color3.fromRGB(150, 220, 150)
DisplayBox.Font = Enum.Font.Code
DisplayBox.TextSize = 10
DisplayBox.TextXAlignment = Enum.TextXAlignment.Left
DisplayBox.TextYAlignment = Enum.TextYAlignment.Top
DisplayBox.MultiLine = true
DisplayBox.ReadOnly = false
DisplayBox.Text = "-- กดปุ่มด้านบน เพื่อเริ่มดัมพ์โครงสร้างแมพและโค้ดทั้งหมด\n-- ระบบจะสร้างโฟลเดอร์ 'โคย 5 6' และเซฟไฟล์ให้โดยอัตโนมัติ!"
DisplayBox.Parent = DumpPage
Instance.new("UICorner", DisplayBox).CornerRadius = UDim.new(0, 6)

DumpBtn.MouseButton1Click:Connect(function()
    DumpBtn.Text = "⏳ กำลังดัมพ์ข้อมูลและสแกนโค้ดทั้งแมพ..."
    task.spawn(function()
        EnsureDirectoryExists()
        
        local userFileName = FileNameBox.Text ~= "" and FileNameBox.Text or DEFAULT_FILE_NAME
        local fullPath = TARGET_FOLDER .. "/" .. userFileName
        
        local output = {}
        table.insert(output, "-- ==========================================================")
        table.insert(output, "-- สคริปต์ โคย 5 6 | FULL MAP & CODE DUMP")
        table.insert(output, "-- PLACE ID: " .. tostring(game.PlaceId))
        table.insert(output, "-- DATE: " .. os.date("%Y-%m-%d %H:%M:%S"))
        table.insert(output, "-- ==========================================================\n")

        local targets = {ReplicatedStorage, Workspace, StarterGuiService, Lighting}
        local decompileFn = decompile or (getscriptbytecode and function(s) return "-- [Bytecode Found]" end)

        for _, svc in ipairs(targets) do
            table.insert(output, "== SERVICE: " .. svc.Name .. " ==")
            for _, obj in ipairs(svc:GetDescendants()) do
                local line = string.format("[%s] %s -> %s", obj.ClassName, obj.Name, obj:GetFullName())
                table.insert(output, line)

                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local src = nil
                    if decompileFn then pcall(function() src = decompileFn(obj) end) end
                    if not src or src == "" then pcall(function() src = obj.Source end) end
                    if src and src ~= "" then
                        table.insert(output, "   -- [SCRIPT SOURCE CODE: " .. obj.Name .. "]\n" .. src .. "\n")
                    end
                end
            end
            task.wait()
        end

        local finalDump = table.concat(output, "\n")
        DisplayBox.Text = finalDump

        -- บันทึกลงไฟล์ในโฟลเดอร์ "โคย 5 6"
        if writefile then
            pcall(function() writefile(fullPath, finalDump) end)
            SendNotify("โคย 5 6", "เซฟไฟล์สำเร็จ! ไปที่ workspace/โคย 5 6/" .. userFileName)
        end
        if setclipboard then
            setclipboard(finalDump)
        end

        DumpBtn.Text = "⚡ เริ่มดัมพ์ไฟล์แมพและโค้ดทั้งหมด (Save to โคย 5 6)"
    end)
end)

-- ============================================================================
-- TAB 2: REMOTE SPY LOGGER (เซฟ Logs ลงโฟลเดอร์ "โคย 5 6")
-- ============================================================================
local SpyToggleBtn = Instance.new("TextButton")
SpyToggleBtn.Size = UDim2.new(1, 0, 0, 35)
SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
SpyToggleBtn.Text = "🔴 อัดสัญญาณ REMOTE: OFF"
SpyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpyToggleBtn.Font = Enum.Font.GothamBold
SpyToggleBtn.TextSize = 11
SpyToggleBtn.Parent = SpyPage
Instance.new("UICorner", SpyToggleBtn).CornerRadius = UDim.new(0, 6)

local SaveSpyBtn = Instance.new("TextButton")
SaveSpyBtn.Size = UDim2.new(1, 0, 0, 28)
SaveSpyBtn.Position = UDim2.new(0, 0, 0, 40)
SaveSpyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
SaveSpyBtn.Text = "💾 เซฟ REMOTE LOGS ลงโฟลเดอร์ โคย 5 6"
SaveSpyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSpyBtn.Font = Enum.Font.GothamBold
SaveSpyBtn.TextSize = 10
SaveSpyBtn.Parent = SpyPage
Instance.new("UICorner", SaveSpyBtn).CornerRadius = UDim.new(0, 6)

local SpyDisplay = Instance.new("TextBox")
SpyDisplay.Size = UDim2.new(1, 0, 1, -78)
SpyDisplay.Position = UDim2.new(0, 0, 0, 75)
SpyDisplay.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
SpyDisplay.TextColor3 = Color3.fromRGB(255, 215, 100)
SpyDisplay.Font = Enum.Font.Code
SpyDisplay.TextSize = 10
SpyDisplay.TextXAlignment = Enum.TextXAlignment.Left
SpyDisplay.TextYAlignment = Enum.TextYAlignment.Top
SpyDisplay.MultiLine = true
SpyDisplay.ReadOnly = false
SpyDisplay.Text = "-- เปิดปุ่ม RECORD REMOTES แล้วไปกดเล่นกิจกรรมในเกม\n-- สัญญาณ Remote จะถูกดักจับและแสดงที่นี่เรียบร้อย!"
SpyDisplay.Parent = SpyPage
Instance.new("UICorner", SpyDisplay).CornerRadius = UDim.new(0, 6)

local isSpying = false
local spyLogs = {}

local rawNamecall = getrawmetatable and getrawmetatable(game) and getrawmetatable(game).__namecall
if rawNamecall and setreadonly then
    setreadonly(getrawmetatable(game), false)
    getrawmetatable(game).__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if isSpying and (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            local formatted = {}
            for _, v in ipairs(args) do
                if type(v) == "string" then table.insert(formatted, string.format('"%s"', tostring(v)))
                else table.insert(formatted, tostring(v)) end
            end
            local codeLine = string.format('game:GetService("%s").%s:%s(%s)', 
                self.Parent and self.Parent.Name or "ReplicatedStorage", 
                self.Name, method, table.concat(formatted, ", "))
            
            table.insert(spyLogs, 1, codeLine)
            if #spyLogs > 40 then table.remove(spyLogs) end
            SpyDisplay.Text = table.concat(spyLogs, "\n")
        end
        return rawNamecall(self, ...)
    end)
    setreadonly(getrawmetatable(game), true)
end

SpyToggleBtn.MouseButton1Click:Connect(function()
    isSpying = not isSpying
    if isSpying then
        SpyToggleBtn.Text = "🟢 อัดสัญญาณ REMOTE: ACTIVE (กำลังบันทึก...)"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
        SendNotify("โคย 5 6", "เริ่มอัดสัญญาณ Remote แล้ว!")
    else
        SpyToggleBtn.Text = "🔴 อัดสัญญาณ REMOTE: OFF"
        SpyToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
end)

SaveSpyBtn.MouseButton1Click:Connect(function()
    EnsureDirectoryExists()
    local text = SpyDisplay.Text
    local spyFilePath = TARGET_FOLDER .. "/RemoteLogs_โคย 5 6.txt"
    if writefile then writefile(spyFilePath, text) end
    if setclipboard then setclipboard(text) end
    SendNotify("โคย 5 6", "เซฟ Logs เรียบร้อยไปที่ workspace/" .. spyFilePath)
end)

SendNotify("โคย 5 6", "โหลดสคริปต์เรียบร้อย! โฟลเดอร์ โคย 5 6 ถูกสร้างแล้ว")
