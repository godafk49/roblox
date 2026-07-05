-- [[ 🍊 ROCK FARM HUB — Auto Farm สำหรับ Rock Fruit ]]
-- เขียนโดย ZCode | เวอร์ชัน 1.0
-- รวม 12 ฝ่าย, 48 ฟังก์ชัน, พร้อม fallback ทุกจุด

-- ============================================================
-- ฝ่ายที่ 1: CORE SYSTEM (ตัวแปรหลัก + พื้นฐาน)
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Backpack = Player:WaitForChild("Backpack")

-- Config (เก็บใน _G ให้ UI เข้าถึงได้)
local G = _G
G.AutoFarm    = false
G.AutoClick   = false
G.AutoSkill   = false
G.AutoEquip   = false
G.AutoQuest   = false
G.AutoStats   = false
G.SpeedBoost  = false

G.Distance      = 5
G.PositionMode  = "Back"
G.MaxRange      = 500
G.MobFilter     = ""
G.SkillDelay    = 1.0
G.SpeedValue    = 50
G.Melee         = 0
G.Sword         = 0
G.DevilFruit    = 0
G.Defense       = 0

-- Skills (เหลือ Z, X, C, V, F)
local Skills = {Z = false, X = false, C = false, V = false, F = false}
local LastSkillUse = {}

-- Cache + สถานะ
local MobsCache = {}
local LastRefresh = 0
local ActionRemote = nil
local StatRemote = nil
local KillCount = 0
local KilledTargets = {}
local Enabled = true
local StatusText = nil
local ScreenGui = nil

-- ============================================================
-- ฝ่ายที่ 14: SafeCall (pcall wrapper)
-- ============================================================

local function SafeCall(func)
    local success, err = pcall(func)
    if not success then
        warn("[RockFarm] " .. tostring(err))
    end
    return success
end

-- ============================================================
-- ฝ่ายที่ 15: GetGuiParent (CoreGui/PlayerGui Fallback)
-- ============================================================

local function GetGuiParent()
    local cg = game:GetService("CoreGui")
    local success = pcall(function()
        local test = Instance.new("ScreenGui")
        test.Parent = cg
        test:Destroy()
    end)
    if success then
        return cg
    else
        return Player:WaitForChild("PlayerGui")
    end
end

-- ============================================================
-- ฝ่ายที่ 13: Notification
-- ============================================================

local function Notify(text)
    SafeCall(function()
        if not ScreenGui then return end
        local n = Instance.new("TextLabel")
        n.Size = UDim2.new(0, 200, 0, 30)
        n.Position = UDim2.new(1, -210, 0, 50)
        n.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        n.TextColor3 = Color3.fromRGB(255, 255, 255)
        n.Text = "  " .. text
        n.Font = Enum.Font.GothamBold
        n.TextSize = 12
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Parent = ScreenGui
        Instance.new("UICorner", n).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", n)
        stroke.Color = Color3.fromRGB(100, 100, 255)
        stroke.Thickness = 1
        Debris:AddItem(n, 2)
    end)
end

-- ============================================================
-- ฝ่ายที่ 18: UpdateStatus
-- ============================================================

