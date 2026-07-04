script_content = '''local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")
local Backpack = Player:WaitForChild("Backpack")

local Config = {
    AutoFarm = false,
    AutoClick = false,
    AutoBring = false,
    AutoSkill = false,
    KillAll = false,
    AutoEquip = false,
    Distance = 5,
    PositionMode = "Back",
    MaxRange = 500,
    BringRange = 50,
    LoopSpeed = 0.2,
    CacheRefresh = 3,
    SkillCooldown = 1,
    MobFilter = "",
    Skills = {Z = false, X = false, C = false, V = false, Q = false, E = false, R = false, F = false},
    KillAllCooldown = 5,
}

local Cache = {Mobs = {}, ActionRemote = nil, LastRefresh = 0, LastSkillUse = {}, LastKillAll = 0}

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then warn("[AutoFarm]", result) end
    return success, result
end

local function IsValidTarget(mob)
    if not mob or not mob.Parent then return false end
    local humanoid = mob:FindFirstChild("Humanoid")
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end
    if humanoid.Health <= 0 then return false end
    if mob == Character then return false end
    if Players:GetPlayerFromCharacter(mob) then return false end
    return true
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetOffsetCFrame(targetCFrame, mode, distance)
    local offset = CFrame.new()
    if mode == "Back" then offset = CFrame.new(0, 0, distance)
    elseif mode == "Front" then offset = CFrame.new(0, 0, -distance)
    elseif mode == "Top" then offset = CFrame.new(0, distance, 0)
    elseif mode == "Bottom" then offset = CFrame.new(0, -distance, 0) end
    return targetCFrame * offset
end

local function FindMobs()
    local mobs = {}
    local searchRoot = workspace:FindFirstChild("Mobs") or workspace
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if IsValidTarget(obj) then
                if Config.MobFilter == "" or string.find(string.lower(obj.Name), string.lower(Config.MobFilter)) then
                    table.insert(mobs, obj)
                end
            end
        end
    end
    table.sort(mobs, function(a, b)
        return GetDistance(HRP.Position, a.HumanoidRootPart.Position) < GetDistance(HRP.Position, b.HumanoidRootPart.Position)
    end)
    return mobs
end

local function RefreshCache()
    local now = tick()
    if now - Cache.LastRefresh >= Config.CacheRefresh then
        Cache.Mobs = FindMobs()
        Cache.LastRefresh = now
    end
    return Cache.Mobs
end

local function GetNearestMob()
    local mobs = RefreshCache()
    for _, mob in ipairs(mobs) do
        if IsValidTarget(mob) then
            if GetDistance(HRP.Position, mob.HumanoidRootPart.Position) <= Config.MaxRange then return mob end
        end
    end
    return nil
end

local function TeleportToMob(mob)
    if not IsValidTarget(mob) then return end
    SafeCall(function()
        HRP.CFrame = GetOffsetCFrame(mob.HumanoidRootPart.CFrame, Config.PositionMode, Config.Distance)
    end)
end

local function ClickAttack()
    SafeCall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

local function SimulateKeyPress(key)
    SafeCall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function AutoEquipWeapon()
    if not Config.AutoEquip then return end
    if Character:FindFirstChildOfClass("Tool") then return end
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            SafeCall(function() Humanoid:EquipTool(tool) end)
            break
        end
    end
end

local function UseSkills()
    if not Config.AutoSkill then return end
    local now = tick()
    for key, enabled in pairs(Config.Skills) do
        if enabled then
            local lastUse = Cache.LastSkillUse[key] or 0
            if now - lastUse >= Config.SkillCooldown then
                SimulateKeyPress(Enum.KeyCode[key])
                Cache.LastSkillUse[key] = now
                task.wait(0.1)
            end
        end
    end
end

local function BringMob(mob)
    if not Config.AutoBring then return end
    if not IsValidTarget(mob) then return end
    if GetDistance(HRP.Position, mob.HumanoidRootPart.Position) > Config.BringRange then return end
    SafeCall(function()
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        if mobHRP then
            mobHRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -5)
            local vel = mobHRP:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            vel.Velocity = Vector3.new(0, 0, 0)
            vel.MaxForce = Vector3.new(4000, 4000, 4000)
            vel.Parent = mobHRP
            task.delay(0.1, function() if vel then vel:Destroy() end end)
        end
    end)
end

local function KillAllMobs()
    if not Config.KillAll then return end
    local now = tick()
    if now - Cache.LastKillAll < Config.KillAllCooldown then return end
    for _, mob in ipairs(FindMobs()) do
        SafeCall(function()
            local humanoid = mob:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then humanoid.Health = 0 end
        end)
    end
    Cache.LastKillAll = now
end

local function FarmLoop()
    task.spawn(function()
        while true do
            if Config.AutoFarm then
                local target = GetNearestMob()
                if target then
                    if _G.StatusLabel then _G.StatusLabel.Text = "Target: " .. target.Name end
                    AutoEquipWeapon()
                    TeleportToMob(target)
                    BringMob(target)
                    if Config.AutoClick then ClickAttack() end
                    UseSkills()
                else
                    if _G.StatusLabel then _G.StatusLabel.Text = "No target found" end
                end
            end
            task.wait(Config.LoopSpeed)
        end
    end)
end

local function KillAllLoop()
    task.spawn(function()
        while true do
            if Config.KillAll then KillAllMobs() end
            task.wait(Config.KillAllCooldown)
        end
    end)
end

-- ==========================================
-- UI SYSTEM
-- ==========================================
local function CreateUI()
    local CoreGui = game:GetService("CoreGui")
    local old = CoreGui:FindFirstChild("AutoFarmUI_Delta")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmUI_Delta"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = true

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(100, 100, 255)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Auto Farm"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 28, 0, 28)
    CloseButton.Position = UDim2.new(1, -32, 0, 3)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    CloseButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -80)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 40)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 3
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    ScrollFrame.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 6)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ScrollFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0, 22)
    StatusLabel.Position = UDim2.new(0, 5, 1, -28)
    StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    StatusLabel.Text = "Ready"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusLabel

    _G.StatusLabel = StatusLabel

    local function CreateToggle(parent, text, configKey, color)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 32)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Parent = parent

        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 8)
        ToggleCorner.Parent = ToggleFrame

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, 0, 1, 0)
        Label.Position = UDim2.new(0, 8, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 13
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ToggleFrame

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 45, 0, 22)
        Button.Position = UDim2.new(1, -52, 0.5, -11)
        Button.BackgroundColor3 = Config[configKey] and (color or Color3.fromRGB(100, 255, 100)) or Color3.fromRGB(100, 100, 100)
        Button.Text = Config[configKey] and "ON" or "OFF"
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 11
        Button.Font = Enum.Font.GothamBold
        Button.Parent = ToggleFrame

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 6)
        ButtonCorner.Parent = Button

        Button.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            Button.BackgroundColor3 = Config[configKey] and (color or Color3.fromRGB(100, 255, 100)) or Color3.fromRGB(100, 100, 100)
            Button.Text = Config[configKey] and "ON" or "OFF"
            StatusLabel.Text = text .. ": " .. (Config[configKey] and "ON" or "OFF")
            StatusLabel.TextColor3 = Config[configKey] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        end)

        return ToggleFrame
    end

    CreateToggle(ScrollFrame, "Auto Farm", "AutoFarm", Color3.fromRGB(100, 255, 100))
    CreateToggle(ScrollFrame, "Auto Click", "AutoClick", Color3.fromRGB(255, 200, 100))
    CreateToggle(ScrollFrame, "Auto Bring", "AutoBring", Color3.fromRGB(255, 150, 50))
    CreateToggle(ScrollFrame, "Auto Skill", "AutoSkill", Color3.fromRGB(255, 100, 100))
    CreateToggle(ScrollFrame, "Kill All", "KillAll", Color3.fromRGB(255, 50, 50))
    CreateToggle(ScrollFrame, "Auto Equip", "AutoEquip", Color3.fromRGB(150, 150, 255))

    -- Search Box
    local SearchFrame = Instance.new("Frame")
    SearchFrame.Size = UDim2.new(1, 0, 0, 32)
    SearchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    SearchFrame.BorderSizePixel = 0
    SearchFrame.Parent = ScrollFrame

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 8)
    SearchCorner.Parent = SearchFrame

    local SearchLabel = Instance.new("TextLabel")
    SearchLabel.Size = UDim2.new(0.25, 0, 1, 0)
    SearchLabel.Position = UDim2.new(0, 8, 0, 0)
    SearchLabel.BackgroundTransparency = 1
    SearchLabel.Text = "Mob:"
    SearchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchLabel.TextSize = 13
    SearchLabel.Font = Enum.Font.Gotham
    SearchLabel.TextXAlignment = Enum.TextXAlignment.Left
    SearchLabel.Parent = SearchFrame

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(0.65, 0, 0.7, 0)
    SearchBox.Position = UDim2.new(0.3, 0, 0.15, 0)
    SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    SearchBox.Text = Config.MobFilter
    SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.TextSize = 13
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = SearchFrame

    local SearchBoxCorner = Instance.new("UICorner")
    SearchBoxCorner.CornerRadius = UDim.new(0, 6)
    SearchBoxCorner.Parent = SearchBox

    SearchBox.FocusLost:Connect(function()
        Config.MobFilter = SearchBox.Text
        Cache.LastRefresh = 0
        StatusLabel.Text = "Filter: " .. (Config.MobFilter ~= "" and Config.MobFilter or "All")
    end)

    -- Distance
    local DistFrame = Instance.new("Frame")
    DistFrame.Size = UDim2.new(1, 0, 0, 45)
    DistFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    DistFrame.BorderSizePixel = 0
    DistFrame.Parent = ScrollFrame

    local DistCorner = Instance.new("UICorner")
    DistCorner.CornerRadius = UDim.new(0, 8)
    DistCorner.Parent = DistFrame

    local DistLabel = Instance.new("TextLabel")
    DistLabel.Size = UDim2.new(1, -10, 0, 18)
    DistLabel.Position = UDim2.new(0, 8, 0, 3)
    DistLabel.BackgroundTransparency = 1
    DistLabel.Text = "Distance: " .. Config.Distance
    DistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DistLabel.TextSize = 12
    DistLabel.Font = Enum.Font.Gotham
    DistLabel.TextXAlignment = Enum.TextXAlignment.Left
    DistLabel.Parent = DistFrame

    local DistBox = Instance.new("TextBox")
    DistBox.Size = UDim2.new(0.9, 0, 0, 20)
    DistBox.Position = UDim2.new(0.05, 0, 0, 20)
    DistBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    DistBox.Text = tostring(Config.Distance)
    DistBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    DistBox.TextSize = 12
    DistBox.Font = Enum.Font.Gotham
    DistBox.Parent = DistFrame

    local DistBoxCorner = Instance.new("UICorner")
    DistBoxCorner.CornerRadius = UDim.new(0, 6)
    DistBoxCorner.Parent = DistBox

    DistBox.FocusLost:Connect(function()
        local num = tonumber(DistBox.Text)
        if num and num >= 1 and num <= 15 then
            Config.Distance = num
            DistLabel.Text = "Distance: " .. Config.Distance
        end
    end)

    -- Position Mode
    local PosFrame = Instance.new("Frame")
    PosFrame.Size = UDim2.new(1, 0, 0, 32)
    PosFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    PosFrame.BorderSizePixel = 0
    PosFrame.Parent = ScrollFrame

    local PosCorner = Instance.new("UICorner")
    PosCorner.CornerRadius = UDim.new(0, 8)
    PosCorner.Parent = PosFrame

    local PosLabel = Instance.new("TextLabel")
    PosLabel.Size = UDim2.new(0.25, 0, 1, 0)
    PosLabel.Position = UDim2.new(0, 8, 0, 0)
    PosLabel.BackgroundTransparency = 1
    PosLabel.Text = "Pos:"
    PosLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PosLabel.TextSize = 13
    PosLabel.Font = Enum.Font.Gotham
    PosLabel.TextXAlignment = Enum.TextXAlignment.Left
    PosLabel.Parent = PosFrame

    local PosButton = Instance.new("TextButton")
    PosButton.Size = UDim2.new(0.65, 0, 0.7, 0)
    PosButton.Position = UDim2.new(0.3, 0, 0.15, 0)
    PosButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    PosButton.Text = Config.PositionMode
    PosButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PosButton.TextSize = 13
    PosButton.Font = Enum.Font.GothamBold
    PosButton.Parent = PosFrame

    local PosButtonCorner = Instance.new("UICorner")
    PosButtonCorner.CornerRadius = UDim.new(0, 6)
    PosButtonCorner.Parent = PosButton

    local modes = {"Back", "Front", "Top", "Bottom"}
    local modeIndex = 1
    for i, m in ipairs(modes) do if m == Config.PositionMode then modeIndex = i break end end

    PosButton.MouseButton1Click:Connect(function()
        modeIndex = modeIndex % #modes + 1
        Config.PositionMode = modes[modeIndex]
        PosButton.Text = Config.PositionMode
    end)

    -- Skills
    local SkillLabel = Instance.new("TextLabel")
    SkillLabel.Size = UDim2.new(1, 0, 0, 20)
    SkillLabel.BackgroundTransparency = 1
    SkillLabel.Text = "Skills (Z,X,C,V,Q,E,R,F)"
    SkillLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    SkillLabel.TextSize = 12
    SkillLabel.Font = Enum.Font.GothamBold
    SkillLabel.Parent = ScrollFrame

    local SkillFrame = Instance.new("Frame")
    SkillFrame.Size = UDim2.new(1, 0, 0, 35)
    SkillFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    SkillFrame.BorderSizePixel = 0
    SkillFrame.Parent = ScrollFrame

    local SkillCorner = Instance.new("UICorner")
    SkillCorner.CornerRadius = UDim.new(0, 8)
    SkillCorner.Parent = SkillFrame

    local skillKeys = {"Z", "X", "C", "V", "Q", "E", "R", "F"}
    for i, key in ipairs(skillKeys) do
        local SkillBtn = Instance.new("TextButton")
        SkillBtn.Size = UDim2.new(0, 28, 0, 28)
        SkillBtn.Position = UDim2.new(0, 4 + (i - 1) * 34, 0.5, -14)
        SkillBtn.BackgroundColor3 = Config.Skills[key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        SkillBtn.Text = key
        SkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        SkillBtn.TextSize = 11
        SkillBtn.Font = Enum.Font.GothamBold
        SkillBtn.Parent = SkillFrame

        local SkillBtnCorner = Instance.new("UICorner")
        SkillBtnCorner.CornerRadius = UDim.new(0, 6)
        SkillBtnCorner.Parent = SkillBtn

        SkillBtn.MouseButton1Click:Connect(function()
            Config.Skills[key] = not Config.Skills[key]
            SkillBtn.BackgroundColor3 = Config.Skills[key] and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 100)
        end)
    end

    -- Draggable
    local dragging = false
    local dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Open Button
    local OpenButton = Instance.new("TextButton")
    OpenButton.Name = "OpenBtn"
    OpenButton.Size = UDim2.new(0, 50, 0, 50)
    OpenButton.Position = UDim2.new(0, 10, 0, 10)
    OpenButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    OpenButton.Text = "AF"
    OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenButton.TextSize = 18
    OpenButton.Font = Enum.Font.GothamBold
    OpenButton.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(1, 0)
    OpenCorner.Parent = OpenButton

    OpenButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    print("UI Created Successfully!")
    return ScreenGui
end

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local gui = game:GetService("CoreGui"):FindFirstChild("AutoFarmUI_Delta")
        if gui then
            local mf = gui:FindFirstChild("MainFrame")
            if mf then mf.Visible = not mf.Visible end
        end
    end
end)

-- Init
local function Initialize()
    repeat task.wait() until Player.Character
    repeat task.wait() until Player.Character:FindFirstChild("HumanoidRootPart")
    CreateUI()
    FarmLoop()
    KillAllLoop()
    print("Auto Farm Loaded!")
end

Initialize()
'''

output_path = '/mnt/agents/output/roblox_auto_farm_working.lua'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(script_content)

print(f"Working script saved!")
print(f"Lines: {len(script_content.splitlines())}")
print(f"Chars: {len(script_content)}")
