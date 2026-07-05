--[[
	==========================================================
	  ROCK FARM HUB  |  Auto Farm for Roblox "Rock Fruit"
	  Language : Lua (LuaU)
	  Platform : Executor (Synapse / Krnl / Delta / Fluxus ...)
	  Structure: 12 departments / 48 functions
	----------------------------------------------------------
	  Confirmed from scraped game code:
	    * Action remote  -> ReplicatedStorage.Remotes.Action
	    * Fire pattern   -> Action:FireServer("Misc", "<action>")
	    * NetworkFramework lives in ReplicatedStorage.Modules
	  Everything the game does NOT confirm is guessed with a
	  safe fallback so the script never hard-crashes.
	==========================================================
]]

--==========================================================
-- DEPT 1: CORE SYSTEM
--==========================================================

-- 1.1 Services
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInputManager= game:GetService("VirtualInputManager")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local Debris             = game:GetService("Debris")

-- 1.2 Player / Character references
local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, HRP, Backpack

local function BindCharacter(char)
	Character = char
	Humanoid  = char:WaitForChild("Humanoid")
	HRP       = char:WaitForChild("HumanoidRootPart")
	Backpack  = LocalPlayer:WaitForChild("Backpack")
end
BindCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

-- 1.3 Config Variables (shared via _G so the UI can reach them)
_G.RockFarm = _G.RockFarm or {
	AutoFarm    = false,
	AutoClick   = false,
	AutoSkill   = false,
	AutoEquip   = false,
	AutoQuest   = false,
	AutoStats   = false,
	SpeedBoost  = false,

	Distance     = 5,          -- studs offset from mob
	PositionMode = "Back",     -- Back / Front / Top / Bottom
	MaxRange     = 2000,       -- max distance to consider a mob
	MobFilter    = "",         -- name substring filter, "" = any
	SkillDelay   = 0.5,        -- seconds between skill presses
	SpeedValue   = 80,         -- WalkSpeed when SpeedBoost on

	QuestMaxLevel = 0,         -- 0 = auto (use my own level); otherwise hard cap
	QuestName     = "",        -- optional: only accept quests whose Name attribute matches (substring)

	Stats  = { Melee = 0, Sword = 0, DevilFruit = 0, Defense = 0 },
	Skills = { "Z", "X", "C", "V", "F" },

	Kills  = 0,
	Target = "None",
}
local Cfg = _G.RockFarm

-- 1.4 SafeCall - pcall wrapper
local function SafeCall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[RockFarm] "..tostring(err))
	end
	return ok
end

-- 1.5 GetGuiParent - CoreGui with PlayerGui fallback
local function GetGuiParent()
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then
		if gethui then return gethui() end
		return cg
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- forward declares for Notify / status (defined with UI)
local Notify, UpdateStatus

-- runtime: when a quest is active, this holds the mob name from Frame_Quest.Title
-- so Auto Farm only hits the quest target instead of any nearby mob.
local _questMobName = nil

--==========================================================
-- DEPT 2: MOB DETECTION
--==========================================================
local MobsCache = {}

-- 2.4 GetDist
local function GetDist(p1, p2)
	return (p1 - p2).Magnitude
end

-- 2.1 IsValidTarget
local function IsValidTarget(mob)
	if not mob or mob == Character then return false end
	if Players:GetPlayerFromCharacter(mob) then return false end -- not another player
	local hum = mob:FindFirstChildOfClass("Humanoid")
	local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChild("UpperTorso")
	if not (hum and root) then return false end
	if hum.Health <= 0 then return false end
	-- when a quest is active, only target the mob named in the quest
	if _questMobName and _questMobName ~= "" then
		if not string.find(string.lower(mob.Name), string.lower(_questMobName)) then
			return false
		end
	end
	if Cfg.MobFilter ~= "" and not string.find(string.lower(mob.Name), string.lower(Cfg.MobFilter)) then
		return false
	end
	return true
end

