local v_u_Players = game:GetService("Players")
local v_u_UserInputService = game:GetService("UserInputService")
local v_u_VirtualUser = game:GetService("VirtualUser")
local v_u_VirtualInputManager = game:GetService("VirtualInputManager")
local v_u_ReplicatedStorage = game:GetService("ReplicatedStorage")
local v_u_RunService = game:GetService("RunService")
local v_u_Debris = game:GetService("Debris")
local v_u_Workspace = workspace

local v_u_Player = v_u_Players.LocalPlayer
local v_u_Character = v_u_Player.Character or v_u_Player.CharacterAdded:Wait()
local v_u_Humanoid = v_u_Character:WaitForChild("Humanoid", 30)
local v_u_HRP = v_u_Character:WaitForChild("HumanoidRootPart", 30)
local v_u_Backpack = v_u_Player:WaitForChild("Backpack")

-- ============================================================
--  Config Variables
-- ============================================================
local v_u_Enabled = true
local v_u_AutoFarm = false
local v_u_AutoClick = false
local v_u_AutoSkill = false
local v_u_AutoEquipToggle = false
local v_u_AutoQuest = false
local v_u_AutoStats = false
local v_u_SpeedBoost = false
local v_u_MobFilter = ""
local v_u_PositionMode = "Back"
local v_u_Distance = 5
local v_u_MaxRange = 500
local v_u_SkillDelay = 1.5
local v_u_SpeedValue = 100
local v_u_Melee = 0
local v_u_Sword = 0
local v_u_DevilFruit = 0
local v_u_Defense = 0

-- ============================================================
--  System Variables
-- ============================================================
local v_u_MobsCache = {}
local v_u_LastRefresh = 0
local v_u_ActionRemote = nil
local v_u_StatRemote = nil
local v_u_Skills = {Z=false, X=false, C=false, V=false, F=false}
local v_u_LastSkillUse = {}
local v_u_KillCount = 0
local v_u_KilledTargets = {}
local v_u_StatusText = nil
local v_u_ScreenGui = nil
local v_u_MainFrame = nil

-- ============================================================
--  SECTION 14: SafeCall (pcall wrapper)
-- ============================================================
local function v_u_SafeCall(p_func)
    local v_success, v_err = pcall(p_func)
    if not v_success then
        warn("[RockFarm] " .. tostring(v_err))
    end
    return v_success
end

-- ============================================================
--  SECTION 2: Mob Detection System
-- ============================================================
local function v_u_IsValidTarget(p_mob)
    if not p_mob or not p_mob.Parent then
        return false
    end
    local v_h = p_mob:FindFirstChild("Humanoid")
    local v_hrp = p_mob:FindFirstChild("HumanoidRootPart")
    if not v_h or not v_hrp then
        return false
    end
    if v_h.Health <= 0 then
        return false
    end
    if p_mob == v_u_Character then
        return false
    end
    if v_u_Players:GetPlayerFromCharacter(p_mob) then
        return false
    end
    return true
end

local function v_u_GetDist(p1, p2)
    return (p1 - p2).Magnitude
end

local function v_u_FindMobs()
    local v_mobs = {}
    local v_roots = {
        v_u_Workspace:FindFirstChild("Mobs"),
        v_u_Workspace:FindFirstChild("NPCs"),
        v_u_Workspace:FindFirstChild("Enemies"),
        v_u_Workspace
    }
    for _, v_root in ipairs(v_roots) do
        if v_root then
            for _, v_obj in ipairs(v_root:GetDescendants()) do
                if v_obj:IsA("Model")
                    and v_obj:FindFirstChild("Humanoid")
                    and v_obj:FindFirstChild("HumanoidRootPart")
                    and v_u_IsValidTarget(v_obj) then
                    if v_u_MobFilter == "" then
                        table.insert(v_mobs, v_obj)
                    else
                        if string.find(string.lower(v_obj.Name), string.lower(v_u_MobFilter), 1, true) then
                            table.insert(v_mobs, v_obj)
                        end
                    end
                end
            end
        end
    end
    table.sort(v_mobs, function(a, b)
        return v_u_GetDist(v_u_HRP.Position, a.HumanoidRootPart.Position)
             < v_u_GetDist(v_u_HRP.Position, b.HumanoidRootPart.Position)
    end)
    return v_mobs
end

