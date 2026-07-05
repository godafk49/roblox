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

-- 1.0 Teardown - remove any UI left over from a previous run so re-executing
-- always shows the NEW interface instead of stacking / showing the old panel.
do
	-- old hand-built GUI (had ResetOnSpawn=false, so it survives between runs)
	for _, root in ipairs({ game:FindFirstChild("CoreGui"), Players.LocalPlayer:FindFirstChild("PlayerGui") }) do
		if root then
			for _, gui in ipairs(root:GetChildren()) do
				if gui.Name == "RockFarmHub" or gui.Name == "Rayfield" then
					pcall(function() gui:Destroy() end)
				end
			end
		end
	end
	-- destroy a previous Rayfield instance if the library exposed one
	if getgenv and getgenv().RockFarmRayfield then
		pcall(function() getgenv().RockFarmRayfield:Destroy() end)
	end
end

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

	GeppoEnabled  = true,      -- air-jump (Space) via Action:FireServer("Misc","geppo")
	DashEnabled   = true,      -- dash (Q) via Action:FireServer("Misc","dash")
	InfiniteGeppo = false,     -- ignore the game's air-jump limit (spam freely)
	DashSpeed     = 120,       -- studs/sec for dash (game default 120)

	EquipChoice   = "",        -- "" = first tool found; else exact tool name from dropdown

	LayDown       = false,     -- when Warp Position = Top, lie the character flat over the mob

	QuestSkipMismatch = true,  -- if an active quest's level is above mine, cancel/drop it

	IslandHop     = false,     -- warp island->island when idle (no mobs found)
	IdleHopSeconds = 5,        -- seconds of no movement before hopping to next island

	Stats  = { Melee = 0, Sword = 0, Power = 0, Defense = 0 },
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
-- runtime: current mob the farm loop has locked onto (glued to every frame by Heartbeat)
local _farmTarget = nil

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