-- 2.2 FindMobs - search likely folders then fall back to full workspace
local MOB_FOLDERS = { "Mobs", "Enemies", "NPCs", "Mob", "Map" }
local function FindMobs()
	local found = {}
	local searched = false
	for _, name in ipairs(MOB_FOLDERS) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			searched = true
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("Model") and IsValidTarget(obj) then
					table.insert(found, obj)
				end
			end
		end
	end
	if not searched or #found == 0 then -- fallback: scan everything
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and IsValidTarget(obj) then
				table.insert(found, obj)
			end
		end
	end
	return found
end

-- 2.5 Mob Cache refresh
local function RefreshCache()
	MobsCache = FindMobs()
end

-- 2.3 GetNearest from cache
local function GetNearest()
	local best, bestDist = nil, Cfg.MaxRange
	for _, mob in ipairs(MobsCache) do
		if IsValidTarget(mob) then
			local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChild("UpperTorso")
			if root and HRP then
				local d = GetDist(HRP.Position, root.Position)
				if d < bestDist then
					best, bestDist = mob, d
				end
			end
		end
	end
	return best
end

--==========================================================
-- DEPT 3: MOVEMENT
--==========================================================

-- 3.1 GetOffset
local function GetOffset(cf, mode, dist)
	if mode == "Front"  then return cf * CFrame.new(0, 0, -dist) end
	if mode == "Top"    then return cf * CFrame.new(0,  dist, 0) end
	if mode == "Bottom" then return cf * CFrame.new(0, -dist, 0) end
	return cf * CFrame.new(0, 0, dist) -- Back (default)
end

-- 3.2 Teleport
local function Teleport(target)
	local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
	if root and HRP then
		HRP.CFrame = GetOffset(root.CFrame, Cfg.PositionMode, Cfg.Distance)
	end
end

-- 3.3 ApplySpeed
local function ApplySpeed()
	if Humanoid then Humanoid.WalkSpeed = Cfg.SpeedValue end
end

-- 3.4 ResetSpeed
local function ResetSpeed()
	if Humanoid then Humanoid.WalkSpeed = 16 end
end

--==========================================================
-- DEPT 4: COMBAT
--==========================================================
local ActionRemote = nil

-- 4.1 FindActionRemote (confirmed path first, then discovery)
local function FindActionRemote()
	-- confirmed from scraped code: ReplicatedStorage.Remotes.Action
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local act = remotes:FindFirstChild("Action")
		if act and act:IsA("RemoteEvent") then
			ActionRemote = act
			return act
		end
	end
	-- fallback: sleitnick net package
	local pkgs = ReplicatedStorage:FindFirstChild("Packages")
	if pkgs then
		for _, obj in ipairs(pkgs:GetDescendants()) do
			if obj:IsA("RemoteEvent") and string.find(string.lower(obj.Name), "action") then
				ActionRemote = obj
				return obj
			end
		end
	end
	-- last resort: scan RS for anything combat-ish
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local n = string.lower(obj.Name)
			if n:find("action") or n:find("attack") or n:find("combat") or n:find("m1") then
				ActionRemote = obj
				return obj
			end
		end
	end
	return nil
end

-- 4.2 AttackFallback
local function AttackFallback()
	if ActionRemote then
		-- scraped fire pattern uses ("Misc", "<action>"); M1 combat uses ("M1","Combat")
		SafeCall(function() ActionRemote:FireServer("M1", "Combat") end)
	else
		SafeCall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton1(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		end)
	end
end

--==========================================================
-- DEPT 5: WEAPON
--==========================================================

-- 5.1 AutoEquip
local function AutoEquip()
	if not Character then return end
	if Character:FindFirstChildOfClass("Tool") then return end -- already holding one
	local tool = Backpack and Backpack:FindFirstChildOfClass("Tool")
	if tool and Humanoid then
		SafeCall(function() Humanoid:EquipTool(tool) end)
	end
end

--==========================================================
-- DEPT 6: SKILL
--==========================================================

-- 6.1 PressSkill (press + release; release is mandatory)
local function PressSkill(key)
	local code = Enum.KeyCode[key]
	if not code then return end
	SafeCall(function()
		VirtualInputManager:SendKeyEvent(true,  code, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, code, false, game)
	end)
end