local function v_u_GetNearest()
    local v_now = tick()
    if v_now - v_u_LastRefresh >= 3 then
        v_u_MobsCache = v_u_FindMobs()
        v_u_LastRefresh = v_now
    end
    for _, v_mob in ipairs(v_u_MobsCache) do
        if v_u_IsValidTarget(v_mob) then
            if v_u_GetDist(v_u_HRP.Position, v_mob.HumanoidRootPart.Position) <= v_u_MaxRange then
                return v_mob
            end
        end
    end
    return nil
end

-- ============================================================
--  SECTION 3: Teleport System
-- ============================================================
local function v_u_GetOffset(p_cf, p_mode, p_dist)
    if p_mode == "Back" then
        return p_cf * CFrame.new(0, 0, p_dist)
    elseif p_mode == "Front" then
        return p_cf * CFrame.new(0, 0, -p_dist)
    elseif p_mode == "Top" then
        return p_cf * CFrame.new(0, p_dist, 0)
    elseif p_mode == "Bottom" then
        return p_cf * CFrame.new(0, -p_dist, 0)
    end
    return p_cf * CFrame.new(0, 0, p_dist)
end

local function v_u_Teleport(p_target)
    v_u_SafeCall(function()
        v_u_HRP.CFrame = v_u_GetOffset(p_target.HumanoidRootPart.CFrame, v_u_PositionMode, v_u_Distance)
    end)
end

-- ============================================================
--  SECTION 4: Remote Event System
-- ============================================================
local function v_u_FindActionRemote()
    local v_remote = nil
    pcall(function()
        local v_rs = v_u_ReplicatedStorage
        local v_packages = v_rs:FindFirstChild("Packages")
        if not v_packages then return end
        local v_index = v_packages:FindFirstChild("_Index")
        if not v_index then return end
        local v_net = v_index:FindFirstChild("sleitnick_net@0.2.0")
        if not v_net then return end
        local v_netModule = v_net:FindFirstChild("net")
        if not v_netModule then return end
        v_remote = v_netModule:FindFirstChild("RE/ActionRemote")
    end)
    return v_remote
end

v_u_ActionRemote = v_u_FindActionRemote()

local function v_u_AttackFallback()
    v_u_SafeCall(function()
        if v_u_ActionRemote then
            v_u_ActionRemote:FireServer("M1", "Combat")
        else
            v_u_VirtualUser:CaptureController()
            v_u_VirtualUser:ClickButton1(Vector2.new(0, 0), v_u_Workspace.CurrentCamera.CFrame)
        end
    end)
end

-- ============================================================
--  SECTION 5: Auto Equip Weapon
-- ============================================================
local function v_u_AutoEquipFunc()
    local v_hasTool = false
    for _, v in pairs(v_u_Character:GetChildren()) do
        if v:IsA("Tool") then
            v_hasTool = true
            break
        end
    end
    if not v_hasTool then
        for _, v_tool in ipairs(v_u_Backpack:GetChildren()) do
            if v_tool:IsA("Tool") then
                v_u_SafeCall(function()
                    v_u_Humanoid:EquipTool(v_tool)
                end)
                break
            end
        end
    end
end

-- ============================================================
--  SECTION 6: Skill System (Z, X, C, V, F)
-- ============================================================
local function v_u_PressSkill(p_key)
    v_u_SafeCall(function()
        v_u_VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[p_key], false, game)
        task.wait(0.05)
        v_u_VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[p_key], false, game)
    end)
end

local function v_u_AutoSkillLoop()
    local v_now = tick()
    for v_key, v_enabled in pairs(v_u_Skills) do
        if v_enabled then
            local v_last = v_u_LastSkillUse[v_key] or 0
            if v_now - v_last >= v_u_SkillDelay then
                v_u_PressSkill(v_key)
                v_u_LastSkillUse[v_key] = v_now
            end
        end
    end
end

-- ============================================================
--  SECTION 7: Auto Quest
-- ============================================================
local function v_u_FindQuestNPC()
    for _, v_obj in ipairs(v_u_Workspace:GetDescendants()) do
        if v_obj:IsA("ProximityPrompt") then
            local v_parent = v_obj.Parent
            if v_parent and (v_parent.Name:lower():find("quest", 1, true)
                           or v_parent.Name:lower():find("npc", 1, true)) then
                local v_hrp = v_parent:FindFirstChild("HumanoidRootPart")
                if v_hrp then
                    return v_parent, v_obj
                end
            end
        end
    end
    return nil, nil