-- 2.2 FindMobs - search likely folders then fall back to full workspace.
-- Includes workspace.island (where this game's mobs live).
local MOB_FOLDERS = { "island", "Island", "Mobs", "Enemies", "NPCs", "Mob", "Map" }
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

-- 2.3 GetNearest from cache (ignores MaxRange when a quest is active, so we'll
-- travel across the map to reach the quest mob even if it's far away)
local function GetNearest()
	local hardCap = (_questMobName and _questMobName ~= "") and math.huge or Cfg.MaxRange
	local best, bestDist = nil, hardCap
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

-- 3.0 ISLAND HOPPING
-- If we haven't moved for IdleHopSeconds (no mob found on this island),
-- warp to the next island to look for mobs there. Cycles through all 12.
local ISLANDS = {
	"Starter island", "Snow island", "Rock island", "Port Island",
	"Marine island", "Lava island", "Forest island", "Fishing island",
	"Event Island", "Crystal island", "Clown island", "Boss island",
}
local _islandIdx = 0
local _lastMovePos = nil
local _lastMoveTime = 0

-- get a teleport CFrame for an island by name (uses PrimaryPart / first BasePart)
local function GetIslandCFrame(name)
	local root = workspace:FindFirstChild("island") or workspace:FindFirstChild("Island")
	if not root then return nil end
	local isle = root:FindFirstChild(name)
	if not isle then return nil end
	if isle:IsA("Model") then
		local ok, cf = pcall(function() return isle:GetPivot() end)
		if ok and cf then return cf end
		if isle.PrimaryPart then return isle.PrimaryPart.CFrame end
	end
	local part = isle:IsA("BasePart") and isle or isle:FindFirstChildWhichIsA("BasePart", true)
	if part then return part.CFrame end
	return nil
end

-- warp to the next island in the list (skips ones that don't exist)
local function HopToNextIsland()
	for _ = 1, #ISLANDS do
		_islandIdx = _islandIdx % #ISLANDS + 1
		local name = ISLANDS[_islandIdx]
		local cf = GetIslandCFrame(name)
		if cf and HRP then
			HRP.CFrame = cf + Vector3.new(0, 8, 0) -- lift a bit so we don't clip into ground
			Cfg.Target = "Searching: " .. name
			if UpdateStatus then UpdateStatus() end
			if Notify then Notify("Hopping to " .. name) end
			return true
		end
	end
	return false
end

-- called every farm tick: returns true if we just hopped (so caller can skip a beat)
local function CheckIdleHop()
	if not (Cfg.IslandHop and HRP) then return false end
	local pos = HRP.Position
	if not _lastMovePos or (pos - _lastMovePos).Magnitude > 4 then
		_lastMovePos = pos
		_lastMoveTime = tick()
		return false
	end
	if tick() - _lastMoveTime >= Cfg.IdleHopSeconds then
		_lastMoveTime = tick() -- reset so we don't spam
		HopToNextIsland()
		return true
	end
	return false
end

-- 3.1 GetOffset
-- Top + LayDown: instead of hovering high, we PRESS DOWN flat onto the mob so our
-- hitbox overlaps theirs for the best possible hits (character lies horizontal,
-- face-down, sitting right on the enemy).
local function GetOffset(cf, mode, dist)
	if mode == "Front"  then return cf * CFrame.new(0, 0, -dist) end
	if mode == "Top" then
		if Cfg.LayDown then
			-- lie flat, pressed down onto the mob (small +Y so we sit on top, then tilt down)
			return CFrame.new(cf.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
		end
		return cf * CFrame.new(0, dist, 0)
	end
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
-- DEPT 4.5: MOVEMENT ABILITIES (Geppo + Dash)
-- Replicated 1:1 from the scraped ClientEvent script:
--   Geppo -> Action:FireServer("Misc","geppo"); HRP velocity Y = 100
--   Dash  -> Action:FireServer("Misc","dash");  BodyVelocity LookVector * speed
--==========================================================
local _geppoCount   = 0
local _lastGeppo    = 0
local _lastDash     = 0
local _dashCooldown = 0.3

-- reset air-jump counter on landing (scraped: Landed sets count = 0)
do
	local function hookLanded()
		if Humanoid then
			Humanoid.StateChanged:Connect(function(_, new)
				if new == Enum.HumanoidStateType.Landed then
					_geppoCount = 0
				end
			end)
		end
	end
	hookLanded()
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.6)
		hookLanded()
	end)
end

local function Geppo()
	if not (Cfg.GeppoEnabled and HRP and Humanoid and ActionRemote) then return end
	if tick() - _lastGeppo < 0.3 then return end
	-- limit: 20 if Skypieans else 10 (scraped). InfiniteGeppo bypasses it.
	local limit = Character:GetAttribute("Skypieans") and 20 or 10
	if not Cfg.InfiniteGeppo and _geppoCount >= limit then return end
	-- scraped only allows geppo while airborne
	if Humanoid.FloorMaterial ~= Enum.Material.Air and not Cfg.InfiniteGeppo then return end
	_lastGeppo = tick()
	SafeCall(function() ActionRemote:FireServer("Misc", "geppo") end)
	HRP.AssemblyLinearVelocity = Vector3.new(HRP.AssemblyLinearVelocity.X, 100, HRP.AssemblyLinearVelocity.Z)
	_geppoCount += 1
end

local function Dash()
	if not (Cfg.DashEnabled and HRP and Humanoid and ActionRemote) then return end
	if tick() - _lastDash < _dashCooldown then return end
	if Humanoid.MoveDirection.Magnitude <= 0 then return end -- scraped requires movement
	_lastDash = tick()
	SafeCall(function() ActionRemote:FireServer("Misc", "dash") end)
	local speed = Cfg.DashSpeed
	if Character:GetAttribute("Merfolk") and HRP:GetAttribute("Swim") then speed = speed * 1.5 end
	if Character:GetAttribute("DashSpeed") then speed = speed * Character:GetAttribute("DashSpeed") end
	local dir = Humanoid.MoveDirection
	HRP.CFrame = CFrame.lookAt(HRP.Position, HRP.Position + dir)
	local bv = Instance.new("BodyVelocity")
	bv.Name = "DashP"
	bv.MaxForce = Vector3.new(100000, 100000, 100000)
	bv.Velocity = HRP.CFrame.LookVector * speed
	bv.Parent = HRP
	Debris:AddItem(bv, 0.25)
end

--==========================================================
-- DEPT 5: WEAPON
--==========================================================

-- 5.1 AutoEquip
-- Cfg.EquipChoice controls behaviour:
--   ""     -> equip the first tool found (default)
--   "<name>" -> equip only the tool whose name matches (from the UI dropdown)
local function GetBackpackTools()
	local names = {}
	if Backpack then
		for _, t in ipairs(Backpack:GetChildren()) do
			if t:IsA("Tool") then table.insert(names, t.Name) end
		end
	end
	-- include a currently-held tool too
	if Character then
		for _, t in ipairs(Character:GetChildren()) do
			if t:IsA("Tool") then table.insert(names, t.Name) end
		end
	end
	return names
end

local function AutoEquip()
	if not (Character and Humanoid) then return end
	local want = Cfg.EquipChoice or ""
	-- already holding the desired tool? nothing to do
	local held = Character:FindFirstChildOfClass("Tool")
	if held and (want == "" or held.Name == want) then return end
	-- pick the tool to equip
	local tool
	if want ~= "" then
		tool = Backpack and Backpack:FindFirstChild(want)
	else
		tool = Backpack and Backpack:FindFirstChildOfClass("Tool")
	end
	if tool then
		SafeCall(function() Humanoid:EquipTool(tool) end)
	end
end

-- 5.2 UnequipWeapon - reset / put tool back in Backpack
local function UnequipWeapon()
	if Humanoid then
		SafeCall(function() Humanoid:UnequipTools() end)
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

-- 7.0d QuestLevelFor - look up the Level attribute for a quest by its mob/title name
local function QuestLevelFor(questName)
	if not questName or questName == "" then return nil end
	local folder = workspace:FindFirstChild("NpcQuest")
	if not folder then return nil end
	local target = string.lower(questName)
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m.Name ~= "QuestHandler" then
			local nm = m:GetAttribute("Name")
			if nm and string.find(string.lower(tostring(nm)), target) then
				return m:GetAttribute("Level")
			end
		end
	end
	return nil
end

-- 7.0e CancelQuest - drop the active quest.
-- Confirmed call: Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
local function CancelQuest()
	local ok = pcall(function()
		local ev = ReplicatedStorage
			:WaitForChild("Modules")
			:WaitForChild("NetworkFramework")
			:WaitForChild("NetworkEvent")
		ev:FireServer("fire", nil, "Quest", "Cancel")
	end)
	if not ok then
		-- fallback: click the Close_ button inside Frame_Quest
		local fq = GetQuestFrame()
		local closeBtn = fq and (fq:FindFirstChild("Close_") or fq:FindFirstChild("Close"))
		if closeBtn and firesignal and closeBtn:IsA("GuiButton") then
			SafeCall(function()
				firesignal(closeBtn.MouseButton1Click)
				firesignal(closeBtn.Activated)
			end)
		end
	end
end

-- 7.0f CheckQuestMismatch - true if the active quest's level is ABOVE mine
-- (respects manual Quest Max Lv; 0 = auto/use my HUD level)
local function CheckQuestMismatch(questName)
	local qlvl = QuestLevelFor(questName)
	if not qlvl then return false end -- can't determine level -> don't drop
	local cap = Cfg.QuestMaxLevel
	if cap <= 0 then cap = GetMyLevel() or 0 end
	if cap <= 0 then return false end
	return qlvl > cap
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
	-- pick the HARDEST quest I still qualify for: highest Level attribute <= cap.
	-- (20 NPC_Quests, each with its own Level; this grabs the best-reward one.)
	table.sort(eligible, function(a, b)
		local la = a:GetAttribute("Level") or 0
		local lb = b:GetAttribute("Level") or 0
		return la > lb
	end)
	local npc = eligible[1]
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
-- Confirmed remote: ReplicatedStorage.Remotes.System
--   System:FireServer("UpStats", "<StatName>")   e.g. "Melee"
-- FireServer is called once per point, so we send it `amount` times.
--==========================================================
local StatRemote = nil

-- 8.1 FindStatRemote (confirmed path first, then discovery fallback)
local function FindStatRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local sys = remotes:FindFirstChild("System")
		if sys and (sys:IsA("RemoteEvent") or sys:IsA("RemoteFunction")) then
			StatRemote = sys
			return sys
		end
		for _, obj in ipairs(remotes:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				local n = string.lower(obj.Name)
				if n:find("stat") or n:find("point") or n:find("allocate") or n:find("upgrade") or n == "system" then
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

-- 8.2 AllocateStats  ->  System:FireServer("UpStats", statName, 1) x amount
-- Confirmed stat names: Melee, Defense, Sword, Power. Third arg is the point count (1 per call).
local function AllocateStats()
	if not StatRemote then return end
	for statName, amount in pairs(Cfg.Stats) do
		if amount and amount > 0 then
			for _ = 1, amount do
				SafeCall(function()
					StatRemote:FireServer("UpStats", statName, 1)
				end)
				task.wait(0.05)
			end
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
-- DEPT 10: UI / GUI  (Rayfield UI Library)
-- Library source: x2Swiftz/UI-Library -> Rayfield (by Sirius)
--==========================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
if getgenv then getgenv().RockFarmRayfield = Rayfield end

local Window = Rayfield:CreateWindow({
	Name = "Rock Farm Hub",
	LoadingTitle = "Rock Farm Hub",
	LoadingSubtitle = "Rock Fruit Auto Farm",
	ConfigurationSaving = { Enabled = false },
	KeySystem = false,
})

local MainTab     = Window:CreateTab("Main")
local MoveTab     = Window:CreateTab("Movement")
local SettingsTab = Window:CreateTab("Settings")
local StatsTab    = Window:CreateTab("Stats")

-- 10.9 Status label (live target + kills)
local StatusLabel = MainTab:CreateLabel("Target: None | Kills: 0")

-- 1.7 UpdateStatus (real definition)
UpdateStatus = function()
	pcall(function()
		StatusLabel:Set(("Target: %s | Kills: %d"):format(Cfg.Target, Cfg.Kills))
	end)
end

-- 1.6 Notify (real definition, via Rayfield)
Notify = function(text)
	pcall(function()
		Rayfield:Notify({ Title = "Rock Farm Hub", Content = tostring(text), Duration = 3 })
	end)
end

-- 10.5 Toggle wrapper -> Rayfield toggle (keeps SpeedBoost side-effect)
-- default tab = MainTab; pass a tab to override.
local function makeToggle(label, key, tab)
	(tab or MainTab):CreateToggle({
		Name = label,
		CurrentValue = Cfg[key] and true or false,
		Flag = "RF_" .. key,
		Callback = function(v)
			Cfg[key] = v
			if key == "SpeedBoost" then
				if v then ApplySpeed() else ResetSpeed() end
			end
		end,
	})
end

-- 10.7 Input wrapper -> Rayfield input (default tab = SettingsTab)
local function makeInput(label, default, apply, tab)
	(tab or SettingsTab):CreateInput({
		Name = label,
		CurrentValue = tostring(default),
		PlaceholderText = tostring(default),
		RemoveTextAfterFocusLost = false,
		Callback = function(t) apply(t) end,
	})
end

-- 10.5 Toggle Buttons (Main tab)
makeToggle("Auto Farm",  "AutoFarm")
makeToggle("Auto Click", "AutoClick")
makeToggle("Auto Skill", "AutoSkill")
makeToggle("Auto Equip", "AutoEquip")
makeToggle("Auto Quest", "AutoQuest")
makeToggle("Auto Stats", "AutoStats")
makeToggle("Speed Boost","SpeedBoost")

-- 10.6b Weapon picker (Main tab) - choose which tool AutoEquip holds, + reset
local WeaponDropdown = MainTab:CreateDropdown({
	Name = "Weapon",
	Options = (function()
		local o = { "Auto (first tool)" }
		for _, n in ipairs(GetBackpackTools()) do table.insert(o, n) end
		return o
	end)(),
	CurrentOption = { "Auto (first tool)" },
	MultipleOptions = false,
	Callback = function(opt)
		local pick = (type(opt) == "table") and opt[1] or opt
		Cfg.EquipChoice = (pick == "Auto (first tool)") and "" or pick
		AutoEquip() -- equip immediately on pick
	end,
})

MainTab:CreateButton({
	Name = "Refresh Weapon List",
	Callback = function()
		local o = { "Auto (first tool)" }
		for _, n in ipairs(GetBackpackTools()) do table.insert(o, n) end
		pcall(function() WeaponDropdown:Refresh(o, false) end)
		Notify("Weapon list refreshed")
	end,
})

MainTab:CreateButton({
	Name = "Unequip Weapon (Reset)",
	Callback = function()
		Cfg.EquipChoice = ""
		pcall(function() WeaponDropdown:Set({ "Auto (first tool)" }) end)
		UnequipWeapon()
		Notify("Weapon unequipped")
	end,
})

-- 10.5b Movement ability toggles (Movement tab)
makeToggle("Geppo (Space)",  "GeppoEnabled",  MoveTab)
makeToggle("Dash (Q)",       "DashEnabled",   MoveTab)
makeToggle("Infinite Geppo", "InfiniteGeppo", MoveTab)

-- 10.5c Lay Down toggle (Movement tab) - only takes effect in Top warp mode.
-- Disables Humanoid.AutoRotate so the game doesn't stand the character back up.
MoveTab:CreateToggle({
	Name = "Lay Down (Top mode)",
	CurrentValue = false,
	Flag = "RF_LayDown",
	Callback = function(v)
		Cfg.LayDown = v
		if Humanoid then Humanoid.AutoRotate = not v end
	end,
})

-- 10.6 Skills multi-select (Main tab) -> sets Cfg.Skills
MainTab:CreateDropdown({
	Name = "Skill Keys",
	Options = { "Z", "X", "C", "V", "F" },
	CurrentOption = { "Z", "X", "C", "V", "F" },
	MultipleOptions = true,
	Callback = function(opts)
		Cfg.Skills = opts
	end,
})

-- 10.8 Position mode dropdown (Main tab)
MainTab:CreateDropdown({
	Name = "Warp Position",
	Options = { "Back", "Front", "Top", "Bottom" },
	CurrentOption = { Cfg.PositionMode },
	MultipleOptions = false,
	Callback = function(opt)
		Cfg.PositionMode = (type(opt) == "table") and opt[1] or opt
	end,
})

-- 10.7 Inputs (Settings tab)
makeInput("Mob Filter", Cfg.MobFilter, function(t) Cfg.MobFilter = t end)
makeInput("Distance",   Cfg.Distance,  function(t) Cfg.Distance = tonumber(t) or Cfg.Distance end)
makeInput("Max Range",  Cfg.MaxRange,  function(t) Cfg.MaxRange = tonumber(t) or Cfg.MaxRange end)
makeInput("Skill Delay",Cfg.SkillDelay,function(t) Cfg.SkillDelay = tonumber(t) or Cfg.SkillDelay end)
makeInput("Speed Value",Cfg.SpeedValue,function(t) Cfg.SpeedValue = tonumber(t) or Cfg.SpeedValue; if Cfg.SpeedBoost then ApplySpeed() end end)
makeInput("Quest Max Lv",Cfg.QuestMaxLevel,function(t) Cfg.QuestMaxLevel = tonumber(t) or 0 end) -- 0 = auto (my level)
makeInput("Quest Name",  Cfg.QuestName,     function(t) Cfg.QuestName = t end)
makeToggle("Skip Quest > My Lv", "QuestSkipMismatch", SettingsTab)
makeToggle("Island Hop (idle)",  "IslandHop", SettingsTab)
makeInput("Idle Hop Secs", Cfg.IdleHopSeconds, function(t) Cfg.IdleHopSeconds = tonumber(t) or 5 end)
makeInput("Dash Speed",  Cfg.DashSpeed,     function(t) Cfg.DashSpeed = tonumber(t) or Cfg.DashSpeed end, MoveTab)

-- Stat inputs (Stats tab)
makeInput("Stat: Melee",   Cfg.Stats.Melee,   function(t) Cfg.Stats.Melee = tonumber(t) or 0 end, StatsTab)
makeInput("Stat: Sword",   Cfg.Stats.Sword,   function(t) Cfg.Stats.Sword = tonumber(t) or 0 end, StatsTab)
makeInput("Stat: Power",   Cfg.Stats.Power,   function(t) Cfg.Stats.Power = tonumber(t) or 0 end, StatsTab)
makeInput("Stat: Defense", Cfg.Stats.Defense, function(t) Cfg.Stats.Defense = tonumber(t) or 0 end, StatsTab)

--==========================================================
-- DEPT 11: LOOP / THREAD (6 threads)
--==========================================================

-- 11.0 Movement keybinds: Space = Geppo, Q = Dash (mirrors scraped controls)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end -- ignore typing in textboxes / chat
	if input.KeyCode == Enum.KeyCode.Space then
		Geppo()
	elseif input.KeyCode == Enum.KeyCode.Q then
		Dash()
	end
end)

-- 11.1 Cache Refresh (every 3s)
task.spawn(function()
	while task.wait(3) do
		SafeCall(RefreshCache)
	end
end)

-- 11.2 Auto Farm decision loop (fast, ~0.1s)
-- Flow: if Auto Quest is ON and no quest is active -> go accept a quest FIRST.
--       once a quest is active -> read its Title and only farm that mob.
-- The actual teleport is done every frame by the Heartbeat gluer below (11.2b),
-- so you stay pinned behind the mob continuously instead of hopping every 0.2s.
local _questAcceptCooldown = 0
task.spawn(function()
	while task.wait(0.1) do
		if Cfg.AutoFarm and Character and Humanoid and Humanoid.Health > 0 then
			local questActive, questMob = true, nil
			if Cfg.AutoQuest then
				questActive, questMob = GetActiveQuest()
			end

			if Cfg.AutoQuest and not questActive then
				-- no active quest: stop farming, go grab one (throttled)
				_questMobName = nil
				_farmTarget = nil
				Cfg.Target = "Getting quest..."
				UpdateStatus()
				if tick() - _questAcceptCooldown >= 1.5 then
					_questAcceptCooldown = tick()
					local npc, prompt, root = FindQuestNPC()
					if npc then SafeCall(TriggerQuest, npc, prompt, root) end
				end
			elseif Cfg.AutoQuest and questActive and Cfg.QuestSkipMismatch and CheckQuestMismatch(questMob) then
				-- active quest is above my level: drop it, then look for a new one
				_questMobName = nil
				_farmTarget = nil
				Cfg.Target = "Quest too high, skipping..."
				UpdateStatus()
				if tick() - _questAcceptCooldown >= 1.5 then
					_questAcceptCooldown = tick()
					CancelQuest()
				end
			else
				-- quest active (or Auto Quest off): farm. Lock onto the quest mob if we have one.
				_questMobName = questMob
				local mob = GetNearest()
				_farmTarget = mob  -- Heartbeat gluer keeps us on it every frame
				if mob then
					Cfg.Target = questMob and (mob.Name.." [quest]") or mob.Name
					TrackKill(mob)
					if Cfg.AutoEquip then SafeCall(AutoEquip) end
					if Cfg.AutoClick then AttackFallback() end
					if Cfg.AutoSkill then TrySkills() end
					CheckKills()
				else
					-- no mob here: after IdleHopSeconds of standing still, jump to next island
					if not CheckIdleHop() then
						Cfg.Target = questMob and ("No '"..questMob.."' nearby") or "None"
					end
				end
				UpdateStatus()
			end
		else
			-- Auto Farm OFF: nothing in the farm family runs (no click, skill, warp, equip).
			_farmTarget = nil
			_questMobName = nil
			if Humanoid and not Humanoid.AutoRotate then Humanoid.AutoRotate = true end -- stand back up
		end
	end
end)

-- 11.2b Rapid warp gluer (every frame) - pins HRP behind the locked mob
RunService.Heartbeat:Connect(function()
	if not (Cfg.AutoFarm and _farmTarget and HRP) then return end
	if not _farmTarget.Parent then _farmTarget = nil return end
	local root = _farmTarget:FindFirstChild("HumanoidRootPart")
		or _farmTarget:FindFirstChild("Torso")
		or _farmTarget:FindFirstChild("UpperTorso")
	local hum = _farmTarget:FindFirstChildOfClass("Humanoid")
	if root and hum and hum.Health > 0 then
		if Cfg.LayDown and Cfg.PositionMode == "Top" and Humanoid then
			Humanoid.AutoRotate = false -- keep flat, game won't stand us up
		end
		HRP.CFrame = GetOffset(root.CFrame, Cfg.PositionMode, Cfg.Distance)
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

-- 11.5 (Anti-AFK removed per request)

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
		Notify("fireproximityprompt missing - Auto Quest may not work")
	end
end

Init()