-- 6.2 AutoSkillLoop is driven by a thread (Dept 11). Helper below:
local _lastSkill = 0
local function TrySkills()
	if tick() - _lastSkill < Cfg.SkillDelay then return end
	_lastSkill = tick()
	for _, key in ipairs(Cfg.Skills) do
		PressSkill(key)
		task.wait(0.05)
	end
end

--==========================================================
-- DEPT 7: AUTO QUEST
--==========================================================

-- 7.0 QuestRemote / QuestHandler discovery
-- Confirmed structure: workspace.NpcQuest holds NPC_Quest1..N + a "QuestHandler".
-- Prompts live in a separate workspace.NpcPrompt folder.
local QuestRemote = nil
local function FindQuestRemote()
	local scan = {}
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then for _, o in ipairs(remotes:GetDescendants()) do scan[#scan+1] = o end end
	for _, o in ipairs(ReplicatedStorage:GetDescendants()) do scan[#scan+1] = o end
	for _, obj in ipairs(scan) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local n = string.lower(obj.Name)
			if n:find("quest") or n:find("mission") or n:find("accept") or n:find("task") then
				QuestRemote = obj
				return obj
			end
		end
	end
	return nil
end

-- helper: get any usable part to teleport to (these NPCs use Head as PrimaryPart)
local function GetNpcRoot(model)
	return model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Head")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChildWhichIsA("BasePart")
end

-- helper: find the ProximityPrompt tied to an NPC.
-- Checks inside the NPC first, then the shared workspace.NpcPrompt folder.
local function FindPromptFor(npc)
	local p = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
	if p then return p end
	local promptFolder = workspace:FindFirstChild("NpcPrompt")
	if promptFolder then
		-- try a prompt whose parent/ancestor name matches the NPC
		for _, obj in ipairs(promptFolder:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				local anc = obj:FindFirstAncestorOfClass("Model")
				if anc and anc.Name == npc.Name then return obj end
			end
		end
		-- otherwise just return the first prompt in the folder
		local any = promptFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
		if any then return any end
	end
	return nil
end

-- 7.0b GetMyLevel - reads player level from the HUD LevelText ("Lv. 1359")
-- Path: PlayerGui.HUD.Main.Frame_Display.LevelText
local function GetMyLevel()
	local ok, lvl = pcall(function()
		local gui = LocalPlayer:FindFirstChild("PlayerGui")
		if not gui then return nil end
		local label = gui:FindFirstChild("HUD")
		label = label and label:FindFirstChild("Main")
		label = label and label:FindFirstChild("Frame_Display")
		label = label and label:FindFirstChild("LevelText")
		if not label then return nil end
		local txt = label.ContentText or label.Text or ""
		return tonumber((txt:gsub("%D", ""))) -- strip everything but digits
	end)
	if ok and lvl then return lvl end
	return nil
end

-- 7.0c Quest HUD state
-- Frame_Quest.Visible  -> true when a quest is currently accepted/active
-- Frame_Quest.Title    -> name of the mob to hunt for the active quest (e.g. "Bacon Strong")
local function GetQuestFrame()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	local hud = gui and gui:FindFirstChild("HUD")
	local main = hud and hud:FindFirstChild("Main")
	return main and main:FindFirstChild("Frame_Quest")
end

-- returns: isActive (bool), mobName (string or nil)
local function GetActiveQuest()
	local ok, active, name = pcall(function()
		local fq = GetQuestFrame()
		if not fq then return false, nil end
		local vis = fq.Visible
		local title = fq:FindFirstChild("Title")
		local txt = title and (title.ContentText or title.Text) or nil
		if txt == "" then txt = nil end
		return vis, txt
	end)
	if ok then return active, name end
	return false, nil
end

-- 7.1 FindQuestNPC - targets workspace.NpcQuest and NPC_Quest* models.
local _questIdx = 1
local function FindQuestNPC()
	local list = {}
	local folder = workspace:FindFirstChild("NpcQuest")
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("Model") and m.Name ~= "QuestHandler" then
				table.insert(list, m)
			end
		end
	end
	-- fallback: scan workspace for NPC_Quest* if the folder name differs
	if #list == 0 then
		for _, m in ipairs(workspace:GetDescendants()) do
			if m:IsA("Model") and string.find(string.lower(m.Name), "quest") then
				table.insert(list, m)
			end
		end
	end
	-- apply Level / Name attribute filters
	-- cap = manual QuestMaxLevel if set (>0), otherwise auto-use my own HUD level
	local cap = Cfg.QuestMaxLevel
	if cap <= 0 then cap = GetMyLevel() or 0 end
	local eligible = {}
	for _, m in ipairs(list) do
		local lvl  = m:GetAttribute("Level")
		local qname = m:GetAttribute("Name")
		local okLevel = true
		if cap > 0 and lvl and lvl > cap then
			okLevel = false
		end
		local okName = true
		if Cfg.QuestName ~= "" then
			okName = qname ~= nil and string.find(string.lower(tostring(qname)), string.lower(Cfg.QuestName)) ~= nil
		end
		if okLevel and okName then
			table.insert(eligible, m)
		end
	end
	if #eligible == 0 then return nil end
	-- rotate through eligible NPCs so we don't get stuck on one
	if _questIdx > #eligible then _questIdx = 1 end
	local npc = eligible[_questIdx]
	_questIdx += 1
	local root = GetNpcRoot(npc)
	if not root then return nil end
	Cfg.Target = ("Quest: %s (Lv %s)"):format(tostring(npc:GetAttribute("Name") or npc.Name), tostring(npc:GetAttribute("Level") or "?"))
	if UpdateStatus then UpdateStatus() end
	return npc, FindPromptFor(npc), root
end

-- 7.2 TriggerQuest - teleport to Head, fire prompt, and poke the quest remote
local function TriggerQuest(npc, prompt, root)
	if HRP and root then
		HRP.CFrame = root.CFrame * CFrame.new(0, 0, 4)
		task.wait(0.4)
	end
	if prompt and prompt:IsA("ProximityPrompt") and fireproximityprompt then
		SafeCall(function() fireproximityprompt(prompt, 0) end)
	end
	if QuestRemote then
		SafeCall(function()
			if QuestRemote:IsA("RemoteFunction") then
				QuestRemote:InvokeServer(npc and npc.Name)
			else
				QuestRemote:FireServer(npc and npc.Name)
			end
		end)
	end
end

-- 7.3 AutoQuestLoop -> thread (Dept 11)

--==========================================================
-- DEPT 8: AUTO STATS
--==========================================================
local StatRemote = nil

-- 8.1 FindStatRemote
local function FindStatRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		for _, obj in ipairs(remotes:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				local n = string.lower(obj.Name)
				if n:find("stat") or n:find("point") or n:find("allocate") or n:find("upgrade") then
					StatRemote = obj
					return obj
				end
			end
		end
	end
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local n = string.lower(obj.Name)
			if n:find("stat") or n:find("point") or n:find("allocate") or n:find("upgrade") then
				StatRemote = obj
				return obj
			end
		end
	end
	return nil
end

-- 8.2 AllocateStats
local function AllocateStats()
	if not StatRemote then return end
	for statName, amount in pairs(Cfg.Stats) do
		if amount and amount > 0 then
			SafeCall(function()
				if StatRemote:IsA("RemoteFunction") then
					StatRemote:InvokeServer(statName, amount)
				else
					StatRemote:FireServer(statName, amount)
				end
			end)
		end
	end
end

-- 8.3 AutoStatsLoop -> thread (Dept 11)

--==========================================================
-- DEPT 9: BACKGROUND
--==========================================================
local _trackedMob = nil

-- 9.3 TrackKill
local function TrackKill(target)
	_trackedMob = target
end

-- 9.4 CheckKills
local function CheckKills()
	if _trackedMob then
		local hum = _trackedMob:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			Cfg.Kills += 1
			_trackedMob = nil
			if UpdateStatus then UpdateStatus() end
		end
	end
end

-- 9.2 OnCharacterAdded
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	BindCharacter(char)
end)

-- 9.1 AntiAFKLoop -> thread (Dept 11)

--==========================================================
-- DEPT 10: UI / GUI
--==========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RockFarmHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GetGuiParent()

-- helpers ------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

-- 10.2 MainFrame
local Main = mk("Frame", {
	Size = UDim2.new(0, 320, 0, 440),
	Position = UDim2.new(0.5, -160, 0.5, -220),
	BackgroundColor3 = Color3.fromRGB(24, 24, 30),
	BorderSizePixel = 0,
	Visible = true,
}, ScreenGui)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, Main)
mk("UIStroke", { Color = Color3.fromRGB(60, 60, 80), Thickness = 1 }, Main)

-- 10.3 TitleBar + gradient + X
local Title = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = Color3.fromRGB(40, 40, 55),
	BorderSizePixel = 0,
}, Main)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, Title)
mk("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(90, 60, 200), Color3.fromRGB(60, 160, 220)),
	Rotation = 15,
}, Title)
mk("TextLabel", {
	Size = UDim2.new(1, -40, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "Rock Farm Hub",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
}, Title)
local closeBtn = mk("TextButton", {
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -32, 0, 4),
	BackgroundColor3 = Color3.fromRGB(200, 60, 60),
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, Title)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

-- 10.4 ScrollingFrame
local Scroll = mk("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -80),
	Position = UDim2.new(0, 8, 0, 44),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)
mk("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, Scroll)

-- 10.9 Status Label
local StatusLabel = mk("TextLabel", {
	Size = UDim2.new(1, -16, 0, 28),
	Position = UDim2.new(0, 8, 1, -34),
	BackgroundColor3 = Color3.fromRGB(35, 35, 45),
	Text = "Target: None | Kills: 0",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(200, 200, 210),
}, Main)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, StatusLabel)

-- 1.7 UpdateStatus (real definition)
UpdateStatus = function()
	StatusLabel.Text = ("Target: %s | Kills: %d"):format(Cfg.Target, Cfg.Kills)
end

-- 1.6 Notify (real definition)
Notify = function(text)
	local n = mk("TextLabel", {
		Size = UDim2.new(0, 240, 0, 34),
		Position = UDim2.new(0.5, -120, 0, 10),
		BackgroundColor3 = Color3.fromRGB(40, 40, 55),
		Text = tostring(text),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}, ScreenGui)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, n)
	task.delay(2.5, function() n:Destroy() end)