end

local function v_u_TriggerQuest(p_npc, p_prompt)
    v_u_SafeCall(function()
        local v_hrp = p_npc:FindFirstChild("HumanoidRootPart")
        if v_hrp then
            v_u_HRP.CFrame = v_hrp.CFrame * CFrame.new(0, 0, 3)
        end
        task.wait(0.5)
        p_prompt.HoldDuration = 0
        p_prompt:InputHoldBegin()
        task.wait(0.3)
        p_prompt:InputHoldEnd()
    end)
end

local function v_u_AutoQuestLoop()
    while v_u_Enabled do
        if v_u_AutoQuest then
            local v_npc, v_prompt = v_u_FindQuestNPC()
            if v_npc and v_prompt then
                v_u_TriggerQuest(v_npc, v_prompt)
                task.wait(1)
            end
        end
        task.wait(5)
    end
end

-- ============================================================
--  SECTION 8: Auto Stats
-- ============================================================
local function v_u_FindStatRemote()
    local v_remote = nil
    pcall(function()
        for _, v_obj in ipairs(v_u_ReplicatedStorage:GetDescendants()) do
            if v_obj:IsA("RemoteEvent") then
                local v_name = v_obj.Name:lower()
                if v_name:find("stat", 1, true)
                   or v_name:find("addpoint", 1, true)
                   or v_name:find("allocate", 1, true) then
                    v_remote = v_obj
                    return
                end
            end
        end
    end)
    return v_remote
end

v_u_StatRemote = v_u_FindStatRemote()

local function v_u_AllocateStats()
    v_u_SafeCall(function()
        local v_stats = {
            {"Melee", v_u_Melee},
            {"Sword", v_u_Sword},
            {"DevilFruit", v_u_DevilFruit},
            {"Defense", v_u_Defense}
        }
        for _, v_s in ipairs(v_stats) do
            local v_statName = v_s[1]
            local v_statValue = v_s[2]
            if v_statValue > 0 and v_u_StatRemote then
                v_u_StatRemote:FireServer(v_statName, v_statValue)
            end
        end
    end)
end

local function v_u_AutoStatsLoop()
    while v_u_Enabled do
        if v_u_AutoStats then
            v_u_AllocateStats()
        end
        task.wait(2)
    end
end

-- ============================================================
--  SECTION 9: Speed Boost
-- ============================================================
local function v_u_ApplySpeed()
    v_u_SafeCall(function()
        if v_u_SpeedBoost and v_u_Humanoid then
            v_u_Humanoid.WalkSpeed = v_u_SpeedValue
        end
    end)
end

local function v_u_ResetSpeed()
    v_u_SafeCall(function()
        if v_u_Humanoid then
            v_u_Humanoid.WalkSpeed = 16
        end
    end)
end