local function UpdateStatus(text)
    SafeCall(function()
        if StatusText then
            StatusText.Text = text or "Ready"
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 2: MOB DETECTION (ค้นหา Mob)
-- ============================================================

local function GetDist(p1, p2)
    return (p1 - p2).Magnitude
end

local function IsValidTarget(mob)
    if not mob or not mob.Parent then return false end
    local h = mob:FindFirstChild("Humanoid")
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return false end
    if h.Health <= 0 then return false end
    if mob == Character then return false end
    if Players:GetPlayerFromCharacter(mob) then return false end
    return true
end

local function FindMobs()
    local mobs = {}
    -- Fallback: ลอง folder หลายชื่อ + workspace ทั้งหมด
    local roots = {
        workspace:FindFirstChild("Mobs"),
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Mob"),
        workspace:FindFirstChild("Map"),
        workspace
    }
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("Model") and IsValidTarget(obj) then
                    local nameMatch = false
                    if G.MobFilter == "" then
                        nameMatch = true
                    elseif obj.Name and string.find(string.lower(obj.Name), string.lower(G.MobFilter), 1, true) then
                        nameMatch = true
                    end
                    if nameMatch then
                        -- ตรวจซ้ำ
                        local exists = false
                        for _, m in ipairs(mobs) do
                            if m == obj then exists = true break end
                        end
                        if not exists then
                            table.insert(mobs, obj)
                        end
                    end
                end
            end
        end
    end
    -- เรียงตามระยะใกล้สุดก่อน
    SafeCall(function()
        table.sort(mobs, function(a, b)
            return GetDist(HRP.Position, a.HumanoidRootPart.Position)
                < GetDist(HRP.Position, b.HumanoidRootPart.Position)
        end)
    end)
    return mobs
end

local function GetNearest()
    local now = tick()
    if now - LastRefresh >= 3 then
        MobsCache = FindMobs()
        LastRefresh = now
    end
    for _, mob in ipairs(MobsCache) do
        if IsValidTarget(mob) then
            local thrp = mob:FindFirstChild("HumanoidRootPart")
            if thrp and HRP then
                local dist = GetDist(HRP.Position, thrp.Position)
                if dist <= G.MaxRange then
                    return mob
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- ฝ่ายที่ 3: MOVEMENT (เคลื่อนที่ + Speed)
-- ============================================================

local function GetOffset(cf, mode, dist)
    if mode == "Back"   then return cf * CFrame.new(0, 0, dist) end
    if mode == "Front"  then return cf * CFrame.new(0, 0, -dist) end
    if mode == "Top"    then return cf * CFrame.new(0, dist, 0) end
    if mode == "Bottom" then return cf * CFrame.new(0, -dist, 0) end
    return cf * CFrame.new(0, 0, dist)
end

local function Teleport(target)
    SafeCall(function()
        local thrp = target:FindFirstChild("HumanoidRootPart")
        if thrp and HRP then
            HRP.CFrame = GetOffset(thrp.CFrame, G.PositionMode, G.Distance)
        end
    end)
end

local function ApplySpeed()
    SafeCall(function()
        if G.SpeedBoost and Humanoid then
            Humanoid.WalkSpeed = G.SpeedValue
        end
    end)
end

local function ResetSpeed()
    SafeCall(function()
        if Humanoid then
            Humanoid.WalkSpeed = 16
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 4: COMBAT (Remote + Fallback)
-- ============================================================

local function FindActionRemote()
    local remote = nil
    pcall(function()
        -- วิธี 1: sleitnick_net path
        local rs = ReplicatedStorage
        local packages = rs:FindFirstChild("Packages")
        if packages then
            local index = packages:FindFirstChild("_Index")
            if index then
                for _, obj in ipairs(index:GetChildren()) do
                    if obj.Name:lower():find("net") then
                        local netModule = obj:FindFirstChild("net")
                        if netModule then
                            local r = netModule:FindFirstChild("RE/ActionRemote")
                            if r then remote = r break end
                        end
                    end
                end
            end
        end
    end)
    -- Fallback: ค้นหา Remote ที่ชื่อเกี่ยวกับ combat
    if not remote then
        pcall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    local name = obj.Name:lower()
                    if name:find("action", 1, true) or name:find("attack", 1, true)
                       or name:find("combat", 1, true) or name:find("m1", 1, true) then
                        remote = obj
                        break
                    end
                end
            end
        end)
    end
    return remote
end

local function AttackFallback()
    SafeCall(function()
        if ActionRemote then
            ActionRemote:FireServer("M1", "Combat")
        else
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 5: WEAPON (Auto Equip)
-- ============================================================

local function AutoEquip()
    SafeCall(function()
        -- ตรวจว่าถืออยู่แล้ว
        local hasTool = false
        for _, v in pairs(Character:GetChildren()) do
            if v:IsA("Tool") then hasTool = true break end
        end
        -- ถ้ายังไม่ถือ → หยิบจาก Backpack
        if not hasTool then
            for _, tool in ipairs(Backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    Humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 6: SKILL (สกิล Z/X/C/V/F)
-- ============================================================

local function PressSkill(key)
    SafeCall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function AutoSkillLoop()
    local now = tick()
    for key, enabled in pairs(Skills) do
        if enabled then
            local last = LastSkillUse[key] or 0
            if now - last >= G.SkillDelay then
                PressSkill(key)
                LastSkillUse[key] = now
            end
        end
    end
end

-- ============================================================
-- ฝ่ายที่ 7: AUTO QUEST (รับเควส)
-- ============================================================

local function FindQuestNPC()
    local foundNpc = nil
    local foundPrompt = nil
    SafeCall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local parent = obj.Parent
                if parent and parent.Name then
                    local lname = parent.Name:lower()
                    if lname:find("quest", 1, true) or lname:find("npc", 1, true)
                       or lname:find("mission", 1, true) then
                        local hrp = parent:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            foundNpc = parent
                            foundPrompt = obj
                            break
                        end
                    end
                end
            end
        end
    end)
    return foundNpc, foundPrompt
end

local function TriggerQuest(npc, prompt)
    SafeCall(function()
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hrp and HRP then
            HRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        end
        task.wait(0.5)
        prompt.HoldDuration = 0
        fireproximityprompt(prompt, 0)
    end)
end

local function AutoQuestLoop()
    task.spawn(function()
        while Enabled do
            if G.AutoQuest then
                local npc, prompt = FindQuestNPC()
                if npc and prompt then
                    TriggerQuest(npc, prompt)
                    task.wait(1)
                end
            end
            task.wait(5)
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 8: AUTO STATS (จัดสรร Stat)
-- ============================================================

local function FindStatRemote()
    local remote = nil
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local name = obj.Name:lower()
                if name:find("stat", 1, true) or name:find("addpoint", 1, true)
                   or name:find("allocate", 1, true) or name:find("upgrade", 1, true) then
                    remote = obj
                    break
                end
            end
        end
    end)
    return remote
end

local function AllocateStats()
    SafeCall(function()
        local stats = {
            {"Melee", G.Melee},
            {"Sword", G.Sword},
            {"DevilFruit", G.DevilFruit},
            {"Defense", G.Defense}
        }
        for _, s in ipairs(stats) do
            local statName = s[1]
            local statValue = s[2]
            if statValue and statValue > 0 then
                if StatRemote then
                    StatRemote:FireServer(statName, statValue)
                end
            end
        end
    end)
end

local function AutoStatsLoop()
    task.spawn(function()
        while Enabled do
            if G.AutoStats then
                AllocateStats()
            end
            task.wait(2)
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 9: BACKGROUND (Anti-AFK, Reload, Kill Count)
-- ============================================================

local function AntiAFKLoop()
    task.spawn(function()
        while Enabled do
            SafeCall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            task.wait(60)
        end
    end)
end

local function OnCharacterAdded(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    Backpack = Player:WaitForChild("Backpack")
    if G.SpeedBoost then ApplySpeed() end
    Notify("Character Reloaded!")
end

Player.CharacterAdded:Connect(OnCharacterAdded)

local function TrackKill(target)
    if not target then return end
    local h = target:FindFirstChild("Humanoid")
    if h and h.Health > 0 then
        KilledTargets[target] = true
    end
end

local function CheckKills()
    for target, _ in pairs(KilledTargets) do
        local h = target:FindFirstChild("Humanoid")
        if h and h.Health <= 0 then
            KillCount = KillCount + 1
            KilledTargets[target] = nil
        elseif not target.Parent then
            KilledTargets[target] = nil
        end
    end
end

-- ============================================================
-- ฝ่ายที่ 16-17: MAIN LOOP (Auto Farm + Cache Refresh)
-- ============================================================

local function StartCacheRefresh()
    task.spawn(function()
        while Enabled do
            SafeCall(function()
                MobsCache = FindMobs()
                LastRefresh = tick()
            end)
            task.wait(3)
        end
    end)
end

local function StartFarm()
    task.spawn(function()
        while Enabled do
            if G.AutoFarm then
                local target = GetNearest()
                if target then
                    UpdateStatus("Target: " .. target.Name .. " | Kills: " .. KillCount)
                    TrackKill(target)
                    if G.AutoEquip then AutoEquip() end
                    Teleport(target)
                    if G.AutoClick then AttackFallback() end
                    if G.AutoSkill then AutoSkillLoop() end
                else
                    UpdateStatus("No target | Kills: " .. KillCount)
                end
            end
            CheckKills()
            task.wait(0.2)
        end
    end)
end

-- ============================================================
-- ฝ่ายที่ 10: UI / GUI
-- ============================================================

local function CreateToggle(parent, text, varName, color)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 45, 0, 20)
    b.Position = UDim2.new(1, -52, 0.5, -10)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

    b.BackgroundColor3 = G[varName] and color or Color3.fromRGB(100, 100, 100)
    b.Text = G[varName] and "ON" or "OFF"

    b.MouseEnter:Connect(function()
        if not G[varName] then b.BackgroundColor3 = Color3.fromRGB(120, 120, 120) end
    end)
    b.MouseLeave:Connect(function()
        b.BackgroundColor3 = G[varName] and color or Color3.fromRGB(100, 100, 100)
    end)

    b.MouseButton1Click:Connect(function()
        G[varName] = not G[varName]
        b.BackgroundColor3 = G[varName] and color or Color3.fromRGB(100, 100, 100)
        b.Text = G[varName] and "ON" or "OFF"
        Notify(text .. ": " .. (G[varName] and "ON" or "OFF"))
        if varName == "SpeedBoost" then
            if G[varName] then ApplySpeed() else ResetSpeed() end
        end
    end)

    return b
end

local function CreateInput(parent, text, varName, min, max, isText)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text .. ": " .. tostring(G[varName])
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0.4, -10, 0.7, 0)
    tb.Position = UDim2.new(0.55, 0, 0.15, 0)
    tb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    tb.Text = tostring(G[varName])
    tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    tb.TextSize = 11
    tb.Font = Enum.Font.Gotham
    tb.ClearTextOnFocus = false
    tb.Parent = f
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)

    tb.FocusLost:Connect(function()
        if isText then
            G[varName] = tb.Text
            l.Text = text .. ": " .. G[varName]
        else
            local n = tonumber(tb.Text)
            if n and n >= min and n <= max then
                G[varName] = n
                l.Text = text .. ": " .. n
            else
                tb.Text = tostring(G[varName])
            end
        end
    end)

    return tb
end

local function CreateSkillButton(parent, key, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 30)
    btn.Position = UDim2.new(0, 5 + (index - 1) * 42, 0.5, -15)
    btn.BackgroundColor3 = Skills[key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
    btn.Text = key
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        Skills[key] = not Skills[key]
        btn.BackgroundColor3 = Skills[key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        Notify("Skill " .. key .. ": " .. (Skills[key] and "ON" or "OFF"))
    end)
    return btn
end

local function CreatePositionButton(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.2, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = "Pos:"
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.7, -10, 0.7, 0)
    b.Position = UDim2.new(0.25, 0, 0.15, 0)
    b.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    b.Text = G.PositionMode
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

    local modes = {"Back", "Front", "Top", "Bottom"}
    b.MouseButton1Click:Connect(function()
        local idx = table.find(modes, G.PositionMode) or 1
        idx = idx % 4 + 1
        G.PositionMode = modes[idx]
        b.Text = G.PositionMode
        Notify("Position: " .. G.PositionMode)
    end)
    return b
end

local function CreateTitleBar(parent)
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, 35)
    tb.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    tb.BorderSizePixel = 0
    tb.Parent = parent
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient", tb)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
    }

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -40, 1, 0)
    tl.Position = UDim2.new(0, 12, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "🍊 Rock Farm Hub"
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 15
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = tb

    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0, 28, 0, 28)
    cb.Position = UDim2.new(1, -32, 0, 3)
    cb.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    cb.Text = "X"
    cb.TextColor3 = Color3.fromRGB(255, 255, 255)
    cb.TextSize = 13
    cb.Font = Enum.Font.GothamBold
    cb.Parent = tb
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 6)
    cb.MouseButton1Click:Connect(function()
        parent.Visible = false
        Notify("GUI Hidden — กดปุ่ม RF เพื่อเปิดใหม่")
    end)

    return tb
