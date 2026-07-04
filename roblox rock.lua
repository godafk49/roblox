local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Backpack = Player:WaitForChild("Backpack")

-- ==================== CONFIG ====================
local AutoFarm = false
local AutoClick = false
local AutoSkill = false
local AutoEquip = false
local AutoQuest = false
local AntiAFK = true
local WalkSpeedBoost = false
local Distance = 5
local PositionMode = "Back"
local MaxRange = 500
local MobFilter = ""
local Skills = {Z=false, X=false, C=false, V=false, Q=false, E=false, R=false, F=false}
local SkillDelay = 1
local WalkSpeedValue = 100
local MobPaths = {"workspace.Mob", "workspace.Mobs", "workspace.Enemies", "workspace.NPCs"}

-- Cache & Stats
local MobsCache = {}
local LastRefresh = 0
local KillCount = 0
local LastSkillUse = {}
local LastAFKMove = 0
local IsRunning = true

-- ==================== NOTIFICATION SYSTEM ====================
local function Notify(title, text, duration)
    duration = duration or 3
    local cg = game:GetService("CoreGui")
    local notifGui = cg:FindFirstChild("AFNotify")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "AFNotify"
        notifGui.Parent = cg
        notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifGui.ResetOnSpawn = false
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.Position = UDim2.new(1, 20, 0.8, 0)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 22)
    titleLabel.Position = UDim2.new(0, 5, 0, 3)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10, 0, 30)
    textLabel.Position = UDim2.new(0, 5, 0, 25)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    textLabel.Parent = frame
    
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -270, 0.8, 0)
    }):Play()
    
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 20, 0.8, 0)
        }):Play()
        task.wait(0.5)
        frame:Destroy()
    end)
end

-- ==================== SAFE CALL ====================
local function SafeCall(func)
    local success, err = pcall(func)
    if not success then 
        warn("[AutoFarm] " .. tostring(err)) 
        Notify("Error", tostring(err), 3)
    end
    return success
end