-- ============================================================
--  SECTION 10: Anti-AFK
-- ============================================================
local function v_u_AntiAFKLoop()
    while v_u_Enabled do
        v_u_SafeCall(function()
            v_u_VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            v_u_VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
        task.wait(60)
    end
end

-- ============================================================
--  SECTION 11: Character Reload
-- ============================================================
v_u_Player.CharacterAdded:Connect(function(p_char)
    v_u_Character = p_char
    v_u_Humanoid = p_char:WaitForChild("Humanoid")
    v_u_HRP = p_char:WaitForChild("HumanoidRootPart")
    v_u_Backpack = v_u_Player:WaitForChild("Backpack")
    if v_u_SpeedBoost then
        v_u_ApplySpeed()
    end
end)

-- ============================================================
--  SECTION 12: Kill Counter
-- ============================================================
local function v_u_TrackKill(p_target)
    if not p_target then return end
    local v_h = p_target:FindFirstChild("Humanoid")
    if not v_h then return end
    if v_h.Health > 0 then
        v_u_KilledTargets[p_target] = true
    end
end

local function v_u_CheckKills()
    for v_target, _ in pairs(v_u_KilledTargets) do
        local v_h = v_target:FindFirstChild("Humanoid")
        if v_h and v_h.Health <= 0 then
            v_u_KillCount = v_u_KillCount + 1
            v_u_KilledTargets[v_target] = nil
            v_u_UpdateStatus("Kills: " .. v_u_KillCount)
        elseif not v_target.Parent then
            v_u_KilledTargets[v_target] = nil
        end
    end
end

-- ============================================================
--  SECTION 13: Notification
-- ============================================================
local function v_u_Notify(p_text)
    v_u_SafeCall(function()
        local v_n = Instance.new("TextLabel")
        v_n.Size = UDim2.new(0, 200, 0, 30)
        v_n.Position = UDim2.new(1, -210, 0, 50)
        v_n.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        v_n.TextColor3 = Color3.fromRGB(255, 255, 255)
        v_n.Text = p_text
        v_n.Font = Enum.Font.GothamBold
        v_n.TextSize = 12
        v_n.Parent = v_u_ScreenGui
        Instance.new("UICorner", v_n).CornerRadius = UDim.new(0, 8)
        v_u_Debris:AddItem(v_n, 2)
    end)
end

-- ============================================================
--  SECTION 15: CoreGui Fallback
-- ============================================================
local function v_u_GetGuiParent()
    local v_cg = game:GetService("CoreGui")
    local v_success = pcall(function()
        local v_sg = Instance.new("ScreenGui")
        v_sg.Parent = v_cg
        v_sg:Destroy()
    end)
    if v_success then
        return v_cg
    else
        return v_u_Player:WaitForChild("PlayerGui")
    end
end

-- ============================================================
--  SECTION 18: Update Status
-- ============================================================
local function v_u_UpdateStatus(p_text)
    v_u_SafeCall(function()
        if v_u_StatusText then
            v_u_StatusText.Text = p_text or "Ready"
        end
    end)
end

-- ============================================================
--  SECTION 16: Main Auto Farm Loop
-- ============================================================
local function v_u_StartFarm()
    task.spawn(function()
        while v_u_Enabled do
            if v_u_AutoFarm then
                local v_target = v_u_GetNearest()
                if v_target then
                    v_u_UpdateStatus("Target: " .. v_target.Name .. " | Kills: " .. v_u_KillCount)
                    v_u_TrackKill(v_target)
                    if v_u_AutoEquipToggle then
                        v_u_AutoEquipFunc()
                    end
                    v_u_Teleport(v_target)
                    if v_u_AutoClick then
                        v_u_AttackFallback()
                    end
                    if v_u_AutoSkill then
                        v_u_AutoSkillLoop()
                    end
                else
                    v_u_UpdateStatus("No target | Kills: " .. v_u_KillCount)
                end
            end
            v_u_CheckKills()
            task.wait(0.2)
        end
    end)
end

-- ============================================================
--  SECTION 17: Mob Cache Refresh
-- ============================================================
local function v_u_StartCacheRefresh()
    task.spawn(function()
        while v_u_Enabled do
            v_u_MobsCache = v_u_FindMobs()
            v_u_LastRefresh = tick()
            task.wait(3)
        end
    end)
end

-- ============================================================
--  SECTION 19-25: UI Construction
-- ============================================================
local function v_u_CreateToggle(p_parent, p_text, p_varName, p_color)
    local v_f = Instance.new("Frame")
    v_f.Size = UDim2.new(1, 0, 0, 28)
    v_f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    v_f.BorderSizePixel = 0
    v_f.Parent = p_parent
    Instance.new("UICorner", v_f).CornerRadius = UDim.new(0, 6)

    local v_l = Instance.new("TextLabel")
    v_l.Size = UDim2.new(0.6, 0, 1, 0)
    v_l.Position = UDim2.new(0, 8, 0, 0)
    v_l.BackgroundTransparency = 1
    v_l.Text = p_text
    v_l.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_l.TextSize = 12
    v_l.Font = Enum.Font.Gotham
    v_l.TextXAlignment = Enum.TextXAlignment.Left
    v_l.Parent = v_f

    local v_b = Instance.new("TextButton")
    v_b.Size = UDim2.new(0, 40, 0, 20)
    v_b.Position = UDim2.new(1, -48, 0.5, -10)
    v_b.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_b.TextSize = 10
    v_b.Font = Enum.Font.GothamBold
    v_b.Parent = v_f
    Instance.new("UICorner", v_b).CornerRadius = UDim.new(0, 5)

    local v_var = _G[p_varName]
    v_b.BackgroundColor3 = v_var and p_color or Color3.fromRGB(100, 100, 100)
    v_b.Text = v_var and "ON" or "OFF"

    v_b.MouseEnter:Connect(function()
        if not _G[p_varName] then
            v_b.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
        end
    end)
    v_b.MouseLeave:Connect(function()
        v_b.BackgroundColor3 = _G[p_varName] and p_color or Color3.fromRGB(100, 100, 100)
    end)

    v_b.MouseButton1Click:Connect(function()
        _G[p_varName] = not _G[p_varName]
        v_b.BackgroundColor3 = _G[p_varName] and p_color or Color3.fromRGB(100, 100, 100)
        v_b.Text = _G[p_varName] and "ON" or "OFF"
        v_u_Notify(p_text .. ": " .. (_G[p_varName] and "ON" or "OFF"))

        if p_varName == "SpeedBoost" then
            if _G[p_varName] then
                v_u_SpeedBoost = true
                v_u_ApplySpeed()
            else
                v_u_SpeedBoost = false
                v_u_ResetSpeed()
            end
        elseif p_varName == "AutoFarm" then
            v_u_AutoFarm = _G[p_varName]
        elseif p_varName == "AutoClick" then
            v_u_AutoClick = _G[p_varName]
        elseif p_varName == "AutoSkill" then
            v_u_AutoSkill = _G[p_varName]
        elseif p_varName == "AutoEquip" then
            v_u_AutoEquipToggle = _G[p_varName]
        elseif p_varName == "AutoQuest" then
            v_u_AutoQuest = _G[p_varName]
        elseif p_varName == "AutoStats" then
            v_u_AutoStats = _G[p_varName]
        end
    end)

    return v_b, v_l
end

local function v_u_CreateInput(p_parent, p_text, p_varName, p_min, p_max)
    local v_f = Instance.new("Frame")
    v_f.Size = UDim2.new(1, 0, 0, 28)
    v_f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    v_f.BorderSizePixel = 0
    v_f.Parent = p_parent
    Instance.new("UICorner", v_f).CornerRadius = UDim.new(0, 6)

    local v_l = Instance.new("TextLabel")
    v_l.Size = UDim2.new(0.4, 0, 1, 0)
    v_l.Position = UDim2.new(0, 8, 0, 0)
    v_l.BackgroundTransparency = 1
    v_l.Text = p_text .. ": " .. tostring(_G[p_varName])
    v_l.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_l.TextSize = 11
    v_l.Font = Enum.Font.Gotham
    v_l.TextXAlignment = Enum.TextXAlignment.Left
    v_l.Parent = v_f

    local v_tb = Instance.new("TextBox")
    v_tb.Size = UDim2.new(0.5, 0, 0.7, 0)
    v_tb.Position = UDim2.new(0.45, 0, 0.15, 0)
    v_tb.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    v_tb.Text = tostring(_G[p_varName])
    v_tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_tb.TextSize = 11
    v_tb.Font = Enum.Font.Gotham
    v_tb.ClearTextOnFocus = false
    v_tb.Parent = v_f
    Instance.new("UICorner", v_tb).CornerRadius = UDim.new(0, 5)

    v_tb.FocusLost:Connect(function()
        if p_varName == "MobFilter" then
            _G[p_varName] = v_tb.Text
            v_u_MobFilter = v_tb.Text
        else
            local v_n = tonumber(v_tb.Text)
            if v_n and v_n >= p_min and v_n <= p_max then
                _G[p_varName] = v_n
                v_l.Text = p_text .. ": " .. v_n

                if p_varName == "Distance" then
                    v_u_Distance = v_n
                elseif p_varName == "MaxRange" then
                    v_u_MaxRange = v_n
                elseif p_varName == "SkillDelay" then
                    v_u_SkillDelay = v_n
                elseif p_varName == "SpeedValue" then
                    v_u_SpeedValue = v_n
                    if v_u_SpeedBoost then v_u_ApplySpeed() end
                elseif p_varName == "Melee" then
                    v_u_Melee = v_n
                elseif p_varName == "Sword" then
                    v_u_Sword = v_n
                elseif p_varName == "DevilFruit" then
                    v_u_DevilFruit = v_n
                elseif p_varName == "Defense" then
                    v_u_Defense = v_n
                end
            else
                v_tb.Text = tostring(_G[p_varName])
            end
        end
    end)

    return v_tb, v_l
end

local function v_u_CreateSkillButton(p_parent, p_key, p_index)
    local v_btn = Instance.new("TextButton")
    v_btn.Size = UDim2.new(0, 30, 0, 30)
    v_btn.Position = UDim2.new(0, 3 + (p_index - 1) * 35, 0.5, -15)
    v_btn.BackgroundColor3 = v_u_Skills[p_key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
    v_btn.Text = p_key
    v_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_btn.TextSize = 12
    v_btn.Font = Enum.Font.GothamBold
    v_btn.Parent = p_parent
    Instance.new("UICorner", v_btn).CornerRadius = UDim.new(0, 6)

    v_btn.MouseButton1Click:Connect(function()
        v_u_Skills[p_key] = not v_u_Skills[p_key]
        v_btn.BackgroundColor3 = v_u_Skills[p_key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        v_u_Notify("Skill " .. p_key .. ": " .. (v_u_Skills[p_key] and "ON" or "OFF"))
    end)

    return v_btn
end

local function v_u_CreatePositionButton(p_parent)
    local v_f = Instance.new("Frame")
    v_f.Size = UDim2.new(1, 0, 0, 28)
    v_f.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    v_f.BorderSizePixel = 0
    v_f.Parent = p_parent
    Instance.new("UICorner", v_f).CornerRadius = UDim.new(0, 6)

    local v_l = Instance.new("TextLabel")
    v_l.Size = UDim2.new(0.2, 0, 1, 0)
    v_l.Position = UDim2.new(0, 8, 0, 0)
    v_l.BackgroundTransparency = 1
    v_l.Text = "Pos:"
    v_l.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_l.TextSize = 12
    v_l.Font = Enum.Font.Gotham
    v_l.TextXAlignment = Enum.TextXAlignment.Left
    v_l.Parent = v_f

    local v_b = Instance.new("TextButton")
    v_b.Size = UDim2.new(0.7, 0, 0.7, 0)
    v_b.Position = UDim2.new(0.25, 0, 0.15, 0)
    v_b.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    v_b.Text = v_u_PositionMode
    v_b.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_b.TextSize = 12
    v_b.Font = Enum.Font.GothamBold
    v_b.Parent = v_f
    Instance.new("UICorner", v_b).CornerRadius = UDim.new(0, 5)

    local v_modes = {"Back", "Front", "Top", "Bottom"}
    v_b.MouseButton1Click:Connect(function()
        local v_idx = table.find(v_modes, v_u_PositionMode) or 1
        v_idx = v_idx % 4 + 1
        v_u_PositionMode = v_modes[v_idx]
        v_b.Text = v_u_PositionMode
        v_u_Notify("Position: " .. v_u_PositionMode)
    end)

    return v_b
end

local function v_u_CreateTitleBar(p_parent)
    local v_tb = Instance.new("Frame")
    v_tb.Size = UDim2.new(1, 0, 0, 30)
    v_tb.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    v_tb.BorderSizePixel = 0
    v_tb.Parent = p_parent
    Instance.new("UICorner", v_tb).CornerRadius = UDim.new(0, 10)

    local v_grad = Instance.new("UIGradient", v_tb)
    v_grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 200))
    }

    local v_tl = Instance.new("TextLabel")
    v_tl.Size = UDim2.new(1, -30, 1, 0)
    v_tl.Position = UDim2.new(0, 10, 0, 0)
    v_tl.BackgroundTransparency = 1
    v_tl.Text = "Rock Farm Hub"
    v_tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_tl.TextSize = 14
    v_tl.Font = Enum.Font.GothamBold
    v_tl.TextXAlignment = Enum.TextXAlignment.Left
    v_tl.Parent = v_tb

    local v_cb = Instance.new("TextButton")
    v_cb.Size = UDim2.new(0, 24, 0, 24)
    v_cb.Position = UDim2.new(1, -28, 0, 3)
    v_cb.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    v_cb.Text = "X"
    v_cb.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_cb.TextSize = 12
    v_cb.Font = Enum.Font.GothamBold
    v_cb.Parent = v_tb
    Instance.new("UICorner", v_cb).CornerRadius = UDim.new(0, 6)
    v_cb.MouseButton1Click:Connect(function()
        p_parent.Visible = false
        v_u_Notify("GUI Hidden -- press RF to reopen")
    end)

    return v_tb
