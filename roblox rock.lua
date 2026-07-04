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

local AutoFarm = false
local AutoClick = false
local AutoSkill = false
local AutoEquip = false
local AutoQuest = false
local AntiAFK = true
local WalkSpeedBoost = false
local QuestOnly = false
local Distance = 5
local PositionMode = "Back"
local MaxRange = 500
local MobFilter = ""
local Skills = {Z=false, X=false, C=false, V=false, Q=false, E=false, R=false, F=false}
local SkillDelay = 1
local WalkSpeedValue = 100
local MobPaths = {"workspace.Mob", "workspace.Mobs", "workspace.Enemies", "workspace.NPCs"}

local CurrentQuestMob = nil
local CurrentQuestNPC = nil
local QuestActive = false
local SelectedWeapon = nil
local MobsCache = {}
local LastRefresh = 0
local KillCount = 0
local LastSkillUse = {}
local LastAFKMove = 0
local IsRunning = true
local LastQuestCheck = 0

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
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -270, 0.8, 0)}):Play()
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 20, 0.8, 0)}):Play()
        task.wait(0.5)
        frame:Destroy()
    end)
end

local function SafeCall(func)
    local success, err = pcall(func)
    if not success then
        warn("[AutoFarm] " .. tostring(err))
        Notify("Error", tostring(err), 3)
    end
    return success
end