-- ==================== GET PLAYER LEVEL (รวมทุกที่) ====================
local function GetPlayerLevel()
    local level = nil
    
    SafeCall(function()
        -- วิธีที่ 1: จาก PlayerGui HUD (ตามที่บอก)
        local playerGui = Player:FindFirstChild("PlayerGui")
        if playerGui then
            local hud = playerGui:FindFirstChild("HUD")
            if hud then
                local main = hud:FindFirstChild("Main")
                if main then
                    local frameDisplay = main:FindFirstChild("Frame_Display")
                    if frameDisplay then
                        local levelText = frameDisplay:FindFirstChild("LevelText")
                        if levelText and levelText:IsA("TextLabel") then
                            -- ดึงตัวเลขจาก "Lv. 832" -> 832
                            local num = string.match(levelText.Text, "%d+")
                            if num then
                                level = tonumber(num)
                                return
                            end
                        end
                    end
                end
            end
        end
        
        -- วิธีที่ 2: Player.Data.Level
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Level") then
            level = Player.Data.Level.Value
            return
        end
        
        -- วิธีที่ 3: Player.leaderstats.Level
        if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Level") then
            level = Player.leaderstats.Level.Value
            return
        end
        
        -- วิธีที่ 4: Player.Level (ตรงๆ)
        if Player:FindFirstChild("Level") then
            level = Player.Level.Value
            return
        end
        
        -- วิธีที่ 5: Player.Stats.Level
        if Player:FindFirstChild("Stats") and Player.Stats:FindFirstChild("Level") then
            level = Player.Stats.Level.Value
            return
        end
        
        -- วิธีที่ 6: Player.Data.Stats.Level
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Stats") and Player.Data.Stats:FindFirstChild("Level") then
            level = Player.Data.Stats.Level.Value
            return
        end
        
        -- วิธีที่ 7: Player.Data.Lv
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Lv") then
            level = Player.Data.Lv.Value
            return
        end
        
        -- วิธีที่ 8: Player.leaderstats.Lv
        if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Lv") then
            level = Player.leaderstats.Lv.Value
            return
        end
        
        -- วิธีที่ 9: Player.Lv
        if Player:FindFirstChild("Lv") then
            level = Player.Lv.Value
            return
        end
        
        -- วิธีที่ 10: หาใน Player.Data ทั้งหมด
        if Player:FindFirstChild("Data") then
            for _, child in ipairs(Player.Data:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = string.lower(child.Name)
                    if name == "level" or name == "lv" or name == "lvl" then
                        level = child.Value
                        return
                    end
                end
            end
        end
        
        -- วิธีที่ 11: หาใน Player โดยตรง
        for _, child in ipairs(Player:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local name = string.lower(child.Name)
                if name == "level" or name == "lv" or name == "lvl" then
                    level = child.Value
                    return
                end
            end
        end
        
        -- วิธีที่ 12: หาใน Character
        if Character then
            for _, child in ipairs(Character:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = string.lower(child.Name)
                    if name == "level" or name == "lv" or name == "lvl" then
                        level = child.Value
                        return
                    end
                end
            end
        end
        
        -- วิธีที่ 13: หาใน PlayerGui ทั้งหมด (TextLabel ที่มีเลข)
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local text = gui.Text
                    -- หา pattern "Lv. 123" หรือ "Level 123" หรือ "LV.123"
                    local num = string.match(text, "[Ll][Vv]%.?%s*(%d+)")
                    if not num then
                        num = string.match(text, "[Ll][Ee][Vv][Ee][Ll]%s*:?%s*(%d+)")
                    end
                    if num then
                        level = tonumber(num)
                        return
                    end
                end
            end
        end
    end)
    
    return level
end

-- ==================== CHARACTER RELOAD ====================
local function SetupCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    HRP = Character:WaitForChild("HumanoidRootPart")
    Backpack = Player:WaitForChild("Backpack")
    
    if WalkSpeedBoost then
        Humanoid.WalkSpeed = WalkSpeedValue
    end
    
    if _G.RebuildUI then _G.RebuildUI() end
    
    Notify("Character", "Character loaded successfully!", 2)
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    SafeCall(SetupCharacter)
end)

-- ==================== ANTI-AFK ====================
local function AntiAFKLoop()
    task.spawn(function()
        while IsRunning do
            if AntiAFK then
                local now = tick()
                if now - LastAFKMove >= 300 then
                    SafeCall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    end)
                    LastAFKMove = now
                    if _G.StatusText then _G.StatusText.Text = "Anti-AFK: Moved" end
                end
            end
            task.wait(30)
        end
    end)
end

-- ==================== AUTO CONFIRM DIALOG (โควทอัตโนมัติ) ====================
local function AutoConfirmDialog()
    SafeCall(function()
        local playerGui = Player:WaitForChild("PlayerGui")
        task.wait(0.5)
        
        local confirmKeywords = {"Accept", "Confirm", "Yes", "Accept Quest", "รับ", "ตกลง", "Take", "Get", "Start", "OK", "ตกลง"}
        
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local text = string.lower(gui.Text)
                for _, keyword in ipairs(confirmKeywords) do
                    if string.find(text, string.lower(keyword), 1, true) then
                        local pos = gui.AbsolutePosition
                        local size = gui.AbsoluteSize
                        local center = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
                        
                        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
                        
                        Notify("Quest", "Auto-confirmed: " .. gui.Text, 2)
                        return
                    end
                end
            end
        end
        
        -- ถ้าไม่เจอปุ่ม กด E, Space, 1
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end)
end

-- ==================== AUTO QUEST (LEVEL-BASED + ATTRIBUTE) ====================
local function GetQuest()
    if not AutoQuest then return end
    
    SafeCall(function()
        local npcFolder = workspace:FindFirstChild("NpcQuest")
        if not npcFolder then
            local possibleNames = {"NpcQuest", "NPCQuest", "QuestNPC", "Quests", "NPC_Quests"}
            for _, name in ipairs(possibleNames) do
                npcFolder = workspace:FindFirstChild(name)
                if npcFolder then break end
            end
        end
        
        if not npcFolder then
            Notify("Quest", "NPC Quest folder not found!", 3)
            return
        end
        
        -- ดึงเลเวลผู้เล่น
        local playerLevel = GetPlayerLevel()
        
        if playerLevel then
            Notify("Debug", "Your Level: " .. tostring(playerLevel), 2)
        else
            Notify("Debug", "Level not found! Using nearest NPC", 3)
        end
        
        -- หา NPC ที่เหมาะสมกับเลเวล
        local bestNPC = nil
        local bestDiff = math.huge
        local myPos = HRP.Position
        
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                -- ดึงเลเวลจาก Attribute (แบบในภาพ)
                local npcLevel = nil
                
                -- ลองหา Attribute "Level"
                if npc:GetAttribute("Level") then
                    npcLevel = npc:GetAttribute("Level")
                -- ลองหา Attribute "Lv" หรือ "lv"
                elseif npc:GetAttribute("Lv") then
                    npcLevel = npc:GetAttribute("Lv")
                elseif npc:GetAttribute("lv") then
                    npcLevel = npc:GetAttribute("lv")
                -- สำรอง: ดึงจากชื่อ (เช่น NPC_Quest12 -> 12)
                else
                    local levelStr = string.match(npc.Name, "%d+")
                    if levelStr then
                        npcLevel = tonumber(levelStr)
                    end
                end
                
                local dist = (npc.HumanoidRootPart.Position - myPos).Magnitude
                
                -- ถ้ารู้เลเวลตัวเอง ให้เลือกตามเลเวล
                if playerLevel and npcLevel then
                    local levelDiff = math.abs(playerLevel - npcLevel)
                    
                    -- เลือก NPC ที่เลเวลใกล้เคียงที่สุด และไม่สูงกว่าเลเวลตัวเองมากเกินไป
                    if dist <= 200 and npcLevel <= playerLevel + 10 and levelDiff < bestDiff then
                        bestDiff = levelDiff
                        bestNPC = npc
                    end
                else
                    -- ถ้าไม่รู้เลเวลตัวเอง ให้เลือกตัวใกล้สุด
                    if dist <= 200 and dist < bestDiff then
                        bestDiff = dist
                        bestNPC = npc
                    end
                end
            end
        end
        
        if bestNPC then
            -- ดึงข้อมูล NPC
            local npcLevel = bestNPC:GetAttribute("Level") or bestNPC:GetAttribute("Lv") or "?"
            local npcName = bestNPC:GetAttribute("Name") or bestNPC.Name
            
            Notify("Quest", "Going to " .. npcName .. " (Lv." .. tostring(npcLevel) .. ")", 2)
            
            -- เทเลพอร์ตไปหา NPC
            SafeCall(function()
                HRP.CFrame = bestNPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end)
            
            task.wait(0.5)
            
            -- กดรับเควส (ProximityPrompt)
            local prompt = bestNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.5)
                Notify("Quest", "Accepted quest from " .. npcName, 2)
            else
                -- ลองหา ClickDetector
                local clickDetector = bestNPC:FindFirstChildWhichIsA("ClickDetector", true)
                if clickDetector then
                    fireclickdetector(clickDetector)
                    task.wait(0.5)
                    Notify("Quest", "Clicked " .. npcName, 2)
                end
            end
            
            -- โควทอัตโนมัติ
            task.wait(0.3)
            AutoConfirmDialog()
        else
            Notify("Quest", "No suitable NPC found!", 3)
        end
    end)