end

-- toggle colors
local TOGGLE_COLORS = {
	AutoFarm   = Color3.fromRGB(100, 255, 100),
	AutoClick  = Color3.fromRGB(255, 200, 100),
	AutoSkill  = Color3.fromRGB(255, 100, 100),
	AutoEquip  = Color3.fromRGB(150, 150, 255),
	AutoQuest  = Color3.fromRGB(100, 200, 255),
	AutoStats  = Color3.fromRGB(255, 255, 100),
	SpeedBoost = Color3.fromRGB(100, 255, 255),
}
local OFF_COLOR = Color3.fromRGB(100, 100, 100)

-- 10.11 Hover effect helper
local function addHover(btn, base)
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.15)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = base
	end)
end

-- 10.5 Toggle Buttons (7)
local order = 0
local function nextOrder() order += 1 return order end

local function makeToggle(label, key)
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = OFF_COLOR,
		Text = label .. " : OFF",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(20, 20, 20),
		LayoutOrder = nextOrder(),
	}, Scroll)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
	local function render()
		if Cfg[key] then
			btn.BackgroundColor3 = TOGGLE_COLORS[key]
			btn.Text = label .. " : ON"
		else
			btn.BackgroundColor3 = OFF_COLOR
			btn.Text = label .. " : OFF"
		end
	end
	btn.MouseButton1Click:Connect(function()
		Cfg[key] = not Cfg[key]
		render()
		if key == "SpeedBoost" then
			if Cfg.SpeedBoost then ApplySpeed() else ResetSpeed() end
		end
	end)
	render()
	return btn