end

local function MakeDraggable(titleBar, frame)
    local dragging = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateOpenButton(parent, mainFrame)
    local ob = Instance.new("TextButton")
    ob.Size = UDim2.new(0, 45, 0, 45)
    ob.Position = UDim2.new(0, 10, 0, 10)
    ob.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    ob.Text = "RF"
    ob.TextColor3 = Color3.fromRGB(255, 255, 255)
    ob.TextSize = 16
    ob.Font = Enum.Font.GothamBold
    ob.Parent = parent
    Instance.new("UICorner", ob).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient", ob)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
    }
    ob.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
    return ob
end

-- ============================================================
-- ฝ่ายที่ 12: INIT (เริ่มต้นสคริปต์)
-- ============================================================

local function Init()
    -- 1. รอ Character โหลด
    repeat task.wait() until Player.Character
    repeat task.wait() until Player.Character:FindFirstChild("HumanoidRootPart")

    -- 2. หา Remote (cache)
    ActionRemote = FindActionRemote()
    StatRemote = FindStatRemote()
    print("[RockFarm] ActionRemote:", ActionRemote and ActionRemote:GetFullName() or "NOT FOUND")
    print("[RockFarm] StatRemote:", StatRemote and StatRemote:GetFullName() or "NOT FOUND")

    -- 3. สร้าง ScreenGui
    local oldGui = game:GetService("CoreGui"):FindFirstChild("RockFarmHub")
    if oldGui then oldGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RockFarmHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- 4. Main Frame
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 280, 0, 480)
    mf.Position = UDim2.new(0.5, -140, 0.5, -240)
    mf.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mf.BorderSizePixel = 0
    mf.Parent = ScreenGui
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", mf)
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 2

    -- 5. Title Bar + Drag
    local titleBar = CreateTitleBar(mf)
    MakeDraggable(titleBar, mf)

    -- 6. ScrollFrame
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -10, 1, -90)
    sf.Position = UDim2.new(0, 5, 0, 40)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 4
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Parent = mf
    local layout = Instance.new("UIListLayout", sf)
    layout.Padding = UDim.new(0, 5)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- 7. Toggle Buttons (7 ตัว)
    CreateToggle(sf, "🌾 Auto Farm", "AutoFarm", Color3.fromRGB(100, 255, 100))
    CreateToggle(sf, "🖱️ Auto Click", "AutoClick", Color3.fromRGB(255, 200, 100))
    CreateToggle(sf, "⚔️ Auto Skill", "AutoSkill", Color3.fromRGB(255, 100, 100))
    CreateToggle(sf, "🗡️ Auto Equip", "AutoEquip", Color3.fromRGB(150, 150, 255))
    CreateToggle(sf, "📋 Auto Quest", "AutoQuest", Color3.fromRGB(100, 200, 255))
    CreateToggle(sf, "📊 Auto Stats", "AutoStats", Color3.fromRGB(255, 255, 100))
    CreateToggle(sf, "💨 Speed Boost", "SpeedBoost", Color3.fromRGB(100, 255, 255))

    -- 8. Skills Label + Buttons (Z, X, C, V, F)
    local skLabel = Instance.new("TextLabel")
    skLabel.Size = UDim2.new(1, 0, 0, 20)
    skLabel.BackgroundTransparency = 1
    skLabel.Text = "⚔️ Skills"
    skLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    skLabel.TextSize = 12
    skLabel.Font = Enum.Font.GothamBold
    skLabel.TextXAlignment = Enum.TextXAlignment.Left
    skLabel.Parent = sf

    local skf = Instance.new("Frame")
    skf.Size = UDim2.new(1, 0, 0, 36)
    skf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    skf.BorderSizePixel = 0
    skf.Parent = sf
    Instance.new("UICorner", skf).CornerRadius = UDim.new(0, 6)

    local keys = {"Z", "X", "C", "V", "F"}
    for i, k in ipairs(keys) do
        CreateSkillButton(skf, k, i)
    end

    -- 9. Input Boxes (9 ช่อง)
    CreateInput(sf, "Mob Filter", "MobFilter", 0, 0, true)
    CreateInput(sf, "Distance", "Distance", 1, 15)
    CreateInput(sf, "Max Range", "MaxRange", 100, 2000)
    CreateInput(sf, "Skill Delay", "SkillDelay", 0.1, 5.0)
    CreateInput(sf, "Speed", "SpeedValue", 16, 500)

    -- Position Button
    CreatePositionButton(sf)

    -- Stats Label
    local stLabel = Instance.new("TextLabel")
    stLabel.Size = UDim2.new(1, 0, 0, 20)
    stLabel.BackgroundTransparency = 1
    stLabel.Text = "📊 Stat Distribution"
    stLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    stLabel.TextSize = 12
    stLabel.Font = Enum.Font.GothamBold
    stLabel.TextXAlignment = Enum.TextXAlignment.Left
    stLabel.Parent = sf

    CreateInput(sf, "Melee", "Melee", 0, 100)
    CreateInput(sf, "Sword", "Sword", 0, 100)
    CreateInput(sf, "Devil Fruit", "DevilFruit", 0, 100)
    CreateInput(sf, "Defense", "Defense", 0, 100)

    -- 10. Status Label
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, -10, 0, 25)
    sl.Position = UDim2.new(0, 5, 1, -32)
    sl.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    sl.Text = "Ready"
    sl.TextColor3 = Color3.fromRGB(100, 255, 100)
    sl.TextSize = 11
    sl.Font = Enum.Font.Gotham
    sl.Parent = mf
    Instance.new("UICorner", sl).CornerRadius = UDim.new(0, 5)
    StatusText = sl

    -- 11. Open Button
    CreateOpenButton(ScreenGui, mf)

    -- 12. เริ่ม Loop ทั้ง 5 threads
    StartCacheRefresh()
    StartFarm()
    AutoQuestLoop()
    AutoStatsLoop()
    AntiAFKLoop()
    -- Thread 6 (CharacterAdded) ทำงานอัตโนมัติ

    print("[Rock Farm Hub] Loaded successfully! 🍊")
    Notify("Rock Farm Hub Loaded! 🍊")
end

-- เริ่ม!
Init()