end

-- ==================== MOB DETECTION ====================
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

local function GetDist(p1, p2)
    return (p1 - p2).Magnitude
end

local function GetOffset(cf, mode, dist)
    if mode == "Back" then return cf * CFrame.new(0, 0, dist)
    elseif mode == "Front" then return cf * CFrame.new(0, 0, -dist)
    elseif mode == "Top" then return cf * CFrame.new(0, dist, 0)
    elseif mode == "Bottom" then return cf * CFrame.new(0, -dist, 0)
    else return cf * CFrame.new(0, 0, dist) end
end

local function FindMobs()
    local mobs = {}
    
    for _, path in ipairs(MobPaths) do
        local parts = string.split(path, ".")
        local current = game
        for i = 2, #parts do
            current = current:FindFirstChild(parts[i])
            if not current then break end
        end
        if current then
            for _, obj in ipairs(current:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if IsValidTarget(obj) then
                        if MobFilter == "" or string.find(string.lower(obj.Name), string.lower(MobFilter), 1, true) then
                            table.insert(mobs, obj)
                        end
                    end
                end
            end
        end
    end
    
    if #mobs == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                if IsValidTarget(obj) then
                    if MobFilter == "" or string.find(string.lower(obj.Name), string.lower(MobFilter), 1, true) then
                        table.insert(mobs, obj)
                    end
                end
            end
        end
    end
    
    table.sort(mobs, function(a, b)
        return GetDist(HRP.Position, a.HumanoidRootPart.Position) < GetDist(HRP.Position, b.HumanoidRootPart.Position)
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
            if GetDist(HRP.Position, mob.HumanoidRootPart.Position) <= MaxRange then
                return mob
            end
        end
    end
    return nil
end

-- ==================== KILL COUNTER ====================
local function TrackKills()
    local oldHealth = {}
    task.spawn(function()
        while IsRunning do
            if AutoFarm then
                for _, mob in ipairs(MobsCache) do
                    if mob and mob:FindFirstChild("Humanoid") then
                        local h = mob.Humanoid
                        local currentHealth = h.Health
                        local prevHealth = oldHealth[mob] or currentHealth
                        
                        if currentHealth <= 0 and prevHealth > 0 then
                            KillCount = KillCount + 1
                            if _G.KillCounter then _G.KillCounter.Text = "Kills: " .. KillCount end
                            Notify("Kill", "Killed " .. mob.Name .. " | Total: " .. KillCount, 2)
                        end
                        oldHealth[mob] = currentHealth
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ==================== FARM LOOP ====================
local function StartFarm()
    task.spawn(function()
        while IsRunning do
            if AutoFarm then
                if AutoQuest then GetQuest() end
                
                local target = GetNearest()
                if target then
                    if _G.StatusText then _G.StatusText.Text = "Target: " .. target.Name end
                    
                    if AutoEquip then
                        local hasTool = false
                        for _, v in pairs(Character:GetChildren()) do
                            if v:IsA("Tool") then hasTool = true; break end
                        end
                        if not hasTool then
                            for _, tool in ipairs(Backpack:GetChildren()) do
                                if tool:IsA("Tool") then
                                    SafeCall(function() Humanoid:EquipTool(tool) end)
                                    break
                                end
                            end
                        end
                    end
                    
                    SafeCall(function()
                        HRP.CFrame = GetOffset(target.HumanoidRootPart.CFrame, PositionMode, Distance)
                    end)
                    
                    if AutoClick then
                        SafeCall(function()
                            if VirtualUser then
                                VirtualUser:CaptureController()
                                VirtualUser:ClickButton1(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                            end
                        end)
                    end
                    
                    if AutoSkill then
                        local now = tick()
                        for key, enabled in pairs(Skills) do
                            if enabled then
                                local last = LastSkillUse[key] or 0
                                if now - last >= SkillDelay then
                                    SafeCall(function()
                                        if VirtualInputManager then
                                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
                                            task.wait(0.05)
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
                                        end
                                    end)
                                    LastSkillUse[key] = now
                                end
                            end
                        end
                    end
                else
                    if _G.StatusText then _G.StatusText.Text = "No target in range" end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- ==================== UI ====================
local function MakeUI()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("AFUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "AFUI"
    sg.Parent = cg
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn = false

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 300, 0, 450)
    mf.Position = UDim2.new(0.5, -150, 0.5, -225)
    mf.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.Parent = sg
    Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", mf).Color = Color3.fromRGB(80, 80, 200)

    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, 30)
    tb.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    tb.BorderSizePixel = 0
    tb.Parent = mf
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -30, 1, 0)
    tl.Position = UDim2.new(0, 10, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "Auto Farm v2.0"
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 14
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = tb

    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0, 24, 0, 24)
    cb.Position = UDim2.new(1, -28, 0, 3)
    cb.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    cb.Text = "X"
    cb.TextColor3 = Color3.fromRGB(255, 255, 255)
    cb.TextSize = 12
    cb.Font = Enum.Font.GothamBold
    cb.Parent = tb
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 6)
    cb.MouseButton1Click:Connect(function() mf.Visible = false end)

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -10, 1, -100)
    sf.Position = UDim2.new(0, 5, 0, 35)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.CanvasSize = UDim2.new(0, 0, 0, 600)
    sf.Parent = mf
    Instance.new("UIListLayout", sf).Padding = UDim.new(0, 5)

    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, -10, 0, 20)
    sl.Position = UDim2.new(0, 5, 1, -55)
    sl.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    sl.Text = "Ready"
    sl.TextColor3 = Color3.fromRGB(100, 255, 100)
    sl.TextSize = 11
    sl.Font = Enum.Font.Gotham
    sl.Parent = mf
    Instance.new("UICorner", sl).CornerRadius = UDim.new(0, 5)
    _G.StatusText = sl

    local kl = Instance.new("TextLabel")
    kl.Size = UDim2.new(1, -10, 0, 20)
    kl.Position = UDim2.new(0, 5, 1, -30)
    kl.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
    kl.Text = "Kills: 0"
    kl.TextColor3 = Color3.fromRGB(255, 200, 100)
    kl.TextSize = 12
    kl.Font = Enum.Font.GothamBold
    kl.Parent = mf
    Instance.new("UICorner", kl).CornerRadius = UDim.new(0, 5)
    _G.KillCounter = kl

    local function Toggle(parent, text, var, color)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 28)
        f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6, 0, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 40, 0, 20)
        b.Position = UDim2.new(1, -48, 0.5, -10)
        b.BackgroundColor3 = var and (color or Color3.fromRGB(100, 255, 100)) or Color3.fromRGB(100, 100, 100)
        b.Text = var and "ON" or "OFF"
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

        return b, l
    end

    local b1 = Toggle(sf, "Auto Farm", AutoFarm, Color3.fromRGB(100, 255, 100))
    b1.MouseButton1Click:Connect(function()
        AutoFarm = not AutoFarm
        b1.BackgroundColor3 = AutoFarm and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        b1.Text = AutoFarm and "ON" or "OFF"
        sl.Text = "Auto Farm: " .. (AutoFarm and "ON" or "OFF")
        Notify("Auto Farm", AutoFarm and "Started" or "Stopped", 2)
    end)

    local b2 = Toggle(sf, "Auto Click", AutoClick, Color3.fromRGB(255, 200, 100))
    b2.MouseButton1Click:Connect(function()
        AutoClick = not AutoClick
        b2.BackgroundColor3 = AutoClick and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(100, 100, 100)
        b2.Text = AutoClick and "ON" or "OFF"
    end)

    local b3 = Toggle(sf, "Auto Skill", AutoSkill, Color3.fromRGB(255, 100, 100))
    b3.MouseButton1Click:Connect(function()
        AutoSkill = not AutoSkill
        b3.BackgroundColor3 = AutoSkill and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 100, 100)
        b3.Text = AutoSkill and "ON" or "OFF"
    end)

    local b4 = Toggle(sf, "Auto Equip", AutoEquip, Color3.fromRGB(150, 150, 255))
    b4.MouseButton1Click:Connect(function()
        AutoEquip = not AutoEquip
        b4.BackgroundColor3 = AutoEquip and Color3.fromRGB(150, 150, 255) or Color3.fromRGB(100, 100, 100)
        b4.Text = AutoEquip and "ON" or "OFF"
    end)

    local b5 = Toggle(sf, "Auto Quest", AutoQuest, Color3.fromRGB(255, 150, 50))
    b5.MouseButton1Click:Connect(function()
        AutoQuest = not AutoQuest
        b5.BackgroundColor3 = AutoQuest and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(100, 100, 100)
        b5.Text = AutoQuest and "ON" or "OFF"
        Notify("Auto Quest", AutoQuest and "Enabled" or "Disabled", 2)
    end)

    local b6 = Toggle(sf, "Anti-AFK", AntiAFK, Color3.fromRGB(50, 255, 150))
    b6.MouseButton1Click:Connect(function()
        AntiAFK = not AntiAFK
        b6.BackgroundColor3 = AntiAFK and Color3.fromRGB(50, 255, 150) or Color3.fromRGB(100, 100, 100)
        b6.Text = AntiAFK and "ON" or "OFF"
        if AntiAFK then LastAFKMove = tick() end
    end)

    local b7 = Toggle(sf, "WalkSpeed", WalkSpeedBoost, Color3.fromRGB(200, 100, 255))
    b7.MouseButton1Click:Connect(function()
        WalkSpeedBoost = not WalkSpeedBoost
        b7.BackgroundColor3 = WalkSpeedBoost and Color3.fromRGB(200, 100, 255) or Color3.fromRGB(100, 100, 100)
        b7.Text = WalkSpeedBoost and "ON" or "OFF"
        if Humanoid then
            Humanoid.WalkSpeed = WalkSpeedBoost and WalkSpeedValue or 16
        end
        Notify("WalkSpeed", WalkSpeedBoost and "Boosted to " .. WalkSpeedValue or "Reset to 16", 2)
    end)

    -- Mob Filter
    local sf2 = Instance.new("Frame")
    sf2.Size = UDim2.new(1, 0, 0, 28)
    sf2.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    sf2.BorderSizePixel = 0
    sf2.Parent = sf
    Instance.new("UICorner", sf2).CornerRadius = UDim.new(0, 6)

    local sl2 = Instance.new("TextLabel")
    sl2.Size = UDim2.new(0.2, 0, 1, 0)
    sl2.Position = UDim2.new(0, 8, 0, 0)
    sl2.BackgroundTransparency = 1
    sl2.Text = "Mob:"
    sl2.TextColor3 = Color3.fromRGB(255, 255, 255)
    sl2.TextSize = 12
    sl2.Font = Enum.Font.Gotham
    sl2.TextXAlignment = Enum.TextXAlignment.Left
    sl2.Parent = sf2

    local sb = Instance.new("TextBox")
    sb.Size = UDim2.new(0.7, 0, 0.7, 0)
    sb.Position = UDim2.new(0.25, 0, 0.15, 0)
    sb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sb.Text = MobFilter
    sb.TextColor3 = Color3.fromRGB(255, 255, 255)
    sb.TextSize = 12
    sb.Font = Enum.Font.Gotham
    sb.ClearTextOnFocus = false
    sb.Parent = sf2
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 5)
    sb.FocusLost:Connect(function()
        MobFilter = sb.Text
        LastRefresh = 0
        sl.Text = "Filter: " .. (MobFilter ~= "" and MobFilter or "All")
    end)

    -- Distance
    local df = Instance.new("Frame")
    df.Size = UDim2.new(1, 0, 0, 40)
    df.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    df.BorderSizePixel = 0
    df.Parent = sf
    Instance.new("UICorner", df).CornerRadius = UDim.new(0, 6)

    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, -10, 0, 16)
    dl.Position = UDim2.new(0, 8, 0, 2)
    dl.BackgroundTransparency = 1
    dl.Text = "Distance: " .. Distance
    dl.TextColor3 = Color3.fromRGB(255, 255, 255)
    dl.TextSize = 11
    dl.Font = Enum.Font.Gotham
    dl.TextXAlignment = Enum.TextXAlignment.Left
    dl.Parent = df

    local db = Instance.new("TextBox")
    db.Size = UDim2.new(0.9, 0, 0, 18)
    db.Position = UDim2.new(0.05, 0, 0, 18)
    db.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    db.Text = tostring(Distance)
    db.TextColor3 = Color3.fromRGB(255, 255, 255)
    db.TextSize = 11
    db.Font = Enum.Font.Gotham
    db.Parent = df
    Instance.new("UICorner", db).CornerRadius = UDim.new(0, 5)
    db.FocusLost:Connect(function()
        local n = tonumber(db.Text)
        if n and n >= 1 and n <= 15 then
            Distance = n
            dl.Text = "Distance: " .. Distance
        end
    end)

    -- Max Range
    local rf = Instance.new("Frame")
    rf.Size = UDim2.new(1, 0, 0, 40)
    rf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    rf.BorderSizePixel = 0
    rf.Parent = sf
    Instance.new("UICorner", rf).CornerRadius = UDim.new(0, 6)

    local rl = Instance.new("TextLabel")
    rl.Size = UDim2.new(1, -10, 0, 16)
    rl.Position = UDim2.new(0, 8, 0, 2)
    rl.BackgroundTransparency = 1
    rl.Text = "Max Range: " .. MaxRange
    rl.TextColor3 = Color3.fromRGB(255, 255, 255)
    rl.TextSize = 11
    rl.Font = Enum.Font.Gotham
    rl.TextXAlignment = Enum.TextXAlignment.Left
    rl.Parent = rf

    local rb = Instance.new("TextBox")
    rb.Size = UDim2.new(0.9, 0, 0, 18)
    rb.Position = UDim2.new(0.05, 0, 0, 18)
    rb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    rb.Text = tostring(MaxRange)
    rb.TextColor3 = Color3.fromRGB(255, 255, 255)
    rb.TextSize = 11
    rb.Font = Enum.Font.Gotham
    rb.Parent = rf
    Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 5)
    rb.FocusLost:Connect(function()
        local n = tonumber(rb.Text)
        if n and n >= 50 and n <= 5000 then
            MaxRange = n
            rl.Text = "Max Range: " .. MaxRange
            LastRefresh = 0
        end
    end)

    -- Skill Delay
    local sdf = Instance.new("Frame")
    sdf.Size = UDim2.new(1, 0, 0, 40)
    sdf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    sdf.BorderSizePixel = 0
    sdf.Parent = sf
    Instance.new("UICorner", sdf).CornerRadius = UDim.new(0, 6)

    local sdl = Instance.new("TextLabel")
    sdl.Size = UDim2.new(1, -10, 0, 16)
    sdl.Position = UDim2.new(0, 8, 0, 2)
    sdl.BackgroundTransparency = 1
    sdl.Text = "Skill Delay: " .. SkillDelay .. "s"
    sdl.TextColor3 = Color3.fromRGB(255, 255, 255)
    sdl.TextSize = 11
    sdl.Font = Enum.Font.Gotham
    sdl.TextXAlignment = Enum.TextXAlignment.Left
    sdl.Parent = sdf

    local sdb = Instance.new("TextBox")
    sdb.Size = UDim2.new(0.9, 0, 0, 18)
    sdb.Position = UDim2.new(0.05, 0, 0, 18)
    sdb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sdb.Text = tostring(SkillDelay)
    sdb.TextColor3 = Color3.fromRGB(255, 255, 255)
    sdb.TextSize = 11
    sdb.Font = Enum.Font.Gotham
    sdb.Parent = sdf
    Instance.new("UICorner", sdb).CornerRadius = UDim.new(0, 5)
    sdb.FocusLost:Connect(function()
        local n = tonumber(sdb.Text)
        if n and n >= 0.1 and n <= 10 then
            SkillDelay = n
            sdl.Text = "Skill Delay: " .. SkillDelay .. "s"
        end
    end)

    -- WalkSpeed Value
    local wsf = Instance.new("Frame")
    wsf.Size = UDim2.new(1, 0, 0, 40)
    wsf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    wsf.BorderSizePixel = 0
    wsf.Parent = sf
    Instance.new("UICorner", wsf).CornerRadius = UDim.new(0, 6)

    local wsl = Instance.new("TextLabel")
    wsl.Size = UDim2.new(1, -10, 0, 16)
    wsl.Position = UDim2.new(0, 8, 0, 2)
    wsl.BackgroundTransparency = 1
    wsl.Text = "WalkSpeed: " .. WalkSpeedValue
    wsl.TextColor3 = Color3.fromRGB(255, 255, 255)
    wsl.TextSize = 11
    wsl.Font = Enum.Font.Gotham
    wsl.TextXAlignment = Enum.TextXAlignment.Left
    wsl.Parent = wsf

    local wsb = Instance.new("TextBox")
    wsb.Size = UDim2.new(0.9, 0, 0, 18)
    wsb.Position = UDim2.new(0.05, 0, 0, 18)
    wsb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    wsb.Text = tostring(WalkSpeedValue)
    wsb.TextColor3 = Color3.fromRGB(255, 255, 255)
    wsb.TextSize = 11
    wsb.Font = Enum.Font.Gotham
    wsb.Parent = wsf
    Instance.new("UICorner", wsb).CornerRadius = UDim.new(0, 5)
    wsb.FocusLost:Connect(function()
        local n = tonumber(wsb.Text)
        if n and n >= 16 and n <= 500 then
            WalkSpeedValue = n
            wsl.Text = "WalkSpeed: " .. WalkSpeedValue
            if WalkSpeedBoost and Humanoid then
                Humanoid.WalkSpeed = WalkSpeedValue
            end
        end
    end)

    -- Position Mode
    local pf = Instance.new("Frame")
    pf.Size = UDim2.new(1, 0, 0, 28)
    pf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    pf.BorderSizePixel = 0
    pf.Parent = sf
    Instance.new("UICorner", pf).CornerRadius = UDim.new(0, 6)

    local pl = Instance.new("TextLabel")
    pl.Size = UDim2.new(0.2, 0, 1, 0)
    pl.Position = UDim2.new(0, 8, 0, 0)
    pl.BackgroundTransparency = 1
    pl.Text = "Pos:"
    pl.TextColor3 = Color3.fromRGB(255, 255, 255)
    pl.TextSize = 12
    pl.Font = Enum.Font.Gotham
    pl.TextXAlignment = Enum.TextXAlignment.Left
    pl.Parent = pf

    local pb = Instance.new("TextButton")
    pb.Size = UDim2.new(0.7, 0, 0.7, 0)
    pb.Position = UDim2.new(0.25, 0, 0.15, 0)
    pb.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    pb.Text = PositionMode
    pb.TextColor3 = Color3.fromRGB(255, 255, 255)
    pb.TextSize = 12
    pb.Font = Enum.Font.GothamBold
    pb.Parent = pf
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 5)

    local modes = {"Back", "Front", "Top", "Bottom"}
    local mi = 1
    pb.MouseButton1Click:Connect(function()
        mi = mi % 4 + 1
        PositionMode = modes[mi]
        pb.Text = PositionMode
    end)

    -- Skills
    local skl = Instance.new("TextLabel")
    skl.Size = UDim2.new(1, 0, 0, 18)
    skl.BackgroundTransparency = 1
    skl.Text = "Skills"
    skl.TextColor3 = Color3.fromRGB(200, 200, 255)
    skl.TextSize = 11
    skl.Font = Enum.Font.GothamBold
    skl.Parent = sf

    local skf = Instance.new("Frame")
    skf.Size = UDim2.new(1, 0, 0, 30)
    skf.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    skf.BorderSizePixel = 0
    skf.Parent = sf
    Instance.new("UICorner", skf).CornerRadius = UDim.new(0, 6)

    local keys = {"Z", "X", "C", "V", "Q", "E", "R", "F"}
    for i, k in ipairs(keys) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(0, 3 + (i-1) * 30, 0.5, -13)
        btn.BackgroundColor3 = Skills[k] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        btn.Text = k
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.Parent = skf
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            Skills[k] = not Skills[k]
            btn.BackgroundColor3 = Skills[k] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        end)
    end

    -- Drag
    local drag = false
    local di, ds, sp
    tb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds = input.Position
            sp = mf.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    tb.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            di = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == di and drag then
            local d = input.Position - ds
            mf.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)

    -- Open Button
    local ob = Instance.new("TextButton")
    ob.Size = UDim2.new(0, 45, 0, 45)
    ob.Position = UDim2.new(0, 10, 0, 10)
    ob.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    ob.Text = "AF"
    ob.TextColor3 = Color3.fromRGB(255, 255, 255)
    ob.TextSize = 16
    ob.Font = Enum.Font.GothamBold
    ob.Parent = sg
    Instance.new("UICorner", ob).CornerRadius = UDim.new(1, 0)
    ob.MouseButton1Click:Connect(function()
        mf.Visible = not mf.Visible
    end)

    _G.RebuildUI = function() end

    print("UI Created!")
    Notify("Auto Farm", "Script loaded successfully!", 3)
end

-- ==================== KEYBINDS ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local g = game:GetService("CoreGui"):FindFirstChild("AFUI")
        if g then
            local m = g:FindFirstChild("Frame")
            if m then m.Visible = not m.Visible end
        end
    end
    if input.KeyCode == Enum.KeyCode.Insert then
        AutoFarm = not AutoFarm
        Notify("Auto Farm", AutoFarm and "Started (Insert)" or "Stopped (Insert)", 2)
        if _G.StatusText then _G.StatusText.Text = "Auto Farm: " .. (AutoFarm and "ON" or "OFF") end
    end
end)

-- ==================== INITIALIZATION ====================
repeat task.wait() until Player.Character
repeat task.wait() until Player.Character:FindFirstChild("HumanoidRootPart")
MakeUI()
StartFarm()
TrackKills()
AntiAFKLoop()
print("Auto Farm v2.0 Loaded!")