local function GetPlayerLevel()
    local level = nil
    SafeCall(function()
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
                            local num = string.match(levelText.Text, "%d+")
                            if num then level = tonumber(num) return end
                        end
                    end
                end
            end
        end
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Level") then
            level = Player.Data.Level.Value return
        end
        if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Level") then
            level = Player.leaderstats.Level.Value return
        end
        if Player:FindFirstChild("Level") then
            level = Player.Level.Value return
        end
        if Player:FindFirstChild("Stats") and Player.Stats:FindFirstChild("Level") then
            level = Player.Stats.Level.Value return
        end
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Lv") then
            level = Player.Data.Lv.Value return
        end
        if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Lv") then
            level = Player.leaderstats.Lv.Value return
        end
        if Player:FindFirstChild("Lv") then
            level = Player.Lv.Value return
        end
        if Player:FindFirstChild("Data") then
            for _, child in ipairs(Player.Data:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = string.lower(child.Name)
                    if name == "level" or name == "lv" or name == "lvl" then
                        level = child.Value return
                    end
                end
            end
        end
        for _, child in ipairs(Player:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local name = string.lower(child.Name)
                if name == "level" or name == "lv" or name == "lvl" then
                    level = child.Value return
                end
            end
        end
        if Character then
            for _, child in ipairs(Character:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = string.lower(child.Name)
                    if name == "level" or name == "lv" or name == "lvl" then
                        level = child.Value return
                    end
                end
            end
        end
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local text = gui.Text
                    local num = string.match(text, "[Ll][Vv]%.?%s*(%d+)")
                    if not num then num = string.match(text, "[Ll][Ee][Vv][Ee][Ll]%s*:?%s*(%d+)") end
                    if num then level = tonumber(num) return end
                end
            end
        end
    end)
    return level
end

local function CheckQuestStatus()
    local hasQuest = false
    local questMob = nil
    local questProgress = nil
    local questTitle = nil

    SafeCall(function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        local hud = playerGui:FindFirstChild("HUD")
        if not hud then return end
        local main = hud:FindFirstChild("Main")
        if not main then return end
        local frameQuest = main:FindFirstChild("Frame_Quest")
        if not frameQuest then return end

        if frameQuest:IsA("Frame") or frameQuest:IsA("ImageLabel") or frameQuest:IsA("ImageButton") then
            if frameQuest.Visible == false then
                hasQuest = false
                return
            end
        end

        hasQuest = true

        for _, child in ipairs(frameQuest:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.Text
                if text and text ~= "" then
                    local mobName = string.match(text, "[Kk]ill%s+%d+%s+(.+)")
                    if not mobName then mobName = string.match(text, "[Dd]efeat%s+(.+)") end
                    if not mobName then mobName = string.match(text, "[Dd]estroy%s+(.+)") end
                    if mobName then
                        questMob = mobName
                    end
                    local progress = string.match(text, "(%d+)%s*/%s*(%d+)")
                    if progress then
                        questProgress = progress
                    end
                    if not questTitle and (string.find(text, "Defeat") or string.find(text, "Kill") or string.find(text, "Destroy")) then
                        questTitle = text
                    end
                end
            end
        end

        if not questMob and questTitle then
            local mob = string.match(questTitle, "Defeat%s+%d+%s+(.+)")
            if not mob then mob = string.match(questTitle, "Kill%s+%d+%s+(.+)") end
            if not mob then mob = string.match(questTitle, "Destroy%s+%d+%s+(.+)") end
            if mob then questMob = mob end
        end

        if not questMob then
            for _, child in ipairs(frameQuest:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text ~= "" then
                    local text = child.Text
                    if string.find(text, "Defeat") or string.find(text, "Kill") or string.find(text, "Destroy") then
                        local patterns = {"Defeat%s+%d+%s+(.+)", "Kill%s+%d+%s+(.+)", "Destroy%s+%d+%s+(.+)", "Defeat%s+(.+)", "Kill%s+(.+)", "Destroy%s+(.+)"}
                        for _, pattern in ipairs(patterns) do
                            local mob = string.match(text, pattern)
                            if mob then questMob = mob break end
                        end
                    end
                    if questMob then break end
                end
            end
        end
    end)

    return hasQuest, questMob, questProgress
end

local function GetQuestMobFromNPC(npc)
    local mobName = nil
    SafeCall(function()
        if npc:GetAttribute("Name") then
            mobName = npc:GetAttribute("Name")
        elseif npc:GetAttribute("Target") then
            mobName = npc:GetAttribute("Target")
        elseif npc:GetAttribute("Mob") then
            mobName = npc:GetAttribute("Mob")
        else
            local name = npc.Name
            if string.find(name, "NPC_") then
                local cleanName = string.gsub(name, "NPC_Quest%d*", "")
                cleanName = string.gsub(cleanName, "NPC_", "")
                cleanName = string.gsub(cleanName, "Quest", "")
                if cleanName ~= "" then
                    mobName = cleanName
                end
            end
        end
    end)
    return mobName
end

local function SetupCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    HRP = Character:WaitForChild("HumanoidRootPart")
    Backpack = Player:WaitForChild("Backpack")
    if WalkSpeedBoost then Humanoid.WalkSpeed = WalkSpeedValue end
    if _G.RebuildUI then _G.RebuildUI() end
    Notify("Character", "Character loaded successfully!", 2)
end

Player.CharacterAdded:Connect(function()
    task.wait(1)
    SafeCall(SetupCharacter)
end)

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

local function AutoConfirmDialog()
    SafeCall(function()
        local playerGui = Player:WaitForChild("PlayerGui")
        task.wait(0.5)
        local confirmKeywords = {"Accept", "Confirm", "Yes", "Accept Quest", "รับ", "ตกลง", "Take", "Get", "Start", "OK", "ตกลง"}
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local text = ""
                if gui:IsA("TextButton") then text = string.lower(gui.Text) end
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

local function GetQuest()
    if not AutoQuest then return end

    local hasQuest, existingMob, progress = CheckQuestStatus()
    if hasQuest then
        QuestActive = true
        CurrentQuestMob = existingMob
        if _G.StatusText then _G.StatusText.Text = "Quest Active: " .. (existingMob or "Unknown") end
        Notify("Quest", "Already have quest: " .. (existingMob or "Unknown"), 2)
        return
    end

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

        local playerLevel = GetPlayerLevel()
        if playerLevel then
            Notify("Debug", "Your Level: " .. tostring(playerLevel), 2)
        else
            Notify("Debug", "Level not found! Using nearest NPC", 3)
        end

        local bestNPC = nil
        local bestDiff = math.huge
        local myPos = HRP.Position

        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                local npcLevel = nil
                if npc:GetAttribute("Level") then
                    npcLevel = npc:GetAttribute("Level")
                elseif npc:GetAttribute("Lv") then
                    npcLevel = npc:GetAttribute("Lv")
                elseif npc:GetAttribute("lv") then
                    npcLevel = npc:GetAttribute("lv")
                else
                    local levelStr = string.match(npc.Name, "%d+")
                    if levelStr then npcLevel = tonumber(levelStr) end
                end

                local dist = (npc.HumanoidRootPart.Position - myPos).Magnitude

                if playerLevel and npcLevel then
                    local levelDiff = math.abs(playerLevel - npcLevel)
                    if dist <= 500 and npcLevel <= playerLevel + 50 and levelDiff < bestDiff then
                        bestDiff = levelDiff
                        bestNPC = npc
                    end
                else
                    if dist <= 500 and dist < bestDiff then
                        bestDiff = dist
                        bestNPC = npc
                    end
                end
            end
        end

        if bestNPC then
            local npcLevel = bestNPC:GetAttribute("Level") or bestNPC:GetAttribute("Lv") or "?"
            local npcDisplayName = bestNPC:GetAttribute("Name") or bestNPC.Name
            CurrentQuestNPC = bestNPC.Name

            local targetMob = GetQuestMobFromNPC(bestNPC)
            if targetMob then
                CurrentQuestMob = targetMob
            end

            Notify("Quest", "Going to " .. npcDisplayName .. " (Lv." .. tostring(npcLevel) .. ")", 2)

            SafeCall(function()
                HRP.CFrame = bestNPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end)

            task.wait(0.5)

            local prompt = bestNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
                task.wait(0.5)
                Notify("Quest", "Accepted quest from " .. npcDisplayName, 2)
            else
                local clickDetector = bestNPC:FindFirstChildWhichIsA("ClickDetector", true)
                if clickDetector then
                    fireclickdetector(clickDetector)
                    task.wait(0.5)
                    Notify("Quest", "Clicked " .. npcDisplayName, 2)
                end
            end

            task.wait(0.3)
            AutoConfirmDialog()

            task.wait(1)
            local hasNewQuest, newQuestMob, newProgress = CheckQuestStatus()
            if hasNewQuest then
                QuestActive = true
                CurrentQuestMob = newQuestMob
                if CurrentQuestMob then
                    Notify("Quest", "Target: " .. CurrentQuestMob, 3)
                    if _G.StatusText then _G.StatusText.Text = "Quest: " .. CurrentQuestMob end
                end
            else
                if targetMob then
                    QuestActive = true
                    CurrentQuestMob = targetMob
                    Notify("Quest", "Target (from NPC): " .. targetMob, 3)
                end
            end
        else
            Notify("Quest", "No suitable NPC found!", 3)
        end
    end)
end

local function SmartTeleport(target)
    SafeCall(function()
        if not target or not target:FindFirstChild("HumanoidRootPart") then return end
        local targetHRP = target.HumanoidRootPart
        local targetCF = targetHRP.CFrame
        local hiddenOffset = CFrame.new(0, -15, 8)
        HRP.CFrame = targetCF * hiddenOffset
        if Humanoid then
            Humanoid.WalkSpeed = 0
            task.wait(0.1)
            HRP.CFrame = targetCF * CFrame.new(0, 0, Distance)
            task.wait(0.05)
            Humanoid.WalkSpeed = WalkSpeedBoost and WalkSpeedValue or 16
        end
    end)
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
                        if QuestOnly and CurrentQuestMob then
                            local questNameLower = string.lower(CurrentQuestMob)
                            local mobNameLower = string.lower(obj.Name)
                            if string.find(mobNameLower, questNameLower, 1, true) or string.find(questNameLower, mobNameLower, 1, true) then
                                table.insert(mobs, obj)
                            end
                        else
                            if MobFilter == "" or string.find(string.lower(obj.Name), string.lower(MobFilter), 1, true) then
                                table.insert(mobs, obj)
                            end
                        end
                    end
                end
            end
        end
    end
    if #mobs == 0 and not QuestOnly then
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
                            if QuestOnly and CurrentQuestMob then
                                local mobNameLower = string.lower(mob.Name)
                                local questNameLower = string.lower(CurrentQuestMob)
                                if string.find(mobNameLower, questNameLower, 1, true) or string.find(questNameLower, mobNameLower, 1, true) then
                                    task.wait(1)
                                    local hasQuest, questMob, progress = CheckQuestStatus()
                                    if not hasQuest then
                                        QuestActive = false
                                        CurrentQuestMob = nil
                                    end
                                end
                            end
                        end
                        oldHealth[mob] = currentHealth
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function EquipSelectedWeapon()
    if not SelectedWeapon then return end
    SafeCall(function()
        for _, v in pairs(Character:GetChildren()) do
            if v:IsA("Tool") and v.Name == SelectedWeapon then return end
        end
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == SelectedWeapon then
                Humanoid:EquipTool(tool)
                Notify("Equip", "Equipped: " .. SelectedWeapon, 2)
                return
            end
        end
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                Humanoid:EquipTool(tool)
                Notify("Equip", "Equipped: " .. tool.Name, 2)
                return
            end
        end
    end)
end

local function StartFarm()
    task.spawn(function()
        while IsRunning do
            if AutoFarm then
                if AutoQuest then
                    local now = tick()
                    if now - LastQuestCheck >= 5 then
                        LastQuestCheck = now
                        local hasQuest, questMob, progress = CheckQuestStatus()
                        if hasQuest then
                            QuestActive = true
                            if questMob and questMob ~= CurrentQuestMob then
                                CurrentQuestMob = questMob
                                Notify("Quest", "Updated target: " .. questMob, 2)
                            end
                        else
                            if QuestActive then
                                QuestActive = false
                                CurrentQuestMob = nil
                                Notify("Quest", "Quest completed! Getting new quest...", 2)
                                GetQuest()
                            else
                                GetQuest()
                            end
                        end
                    end
                end

                local target = GetNearest()
                if target then
                    if _G.StatusText then _G.StatusText.Text = "Target: " .. target.Name end
                    if AutoEquip then EquipSelectedWeapon() end
                    SmartTeleport(target)
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
                    if _G.StatusText then
                        if QuestOnly and CurrentQuestMob then
                            _G.StatusText.Text = "Quest: " .. CurrentQuestMob .. " not found"
                        else
                            _G.StatusText.Text = "No target in range"
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

local function GetWeaponList()
    local weapons = {}
    SafeCall(function()
        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(weapons, tool.Name) end
        end
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") then table.insert(weapons, tool.Name) end
        end
    end)
    return weapons
end

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
    mf.Size = UDim2.new(0, 320, 0, 520)
    mf.Position = UDim2.new(0.5, -160, 0.5, -260)
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
    tl.Text = "Auto Farm v4.1"
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
    sf.Size = UDim2.new(1, -10, 1, -120)
    sf.Position = UDim2.new(0, 5, 0, 35)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.CanvasSize = UDim2.new(0, 0, 0, 900)
    sf.Parent = mf
    Instance.new("UIListLayout", sf).Padding = UDim.new(0, 5)

    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, -10, 0, 20)
    sl.Position = UDim2.new(0, 5, 1, -75)
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
    kl.Position = UDim2.new(0, 5, 1, -50)
    kl.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
    kl.Text = "Kills: 0"
    kl.TextColor3 = Color3.fromRGB(255, 200, 100)
    kl.TextSize = 12
    kl.Font = Enum.Font.GothamBold
    kl.Parent = mf
    Instance.new("UICorner", kl).CornerRadius = UDim.new(0, 5)
    _G.KillCounter = kl

    local ql = Instance.new("TextLabel")
    ql.Size = UDim2.new(1, -10, 0, 20)
    ql.Position = UDim2.new(0, 5, 1, -25)
    ql.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    ql.Text = "Quest: None"
    ql.TextColor3 = Color3.fromRGB(100, 200, 255)
    ql.TextSize = 11
    ql.Font = Enum.Font.Gotham
    ql.Parent = mf
    Instance.new("UICorner", ql).CornerRadius = UDim.new(0, 5)
    _G.QuestText = ql

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

    local b8 = Toggle(sf, "Quest Only", QuestOnly, Color3.fromRGB(255, 100, 200))
    b8.MouseButton1Click:Connect(function()
        QuestOnly = not QuestOnly
        b8.BackgroundColor3 = QuestOnly and Color3.fromRGB(255, 100, 200) or Color3.fromRGB(100, 100, 100)
        b8.Text = QuestOnly and "ON" or "OFF"
        Notify("Quest Only", QuestOnly and "Only quest mobs" or "All mobs", 2)
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
        if Humanoid then Humanoid.WalkSpeed = WalkSpeedBoost and WalkSpeedValue or 16 end
        Notify("WalkSpeed", WalkSpeedBoost and "Boosted to " .. WalkSpeedValue or "Reset to 16", 2)
    end)

    local wepLabel = Instance.new("TextLabel")
    wepLabel.Size = UDim2.new(1, 0, 0, 18)
    wepLabel.BackgroundTransparency = 1
    wepLabel.Text = "Select Weapon"
    wepLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    wepLabel.TextSize = 11
    wepLabel.Font = Enum.Font.GothamBold
    wepLabel.Parent = sf

    local wepFrame = Instance.new("Frame")
    wepFrame.Size = UDim2.new(1, 0, 0, 80)
    wepFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    wepFrame.BorderSizePixel = 0
    wepFrame.Parent = sf
    Instance.new("UICorner", wepFrame).CornerRadius = UDim.new(0, 6)

    local wepScroll = Instance.new("ScrollingFrame")
    wepScroll.Size = UDim2.new(1, -10, 1, -10)
    wepScroll.Position = UDim2.new(0, 5, 0, 5)
    wepScroll.BackgroundTransparency = 1
    wepScroll.ScrollBarThickness = 3
    wepScroll.CanvasSize = UDim2.new(0, 0, 0, 200)
    wepScroll.Parent = wepFrame
    local wepListLayout = Instance.new("UIListLayout", wepScroll)
    wepListLayout.Padding = UDim.new(0, 3)

    local function RefreshWeapons()
        for _, child in ipairs(wepScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local weapons = GetWeaponList()
        for _, weaponName in ipairs(weapons) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 22)
            btn.BackgroundColor3 = (SelectedWeapon == weaponName) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 80)
            btn.Text = weaponName
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 11
            btn.Font = Enum.Font.Gotham
            btn.Parent = wepScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                SelectedWeapon = weaponName
                for _, b in ipairs(wepScroll:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = (b.Text == SelectedWeapon) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(60, 60, 80)
                    end
                end
                Notify("Weapon", "Selected: " .. weaponName, 2)
            end)
        end
        wepScroll.CanvasSize = UDim2.new(0, 0, 0, #weapons * 25)
    end

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, 0, 0, 20)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
    refreshBtn.Text = "Refresh Weapons"
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.TextSize = 10
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.Parent = sf
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 5)
    refreshBtn.MouseButton1Click:Connect(function()
        RefreshWeapons()
        Notify("Weapon", "Weapon list refreshed", 2)
    end)

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
            if WalkSpeedBoost and Humanoid then Humanoid.WalkSpeed = WalkSpeedValue end
        end
    end)

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
    ob.MouseButton1Click:Connect(function() mf.Visible = not mf.Visible end)

    _G.RebuildUI = function() end

    task.spawn(function()
        while IsRunning do
            if _G.QuestText then
                local hasQuest, questMob, progress = CheckQuestStatus()
                if hasQuest then
                    local displayText = "Quest: " .. (questMob or "Active")
                    if progress then displayText = displayText .. " (" .. progress .. ")" end
                    _G.QuestText.Text = displayText
                    _G.QuestText.TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    _G.QuestText.Text = "Quest: None"
                    _G.QuestText.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            end
            task.wait(2)
        end
    end)

    task.delay(1, RefreshWeapons)
    print("UI Created!")
    Notify("Auto Farm", "Script loaded successfully!", 3)
end

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

repeat task.wait() until Player.Character
repeat task.wait() until Player.Character:FindFirstChild("HumanoidRootPart")
MakeUI()
StartFarm()
TrackKills()
AntiAFKLoop()
print("Auto Farm v4.1 Loaded!")
