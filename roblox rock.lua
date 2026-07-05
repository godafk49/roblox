-- [[ 🍊 ROCK FRUIT EXPLORER GUI ]]
-- แสดงผลใน executor พร้อม UI ไม่ต้องดู console

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = workspace
local Player = Players.LocalPlayer

-- ====== สร้าง GUI ======
local oldGui = Player.PlayerGui:FindFirstChild("RFExplorer")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "RFExplorer"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- ลอง CoreGui ก่อน ถ้าบล็อกใช้ PlayerGui
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = Player.PlayerGui end

-- ====== หน้าต่างหลัก ======
local mf = Instance.new("Frame")
mf.Size = UDim2.new(0, 500, 0, 400)
mf.Position = UDim2.new(0.5, -250, 0.5, -200)
mf.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mf.BorderSizePixel = 0
mf.Active = true
mf.Draggable = true
mf.Parent = sg
Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", mf)
stroke.Color = Color3.fromRGB(100, 100, 255)
stroke.Thickness = 2

-- ====== Title Bar ======
local tb = Instance.new("Frame")
tb.Size = UDim2.new(1, 0, 0, 35)
tb.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
tb.BorderSizePixel = 0
tb.Parent = mf
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

local grad = Instance.new("UIGradient", tb)
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
}

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔍 Rock Fruit Explorer"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = tb

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = tb
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ====== ปุ่มเมนูด้านซ้าย ======
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -45)
sidebar.Position = UDim2.new(0, 5, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
sidebar.BorderSizePixel = 0
sidebar.Parent = mf
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local menuLayout = Instance.new("UIListLayout", sidebar)
menuLayout.Padding = UDim.new(0, 5)
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ====== เนื้อหาด้านขวา (ScrollingFrame) ======
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -145, 1, -50)
content.Position = UDim2.new(0, 140, 0, 45)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = mf

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.Padding = UDim.new(0, 4)

-- ====== ฟังก์ชันเพิ่มข้อความใน content ======
local function addText(text, color, size)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    lbl.Text = "  " .. text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = size or 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = content
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
    -- ปรับขนาดตามข้อความ
    local h = math.ceil(#text / 50) * 18
    lbl.Size = UDim2.new(1, -10, 0, math.max(20, h + 6))
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
    end)
    return lbl
end

local function addHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 28)
    lbl.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
    lbl.Text = "  📌 " .. text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = content
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
    end)
end

-- ====== ฟังก์ชันเคลียร์ content ======
local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end
end

-- ====== สร้างปุ่มเมนู ======
local function makeMenuButton(text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60, 60, 90) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65) end)
    return btn
end

-- ====== ปุ่ม Refresh ======
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(1, -10, 0, 30)
refreshBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
refreshBtn.Text = "🔄 Refresh"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 12
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.LayoutOrder = 99
refreshBtn.Parent = sidebar
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)

-- ====== ฟังก์ชันสำรวจแต่ละส่วน ======

local function scanMobs()
    clearContent()
    addHeader("怪物 MOB LOCATIONS")
    
    local mobCount = 0
    local folders = {}
    local samples = {}
    
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") 
           and obj:FindFirstChild("Humanoid") 
           and obj:FindFirstChild("HumanoidRootPart") 
           and not Players:GetPlayerFromCharacter(obj) then
            mobCount = mobCount + 1
            local parent = obj.Parent
            if parent and parent ~= WS then
                folders[parent.Name] = (folders[parent.Name] or 0) + 1
                -- ดึง path เต็ม
                if #samples < 8 then
                    local path = obj.Name
                    local p = parent
                    local depth = 0
                    while p and p ~= WS and depth < 3 do
                        path = p.Name .. "." .. path
                        p = p.Parent
                        depth = depth + 1
                    end
                    local found = false
                    for _, s in ipairs(samples) do if s == path then found = true break end end
                    if not found then table.insert(samples, path) end
                end
            end
        end
    end
    
    addText("📊 พบ mob ทั้งหมด: " .. mobCount .. " ตัว", Color3.fromRGB(100, 255, 100), 14)
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    
    if next(folders) then
        addText("📂 Folder ที่เก็บ mob:", Color3.fromRGB(200, 200, 255), 13)
        for name, count in pairs(folders) do
            addText("   • workspace." .. name .. " (" .. count .. " ตัว)", Color3.fromRGB(255, 255, 100))
        end
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    if #samples > 0 then
        addText("📍 ตัวอย่างตำแหน่ง:", Color3.fromRGB(200, 200, 255), 13)
        for _, path in ipairs(samples) do
            addText("   • workspace." .. path, Color3.fromRGB(100, 255, 150))
        end
    end
    
    if mobCount == 0 then
        addText("❌ ไม่พบ mob — ลองไปยืนใกล้ mob แล้ว Refresh", Color3.fromRGB(255, 100, 100))
    end