end

local function v_u_MakeDraggable(p_titleBar, p_frame)
    local v_dragging = false
    local v_dragStart, v_startPos

    p_titleBar.InputBegan:Connect(function(p_input)
        if p_input.UserInputType == Enum.UserInputType.MouseButton1
           or p_input.UserInputType == Enum.UserInputType.Touch then
            v_dragging = true
            v_dragStart = p_input.Position
            v_startPos = p_frame.Position
            p_input.Changed:Connect(function()
                if p_input.UserInputState == Enum.UserInputState.End then
                    v_dragging = false
                end
            end)
        end
    end)

    v_u_UserInputService.InputChanged:Connect(function(p_input)
        if v_dragging and (p_input.UserInputType == Enum.UserInputType.MouseMovement
                          or p_input.UserInputType == Enum.UserInputType.Touch) then
            local v_delta = p_input.Position - v_dragStart
            p_frame.Position = UDim2.new(
                v_startPos.X.Scale, v_startPos.X.Offset + v_delta.X,
                v_startPos.Y.Scale, v_startPos.Y.Offset + v_delta.Y
            )
        end
    end)
end

local function v_u_CreateOpenButton(p_parent, p_mainFrame)
    local v_ob = Instance.new("TextButton")
    v_ob.Size = UDim2.new(0, 45, 0, 45)
    v_ob.Position = UDim2.new(0, 10, 0, 10)
    v_ob.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    v_ob.Text = "RF"
    v_ob.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_ob.TextSize = 16
    v_ob.Font = Enum.Font.GothamBold
    v_ob.Parent = p_parent
    Instance.new("UICorner", v_ob).CornerRadius = UDim.new(1, 0)

    v_ob.MouseButton1Click:Connect(function()
        p_mainFrame.Visible = not p_mainFrame.Visible
    end)

    return v_ob