end

makeToggle("Auto Farm",  "AutoFarm")
makeToggle("Auto Click", "AutoClick")
makeToggle("Auto Skill", "AutoSkill")
makeToggle("Auto Equip", "AutoEquip")
makeToggle("Auto Quest", "AutoQuest")
makeToggle("Auto Stats", "AutoStats")
makeToggle("Speed Boost","SpeedBoost")

-- 10.6 Skill Buttons (5) - toggle which keys AutoSkill presses
local skillHolder = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
}, Scroll)
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, skillHolder)

local activeSkills = { Z = true, X = true, C = true, V = true, F = true }
local function rebuildSkillList()
	local list = {}
	for _, k in ipairs({ "Z", "X", "C", "V", "F" }) do
		if activeSkills[k] then table.insert(list, k) end
	end
	Cfg.Skills = list
end
for _, key in ipairs({ "Z", "X", "C", "V", "F" }) do
	local sb = mk("TextButton", {
		Size = UDim2.new(0, 52, 1, 0),
		BackgroundColor3 = TOGGLE_COLORS.AutoSkill,
		Text = key,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(20, 20, 20),
	}, skillHolder)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, sb)
	sb.MouseButton1Click:Connect(function()
		activeSkills[key] = not activeSkills[key]
		sb.BackgroundColor3 = activeSkills[key] and TOGGLE_COLORS.AutoSkill or OFF_COLOR
		rebuildSkillList()
	end)