end

local function scanRemotes()
    clearContent()
    addHeader("📡 REMOTE EVENTS")
    
    -- sleitnick_net
    local packages = RS:FindFirstChild("Packages")
    if packages then
        local index = packages:FindFirstChild("_Index")
        if index then
            for _, obj in ipairs(index:GetChildren()) do
                if obj.Name:lower():find("net") then
                    local net = obj:FindFirstChild("net")
                    if net then
                        addText("✅ RS.Packages._Index." .. obj.Name .. ".net/", Color3.fromRGB(100, 255, 100), 13)
                        local foundRemote = false
                        for _, sub in ipairs(net:GetDescendants()) do
                            if sub:IsA("RemoteEvent") or sub:IsA("RemoteFunction") then
                                addText("   • " .. sub:GetFullName():gsub("ReplicatedStorage%.", "RS."), Color3.fromRGB(255, 255, 150))
                                foundRemote = true
                            end
                        end
                        if not foundRemote then
                            for _, sub in ipairs(net:GetChildren()) do
                                addText("   📂 " .. sub.Name .. "/ (" .. sub.ClassName .. ")", Color3.fromRGB(200, 200, 255))
                                for _, deep in ipairs(sub:GetChildren()) do
                                    addText("      • " .. deep.Name .. " (" .. deep.ClassName .. ")", Color3.fromRGB(255, 255, 100))
                                end
                            end
                        end
                    end
                end
            end
        else
            addText("❌ ไม่พบ Packages._Index", Color3.fromRGB(255, 100, 100))
        end
    else
        addText("❌ ไม่พบ Packages folder", Color3.fromRGB(255, 100, 100))
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    addHeader("⚔️ COMBAT REMOTES")
    local combatCount = 0
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("attack", 1, true) or name:find("combat", 1, true)
               or name:find("m1", 1, true) or name:find("action", 1, true)
               or name:find("damage", 1, true) or name:find("hit", 1, true) then
                addText("🎯 " .. obj:GetFullName():gsub("ReplicatedStorage%.", "RS."), Color3.fromRGB(255, 100, 100))
                combatCount = combatCount + 1
            end
        end
    end
    if combatCount == 0 then
        addText("❌ ไม่พบ Combat Remote", Color3.fromRGB(255, 150, 150))
    end
end

local function scanQuests()
    clearContent()
    addHeader("🚶 NPC + PROXIMITY PROMPTS")
    
    local count = 0
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            count = count + 1
            local parent = obj.Parent
            local name = parent and parent.Name or "?"
            local text = obj.ObjectText or obj.ActionText or "?"
            local path = obj:GetFullName():gsub("Workspace%.", "WS."):gsub("Workspace", "WS")
            addText("🎯 " .. name, Color3.fromRGB(100, 200, 255), 13)
            addText("   📍 " .. path, Color3.fromRGB(200, 200, 200), 11)
            addText("   📝 Text: " .. text, Color3.fromRGB(255, 255, 150), 11)
            addText(" ", Color3.fromRGB(255, 255, 255), 6)
        end
    end
    addText("📊 พบ ProximityPrompt ทั้งหมด: " .. count .. " ตัว", Color3.fromRGB(100, 255, 100), 14)
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    addHeader("📋 QUEST REMOTES")
    local qCount = 0
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("quest", 1, true) or name:find("mission", 1, true)
               or name:find("task", 1, true) then
                addText("🎯 " .. obj:GetFullName():gsub("ReplicatedStorage%.", "RS."), Color3.fromRGB(100, 200, 255))
                qCount = qCount + 1
            end
        end
    end
    if qCount == 0 then addText("❌ ไม่พบ Quest Remote", Color3.fromRGB(255, 150, 150)) end
end