end

-- ============================================================
--  SECTION 26: Initialization
-- ============================================================
local function v_u_Init()
    repeat task.wait() until v_u_Player.Character
    repeat task.wait() until v_u_Player.Character:FindFirstChild("HumanoidRootPart")

    v_u_ActionRemote = v_u_FindActionRemote()
    v_u_StatRemote = v_u_FindStatRemote()

    local v_gp = v_u_GetGuiParent()
    v_u_ScreenGui = Instance.new("ScreenGui")
    v_u_ScreenGui.Name = "RockFarmHub"
    v_u_ScreenGui.ResetOnSpawn = false
    v_u_ScreenGui.Parent = v_gp

    v_u_MainFrame = Instance.new("Frame")
    v_u_MainFrame.Size = UDim2.new(0, 260, 0, 420)
    v_u_MainFrame.Position = UDim2.new(0, 50, 0, 50)
    v_u_MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    v_u_MainFrame.BorderSizePixel = 0
    v_u_MainFrame.Parent = v_u_ScreenGui
    Instance.new("UICorner", v_u_MainFrame).CornerRadius = UDim.new(0, 12)

    local v_tb = v_u_CreateTitleBar(v_u_MainFrame)
    v_u_MakeDraggable(v_tb, v_u_MainFrame)

    local v_sf = Instance.new("ScrollingFrame")
    v_sf.Size = UDim2.new(1, -10, 1, -80)
    v_sf.Position = UDim2.new(0, 5, 0, 35)
    v_sf.BackgroundTransparency = 1
    v_sf.BorderSizePixel = 0
    v_sf.ScrollBarThickness = 3
    v_sf.CanvasSize = UDim2.new(0, 0, 0, 600)
    v_sf.Parent = v_u_MainFrame

    local v_list = Instance.new("UIListLayout")
    v_list.Padding = UDim.new(0, 5)
    v_list.Parent = v_sf

    -- Global references for UI
    _G.AutoFarm = v_u_AutoFarm
    _G.AutoClick = v_u_AutoClick
    _G.AutoSkill = v_u_AutoSkill
    _G.AutoEquip = v_u_AutoEquipToggle
    _G.AutoQuest = v_u_AutoQuest
    _G.AutoStats = v_u_AutoStats
    _G.SpeedBoost = v_u_SpeedBoost
    _G.MobFilter = v_u_MobFilter
    _G.Distance = v_u_Distance
    _G.MaxRange = v_u_MaxRange
    _G.SkillDelay = v_u_SkillDelay
    _G.SpeedValue = v_u_SpeedValue
    _G.Melee = v_u_Melee
    _G.Sword = v_u_Sword
    _G.DevilFruit = v_u_DevilFruit
    _G.Defense = v_u_Defense
    _G.PositionMode = v_u_PositionMode

    v_u_CreateToggle(v_sf, "Auto Farm", "AutoFarm", Color3.fromRGB(100, 255, 100))
    v_u_CreateToggle(v_sf, "Auto Click", "AutoClick", Color3.fromRGB(255, 200, 100))
    v_u_CreateToggle(v_sf, "Auto Skill", "AutoSkill", Color3.fromRGB(255, 100, 100))
    v_u_CreateToggle(v_sf, "Auto Equip", "AutoEquip", Color3.fromRGB(150, 150, 255))
    v_u_CreateToggle(v_sf, "Auto Quest", "AutoQuest", Color3.fromRGB(100, 200, 255))
    v_u_CreateToggle(v_sf, "Auto Stats", "AutoStats", Color3.fromRGB(255, 255, 100))
    v_u_CreateToggle(v_sf, "Speed Boost", "SpeedBoost", Color3.fromRGB(100, 255, 255))

    local v_skf = Instance.new("Frame")
    v_skf.Size = UDim2.new(1, 0, 0, 40)
    v_skf.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    v_skf.BorderSizePixel = 0
    v_skf.Parent = v_sf
    Instance.new("UICorner", v_skf).CornerRadius = UDim.new(0, 6)

    local v_skl = Instance.new("TextLabel")
    v_skl.Size = UDim2.new(0.3, 0, 1, 0)
    v_skl.Position = UDim2.new(0, 8, 0, 0)
    v_skl.BackgroundTransparency = 1
    v_skl.Text = "Skills:"
    v_skl.TextColor3 = Color3.fromRGB(255, 255, 255)
    v_skl.TextSize = 12
    v_skl.Font = Enum.Font.Gotham
    v_skl.TextXAlignment = Enum.TextXAlignment.Left
    v_skl.Parent = v_skf

    v_u_CreateSkillButton(v_skf, "Z", 1)
    v_u_CreateSkillButton(v_skf, "X", 2)
    v_u_CreateSkillButton(v_skf, "C", 3)
    v_u_CreateSkillButton(v_skf, "V", 4)
    v_u_CreateSkillButton(v_skf, "F", 5)

    v_u_CreateInput(v_sf, "Mob Filter", "MobFilter", 0, 0)
    v_u_CreateInput(v_sf, "Distance", "Distance", 1, 15)
    v_u_CreateInput(v_sf, "Max Range", "MaxRange", 100, 2000)
    v_u_CreateInput(v_sf, "Skill Delay", "SkillDelay", 0.1, 5.0)
    v_u_CreateInput(v_sf, "Speed", "SpeedValue", 16, 500)
    v_u_CreateInput(v_sf, "Melee", "Melee", 0, 100)
    v_u_CreateInput(v_sf, "Sword", "Sword", 0, 100)
    v_u_CreateInput(v_sf, "Devil Fruit", "DevilFruit", 0, 100)
    v_u_CreateInput(v_sf, "Defense", "Defense", 0, 100)

    v_u_CreatePositionButton(v_sf)

    v_u_StatusText = Instance.new("TextLabel")
    v_u_StatusText.Size = UDim2.new(1, -10, 0, 20)
    v_u_StatusText.Position = UDim2.new(0, 5, 1, -25)
    v_u_StatusText.BackgroundTransparency = 1
    v_u_StatusText.Text = "Ready"
    v_u_StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    v_u_StatusText.TextSize = 11
    v_u_StatusText.Font = Enum.Font.Gotham
    v_u_StatusText.TextXAlignment = Enum.TextXAlignment.Left
    v_u_StatusText.Parent = v_u_MainFrame

    v_u_CreateOpenButton(v_u_ScreenGui, v_u_MainFrame)

    task.spawn(v_u_StartCacheRefresh)
    task.spawn(v_u_StartFarm)
    task.spawn(v_u_AutoQuestLoop)
    task.spawn(v_u_AutoStatsLoop)
    task.spawn(v_u_AntiAFKLoop)

    print("[Rock Farm Hub] Loaded successfully!")
    v_u_Notify("Rock Farm Hub Loaded!")
end

v_u_Init()