end

-- 10.7 Input Boxes (9)
local function makeInput(label, default, apply)
	local holder = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(35, 35, 45),
		LayoutOrder = nextOrder(),
	}, Scroll)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, holder)
	mk("TextLabel", {
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 210),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	local box = mk("TextBox", {
		Size = UDim2.new(0.4, -8, 0.7, 0),
		Position = UDim2.new(0.6, 0, 0.15, 0),
		BackgroundColor3 = Color3.fromRGB(50, 50, 65),
		Text = tostring(default),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ClearTextOnFocus = false,
	}, holder)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
	box.FocusLost:Connect(function()
		apply(box.Text)
	end)
end

makeInput("Mob Filter", Cfg.MobFilter, function(t) Cfg.MobFilter = t end)
makeInput("Distance",   Cfg.Distance,  function(t) Cfg.Distance = tonumber(t) or Cfg.Distance end)
makeInput("Max Range",  Cfg.MaxRange,  function(t) Cfg.MaxRange = tonumber(t) or Cfg.MaxRange end)
makeInput("Skill Delay",Cfg.SkillDelay,function(t) Cfg.SkillDelay = tonumber(t) or Cfg.SkillDelay end)
makeInput("Speed Value",Cfg.SpeedValue,function(t) Cfg.SpeedValue = tonumber(t) or Cfg.SpeedValue; if Cfg.SpeedBoost then ApplySpeed() end end)
makeInput("Quest Max Lv",Cfg.QuestMaxLevel,function(t) Cfg.QuestMaxLevel = tonumber(t) or 0 end) -- 0 = auto (my level)
makeInput("Quest Name",  Cfg.QuestName,     function(t) Cfg.QuestName = t end)
makeInput("Stat: Melee",      Cfg.Stats.Melee,      function(t) Cfg.Stats.Melee = tonumber(t) or 0 end)
makeInput("Stat: Sword",      Cfg.Stats.Sword,      function(t) Cfg.Stats.Sword = tonumber(t) or 0 end)
makeInput("Stat: DevilFruit", Cfg.Stats.DevilFruit, function(t) Cfg.Stats.DevilFruit = tonumber(t) or 0 end)
makeInput("Stat: Defense",    Cfg.Stats.Defense,    function(t) Cfg.Stats.Defense = tonumber(t) or 0 end)

-- 10.8 Position Button (cycles Back/Front/Top/Bottom)
local POS_MODES = { "Back", "Front", "Top", "Bottom" }
local posIdx = 1
local posBtn = mk("TextButton", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(70, 70, 90),
	Text = "Position: Back",
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	LayoutOrder = nextOrder(),
}, Scroll)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, posBtn)
posBtn.MouseButton1Click:Connect(function()
	posIdx = posIdx % #POS_MODES + 1
	Cfg.PositionMode = POS_MODES[posIdx]
	posBtn.Text = "Position: " .. Cfg.PositionMode
end)
addHover(posBtn, Color3.fromRGB(70, 70, 90))

-- 10.10 Open Button (top-left toggle for whole GUI)
local OpenBtn = mk("TextButton", {
	Size = UDim2.new(0, 44, 0, 44),
	Position = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = Color3.fromRGB(90, 60, 200),
	Text = "RF",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(255, 255, 255),
}, ScreenGui)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, OpenBtn)
OpenBtn.MouseButton1Click:Connect(function()
	Main.Visible = not Main.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	Main.Visible = false
end)