local function scanStats()
    clearContent()
    addHeader("📊 STATS + LEVEL")
    
    local char = Player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            addText("🏃 WalkSpeed: " .. hum.WalkSpeed, Color3.fromRGB(100, 255, 100), 13)
            addText("🩸 Health: " .. hum.Health .. "/" .. hum.MaxHealth, Color3.fromRGB(255, 100, 100), 13)
            addText("⬆️ JumpPower: " .. hum.JumpPower, Color3.fromRGB(100, 200, 255), 13)
        end
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    
    -- หา Stat folders
    for _, loc in ipairs({{char, "Character"}, {Player, "Player"}}) do
        local obj, label = loc[1], loc[2]
        if obj then
            for _, name in ipairs({"Stats", "Attributes", "Data", "PlayerData", "leaderstats"}) do
                local stats = obj:FindFirstChild(name)
                if stats then
                    addText("📂 " .. label .. "." .. name .. "/:", Color3.fromRGB(200, 200, 255), 13)
                    for _, stat in ipairs(stats:GetChildren()) do
                        addText("   • " .. stat.Name .. " = " .. tostring(stat.Value) .. " (" .. stat.ClassName .. ")", Color3.fromRGB(255, 255, 100))
                    end
                end
            end
        end
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    addHeader("📡 STAT REMOTES")
    local sCount = 0
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("stat", 1, true) or name:find("point", 1, true)
               or name:find("allocate", 1, true) or name:find("upgrade", 1, true) then
                addText("🎯 " .. obj:GetFullName():gsub("ReplicatedStorage%.", "RS."), Color3.fromRGB(255, 200, 100))
                sCount = sCount + 1
            end
        end
    end
    if sCount == 0 then addText("❌ ไม่พบ Stat Remote", Color3.fromRGB(255, 150, 150)) end
end

local function scanTools()
    clearContent()
    addHeader("🗡️ WEAPONS + TOOLS")
    
    local char = Player.Character
    local backpack = Player:FindFirstChild("Backpack")
    
    if char then
        addText("✋ อาวุธที่ถืออยู่:", Color3.fromRGB(200, 200, 255), 13)
        local holdCount = 0
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                addText("   🗡️ " .. tool.Name, Color3.fromRGB(255, 255, 100))
                holdCount = holdCount + 1
            end
        end
        if holdCount == 0 then addText("   (ไม่มี)", Color3.fromRGB(150, 150, 150)) end
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    
    if backpack then
        addText("🎒 อาวุธใน Backpack:", Color3.fromRGB(200, 200, 255), 13)
        local bpCount = 0
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                addText("   🗡️ " .. tool.Name, Color3.fromRGB(100, 255, 100))
                bpCount = bpCount + 1
            end
        end
        if bpCount == 0 then addText("   (ว่าง)", Color3.fromRGB(150, 150, 150)) end
    end
    
    addText(" ", Color3.fromRGB(255, 255, 255), 8)
    addHeader("📦 ALL TOOLS IN GAME")
    local gameTools = {}
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("Tool") then
            table.insert(gameTools, obj.Name)
        end
    end
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Tool") then
            table.insert(gameTools, obj.Name)
        end
    end
    if #gameTools > 0 then
        for _, name in ipairs(gameTools) do
            addText("   • " .. name, Color3.fromRGB(255, 200, 200))
        end
    else
        addText("❌ ไม่พบ Tool ในเกม", Color3.fromRGB(255, 150, 150))
    end
end

-- ====== เชื่อมปุ่มเมนู ======
local currentScan = scanMobs

local btnMobs = makeMenuButton("怪物 Mobs", 1)
local btnRemotes = makeMenuButton("📡 Remotes", 2)
local btnQuests = makeMenuButton("🚶 Quests/NPC", 3)
local btnStats = makeMenuButton("📊 Stats", 4)
local btnTools = makeMenuButton("🗡️ Tools", 5)

btnMobs.MouseButton1Click:Connect(function() currentScan = scanMobs scanMobs() end)
btnRemotes.MouseButton1Click:Connect(function() currentScan = scanRemotes scanRemotes() end)
btnQuests.MouseButton1Click:Connect(function() currentScan = scanQuests scanQuests() end)
btnStats.MouseButton1Click:Connect(function() currentScan = scanStats scanStats() end)
btnTools.MouseButton1Click:Connect(function() currentScan = scanTools scanTools() end)

refreshBtn.MouseButton1Click:Connect(function()
    if currentScan then currentScan() end
end)

-- ====== เริ่มต้น: แสดง Mob ก่อน ======
scanMobs()

print("✅ Rock Fruit Explorer Loaded! ดูผลใน GUI")