-- 10.12 Drag System
do
	local dragging, dragStart, startPos
	Title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

--==========================================================
-- DEPT 11: LOOP / THREAD (6 threads)
--==========================================================

-- 11.1 Cache Refresh (every 3s)
task.spawn(function()
	while task.wait(3) do
		SafeCall(RefreshCache)
	end
end)

-- 11.2 Auto Farm (every 0.2s)
-- Flow: if Auto Quest is ON and no quest is active -> go accept a quest FIRST.
--       once a quest is active -> read its Title and only farm that mob.
local _questAcceptCooldown = 0
task.spawn(function()
	while task.wait(0.2) do
		if Cfg.AutoFarm and Character and Humanoid and Humanoid.Health > 0 then
			local questActive, questMob = true, nil
			if Cfg.AutoQuest then
				questActive, questMob = GetActiveQuest()
			end

			if Cfg.AutoQuest and not questActive then
				-- no active quest: stop farming, go grab one (throttled)
				_questMobName = nil
				Cfg.Target = "Getting quest..."
				UpdateStatus()
				if tick() - _questAcceptCooldown >= 1.5 then
					_questAcceptCooldown = tick()
					local npc, prompt, root = FindQuestNPC()
					if npc then SafeCall(TriggerQuest, npc, prompt, root) end
				end
			else
				-- quest active (or Auto Quest off): farm. Lock onto the quest mob if we have one.
				_questMobName = questMob
				local mob = GetNearest()
				if mob then
					Cfg.Target = questMob and (mob.Name.." [quest]") or mob.Name
					TrackKill(mob)
					SafeCall(Teleport, mob)
					if Cfg.AutoClick then AttackFallback() end
					if Cfg.AutoSkill then TrySkills() end
					CheckKills()
				else
					Cfg.Target = questMob and ("No '"..questMob.."' nearby") or "None"
				end
				UpdateStatus()
			end
		elseif Cfg.AutoClick and not Cfg.AutoFarm then
			AttackFallback()
		end
		if Cfg.AutoEquip then SafeCall(AutoEquip) end
	end
end)

-- 11.3 Auto Quest safety net (every 5s) - accept a quest if none is active,
-- even when Auto Farm is off.
task.spawn(function()
	while task.wait(5) do
		if Cfg.AutoQuest and not Cfg.AutoFarm then
			local active = GetActiveQuest()
			if not active then
				local npc, prompt, root = FindQuestNPC()
				if npc then SafeCall(TriggerQuest, npc, prompt, root) end
			end
		end
	end
end)

-- 11.4 Auto Stats (every 2s)
task.spawn(function()
	while task.wait(2) do
		if Cfg.AutoStats then SafeCall(AllocateStats) end
	end
end)

-- 11.5 Anti-AFK (every 60s)
task.spawn(function()
	while task.wait(60) do
		SafeCall(function()
			VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		end)
	end
end)

-- also patch the classic idle-kick signal if available
SafeCall(function()
	LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

-- 11.6 SpeedBoost keeper (re-applies WalkSpeed if the game resets it)
task.spawn(function()
	while task.wait(0.5) do
		if Cfg.SpeedBoost and Humanoid and Humanoid.WalkSpeed ~= Cfg.SpeedValue then
			ApplySpeed()
		end
	end
end)

--==========================================================
-- DEPT 12: INIT
--==========================================================
local function Init()
	-- 1. character already loaded via BindCharacter
	-- 2. cache remotes
	FindActionRemote()
	FindStatRemote()
	FindQuestRemote()
	-- 3. UI already built above
	-- 4. first cache fill
	RefreshCache()
	UpdateStatus()
	-- 5. notify
	local combatMode = ActionRemote and ("Remote: " .. ActionRemote.Name) or "VirtualUser fallback"
	Notify("Rock Farm Hub loaded (" .. combatMode .. ")")
	if not fireproximityprompt then
		Notify("fireproximityprompt missing - Auto Quest disabled")
	end
end

Init()
