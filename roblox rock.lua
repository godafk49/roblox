-- ============================================================================
-- KOI56 CORE ENGINE v3
-- 1. DUPLICATE MAP (.RBXL / serializer fallback)
-- 2. SCRIPT & MAP SOURCE SCRAPER (budgeted, metadata-only search, single preview)
--
-- Built on Fluent (https://github.com/dawid-scripts/Fluent) for a modern UI.
-- FPS-focused: Acrylic OFF, scrape runs in a time-budgeted coroutine
-- (yields every 5ms), search filters over CHEAP metadata only (never the
-- decompiled source), and the preview box shows ONE script at a time.
-- ============================================================================

-- --------------------------------------------------------------------------
-- Capabilities. Detect once, branch later. Defensive pcall around each probe.
-- --------------------------------------------------------------------------
local Cap = {}
Cap.writefile         = type(writefile) == "function"
Cap.readfile          = type(readfile) == "function"
Cap.setclipboard      = type(setclipboard) == "function" or type(toclipboard) == "function"
Cap.cloneref          = type(cloneref) == "function"
Cap.gethui            = type(gethui) == "function"
Cap.synProtectGui     = syn and type(syn.protect_gui) == "function"
Cap.saveinstance      = type(saveinstance) == "function" or type(save_instance) == "function"
Cap.decompile         = type(decompile) == "function"
Cap.getscriptbytecode = type(getscriptbytecode) == "function"

local function getSaveInstance()
	if type(saveinstance) == "function" then return saveinstance end
	if type(save_instance) == "function" then return save_instance end
	return nil
end

-- --------------------------------------------------------------------------
-- Services. cloneref where available so held references are distinct from the
-- raw game-owned ones (defensive against weak-table identity probes).
-- --------------------------------------------------------------------------
local function cloneRef(inst)
	if Cap.cloneref then
		local ok, cloned = pcall(cloneref, inst)
		if ok then return cloned end
	end
	return inst
end

local gameRef           = cloneRef(game)
local playersService    = gameRef:GetService("Players")
local workspaceService  = gameRef:GetService("Workspace")
local starterGui        = gameRef:GetService("StarterGui")
local runService        = gameRef:GetService("RunService")
local replicatedStorage = gameRef:GetService("ReplicatedStorage")
local lightingService   = gameRef:GetService("Lighting")
local starterPack       = gameRef:GetService("StarterPack")

-- --------------------------------------------------------------------------
-- Small utilities.
-- --------------------------------------------------------------------------
local function notify(title, content)
	-- Fluent:Notify is used once the window exists; before that, fall back.
	pcall(function() starterGui:SetCore("SendNotification", {
		Title = title, Text = content, Duration = 4,
	}) end)
end

local function setClipboardText(text)
	if type(setclipboard) == "function" then return pcall(setclipboard, text) end
	if type(toclipboard) == "function" then return pcall(toclipboard, text) end
	return false
end

-- Time-budgeted loop. Runs `fn` until `budgetSeconds` of wall-clock time elapses,
-- then yields one frame. Prevents frame drops during long walks.
local function budgetedWhile(pred, fn, budgetSeconds)
	budgetSeconds = budgetSeconds or 0.005
	while pred() do
		local start = os.clock()
		while pred() and (os.clock() - start) < budgetSeconds do
			fn()
		end
		runService.Heartbeat:Wait()
	end
end

-- Translate the Speed slider (1-10) into a budget for budgetedWhile.
-- Larger budget = more work per frame = faster overall (but more FPS impact).
--   1 → 0.002s (slow / gentle on FPS),  5 → 0.010s (balanced),  10 → 0.020s (fast / heavy).
local function budgetFromSpeed(speed)
	local clamped = math.max(1, math.min(10, speed or 5))
	return clamped * 0.002
end

-- ============================================================================
-- Load Fluent + addons. httpGet errors -> hard stop with a clear message.
-- ============================================================================
local fluentOk, Fluent = pcall(function()
	return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not fluentOk or not Fluent then
	notify("KOI56", "โหลด Fluent ไม่สำเร็จ — ตรวจสอบอินเทอร์เน็ตและลองใหม่")
	return
end

local saveMgrOk, SaveManager = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)
local ifaceOk, InterfaceManager = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)
if not saveMgrOk then SaveManager = nil end
if not ifaceOk then InterfaceManager = nil end

-- NOTE: Fluent protects its own ScreenGui internally (it checks for gethui /
-- syn.protect_gui at load). No extra hook is needed here.

-- ============================================================================
-- Window. Acrylic = false because the blur effect is a known FPS hog on low-end
-- GPUs / mobile, and Fluent itself notes it can be detected.
-- ============================================================================
local Window = Fluent:CreateWindow({
	Title = "KOI56 Engine v3",
	SubTitle = "Core 2-in-1 Suite",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
	Map     = Window:AddTab({ Title = "Duplicate Map", Icon = "map" }),
	Scraper = Window:AddTab({ Title = "Script Scraper", Icon = "file-code" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- Forward declarations so button callbacks can reference functions/values
-- defined further down without relying on globals.
local runSaveMap

-- --------------------------------------------------------------------------
-- Shared settings used by SaveManager.
-- --------------------------------------------------------------------------
local settings = {
	MapFileName      = "KOI56_Map_" .. tostring(game.PlaceId) .. ".rbxl",
	DumpFileName     = "KOI56_ScriptSource_" .. tostring(game.PlaceId) .. ".txt",
	RemovePlayer     = true,
	IncludeReplicatedStorage = true,
	IncludeLighting          = true,
	IncludeStarterPack       = true,
	IncludeStarterGui        = true,
	Speed            = 5,  -- 1 = ช้า/นุ่ม (FPS ลื่น), 10 = เร็ว/แรง (FPS กระตุกขณะทำงาน)
}

-- --------------------------------------------------------------------------
-- Live progress display. Uses a persistent Fluent notification (Duration=nil
-- means it never auto-dismisses). We reach into the returned notification
-- object's ContentLabel TextLabel to update the text without recreating it.
-- Returns two functions: update(pct, msg) and done().
-- --------------------------------------------------------------------------
local function makeProgress(title)
	local notif = Fluent:Notify({
		Title = title,
		Content = "0%",
		Duration = nil,  -- stays visible until we close it
	})
	if not notif then
		-- Fallback: no-op progress if Notify misbehaves.
		return function() end, function() end
	end
	local update = function(pct, msg)
		if not notif or not notif.ContentLabel then return end
		local pctClamped = math.max(0, math.min(100, math.floor(pct or 0)))
		local text = pctClamped .. "%"
		if msg then text = text .. " · " .. msg end
		pcall(function() notif.ContentLabel.Text = text end)
	end
	local done = function()
		if notif then
			pcall(function() notif:Close() end)
			notif = nil  -- idempotent: safe to call again; update becomes no-op
		end
	end
	return update, done
end

-- ============================================================================
-- FUNCTION 1: DUPLICATE MAP ENGINE
-- ============================================================================
-- Filename input.
Tabs.Map:AddInput("MapFileName", {
	Title = "Map file name",
	Default = settings.MapFileName,
	Placeholder = "filename.rbxl",
	Callback = function(val) settings.MapFileName = val end,
})

-- Include-option toggles.
Tabs.Map:AddToggle("OptRemovePlayer", {
	Title = "RemovePlayer (Animator guard)",
	Description = "Drop player characters. Prevents Animator Error when re-importing in Studio.",
	Default = settings.RemovePlayer,
	Callback = function(val) settings.RemovePlayer = val end,
})
Tabs.Map:AddToggle("OptReplicatedStorage", {
	Title = "Include ReplicatedStorage",
	Default = settings.IncludeReplicatedStorage,
	Callback = function(val) settings.IncludeReplicatedStorage = val end,
})
Tabs.Map:AddToggle("OptLighting", {
	Title = "Include Lighting",
	Default = settings.IncludeLighting,
	Callback = function(val) settings.IncludeLighting = val end,
})
Tabs.Map:AddToggle("OptStarterPack", {
	Title = "Include StarterPack",
	Default = settings.IncludeStarterPack,
	Callback = function(val) settings.IncludeStarterPack = val end,
})
Tabs.Map:AddToggle("OptStarterGui", {
	Title = "Include StarterGui",
	Default = settings.IncludeStarterGui,
	Callback = function(val) settings.IncludeStarterGui = val end,
})

Tabs.Map:AddButton({
	Title = "Save Map",
	Description = "saveinstance -> .rbxl ; else serializer -> .lua ; else clipboard.",
	Callback = function()
		task.spawn(runSaveMap)
	end,
})

-- --------------------------------------------------------------------------
-- Map: serializer (used when saveinstance is unavailable).
-- --------------------------------------------------------------------------
local SERIALIZED_PROPS = {
	"Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "Massless",
	"Size", "CFrame", "Position", "Orientation",
	"Transparency", "Reflectance", "Material", "Color",
	"FrontSurface", "BackSurface", "LeftSurface", "RightSurface", "TopSurface", "BottomSurface",
	"Shape",
	"Brightness", "Range", "Angle", "Enabled", "Shadows", "ClockTime",
	"FogEnd", "FogStart", "FogColor", "GlobalShadows",
	"Ambient", "OutdoorAmbient", "Technology",
	"Texture",
	"Text", "Font", "TextSize", "BackgroundColor3", "TextXAlignment",
	"TextYAlignment", "TextWrapped",
}

local function fmtNum(n)
	if n ~= n then return "0/0" end
	if n == math.huge then return "math.huge" end
	if n == -math.huge then return "-math.huge" end
	local s = string.format("%.4f", n)
	s = s:gsub("%.?0+$", "")
	if s == "" or s == "-" then s = "0" end
	return s
end

local function serializeValue(v)
	local t = typeof(v)
	if t == "number" then
		return fmtNum(v)
	elseif t == "string" then
		return string.format("%q", v)
	elseif t == "boolean" then
		return v and "true" or "false"
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", fmtNum(v.X), fmtNum(v.Y), fmtNum(v.Z))
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s, %s)", fmtNum(v.X), fmtNum(v.Y))
	elseif t == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
		if r00 == 1 and r11 == 1 and r22 == 1 then
			return string.format("CFrame.new(%s, %s, %s)", fmtNum(x), fmtNum(y), fmtNum(z))
		end
		return string.format(
			"CFrame.new(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
			fmtNum(x), fmtNum(y), fmtNum(z),
			fmtNum(r00), fmtNum(r01), fmtNum(r02),
			fmtNum(r10), fmtNum(r11), fmtNum(r12),
			fmtNum(r20), fmtNum(r21), fmtNum(r22)
		)
	elseif t == "Color3" then
		return string.format("Color3.new(%s, %s, %s)", fmtNum(v.R), fmtNum(v.G), fmtNum(v.B))
	elseif t == "BrickColor" then
		return string.format('BrickColor.new("%s")', v.Name)
	elseif t == "EnumItem" then
		return "Enum." .. tostring(v.EnumType) .. "." .. tostring(v.Name)
	elseif t == "UDim" then
		return string.format("UDim.new(%s, %s)", fmtNum(v.Scale), fmtNum(v.Offset))
	elseif t == "UDim2" then
		return string.format("UDim2.new(%s, %s, %s, %s)",
			fmtNum(v.X.Scale), fmtNum(v.X.Offset), fmtNum(v.Y.Scale), fmtNum(v.Y.Offset))
	end
	return nil
end

local function buildContainerList(opts)
	local list = { workspaceService }
	if opts.IncludeReplicatedStorage then table.insert(list, replicatedStorage) end
	if opts.IncludeLighting then table.insert(list, lightingService) end
	if opts.IncludeStarterPack then table.insert(list, starterPack) end
	if opts.IncludeStarterGui then table.insert(list, starterGui) end
	return list
end

-- Iterative, budgeted tree walker. Builds a flat list of {parentIdx, className,
-- name, props} without recursion (avoids C-stack overflow on deep trees) and
-- yields every 5ms so the game keeps rendering. `onProgress(pct, msg)` is called
-- periodically (it's optional; pass nil to skip).
local function buildNodeTable(opts, onProgress)
	local nodes  = {}      -- [idx] = {parentIdx, className, name, props}
	local order  = {}      -- build order of idx

	-- Stack of {inst, parentIdx}. Seeded with the chosen root containers.
	local stack = {}
	local roots = buildContainerList(opts)
	for _, root in ipairs(roots) do
		table.insert(stack, { root, nil })
	end

	-- Approximate total for the progress percentage. Sum of descendants across
	-- the root containers. Cheap-ish (one C call per container) and budgeted.
	local grandTotal = 0
	for _, root in ipairs(roots) do
		local ok, count = pcall(function()
			local n = 1  -- include the root itself
			for _ in ipairs(root:GetDescendants()) do n = n + 1 end
			return n
		end)
		if ok then grandTotal = grandTotal + count end
	end
	if grandTotal == 0 then grandTotal = 1 end

	local function isPlayerCharacter(inst)
		if not opts.RemovePlayer then return false end
		if not inst:IsA("Model") then return false end
		if not inst:FindFirstChildOfClass("Humanoid") then return false end
		return inst:IsDescendantOf(playersService)
	end

	local nodeCount = 0
	local sinceLastReport = 0  -- throttle progress updates so we don't spam Text writes
	-- Budgeted walk: process the stack until empty, yielding every 5ms.
	budgetedWhile(
		function() return #stack > 0 end,
		function()
			local entry = table.remove(stack)  -- LIFO
			local inst, parentIdx = entry[1], entry[2]
			if isPlayerCharacter(inst) then return end

			local className = inst.ClassName
			if className == "Workspace" then className = "Folder" end

			nodeCount = nodeCount + 1
			local idx = nodeCount
			local node = { parentIdx = parentIdx, className = className, name = inst.Name, props = {} }
			nodes[idx] = node
			table.insert(order, idx)

			-- Capture the cheap serializable props.
			for _, propName in ipairs(SERIALIZED_PROPS) do
				local ok, value = pcall(function() return inst[propName] end)
				if ok then
					local lit = serializeValue(value)
					if lit then node.props[propName] = lit end
				end
			end

			-- Push children so they get processed next (also budgeted).
			for _, child in ipairs(inst:GetChildren()) do
				table.insert(stack, { child, idx })
			end

			-- Throttled progress report.
			if onProgress then
				sinceLastReport = sinceLastReport + 1
				if sinceLastReport >= 100 then
					sinceLastReport = 0
					onProgress(nodeCount / grandTotal * 100, nodeCount .. " objects")
				end
			end
		end,
		0.005
	)

	return nodes, order
end

-- Emits the reconstruction .lua text from a flat node table. String assembly is
-- bounded by node count and fast (one pass); table.concat at the end.
local function emitReconstruction(nodes, order)
	local lines = {}
	table.insert(lines, "-- ============================================================================")
	table.insert(lines, "-- KOI56 MAP RECONSTRUCTION (serializer fallback)")
	table.insert(lines, string.format("-- PlaceId: %d | Game: %s | Nodes: %d", game.PlaceId, game.Name, #order))
	table.insert(lines, "-- Run this in a fresh place to rebuild the captured hierarchy.")
	table.insert(lines, "-- ============================================================================")
	table.insert(lines, "")
	table.insert(lines, "local ROOT = Instance.new(\"Folder\")")
	table.insert(lines, "ROOT.Name = \"KOI56_ReconstructedMap\"")
	table.insert(lines, "ROOT.Parent = workspace")
	table.insert(lines, "")
	table.insert(lines, "local nodes = {}")
	table.insert(lines, "local function make(className, name, parent)")
	table.insert(lines, "    local i = Instance.new(className)")
	table.insert(lines, "    i.Name = name")
	table.insert(lines, "    i.Parent = parent")
	table.insert(lines, "    return i")
	table.insert(lines, "end")
	table.insert(lines, "")

	for _, idx in ipairs(order) do
		local node = nodes[idx]
		local parentRef = node.parentIdx and ("nodes[" .. node.parentIdx .. "]") or "ROOT"
		table.insert(lines, string.format("nodes[%d] = make(%q, %q, %s)",
			idx, node.className, node.name, parentRef))
		for propName, lit in pairs(node.props) do
			table.insert(lines, string.format("nodes[%d].%s = %s", idx, propName, lit))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "print(\"[KOI56] Reconstructed \" .. #nodes .. \" instances into ROOT.\")")
	return table.concat(lines, "\n")
end

-- runSaveMap: the actual save logic (forward-declared above the button).
runSaveMap = function()
	local opts = {
		RemovePlayer             = settings.RemovePlayer,
		IncludeReplicatedStorage = settings.IncludeReplicatedStorage,
		IncludeLighting          = settings.IncludeLighting,
		IncludeStarterPack       = settings.IncludeStarterPack,
		IncludeStarterGui        = settings.IncludeStarterGui,
	}
	local baseName = settings.MapFileName
	local saveFn = getSaveInstance()

	-- Filename resolution.
	local rbxlName = baseName
	if not rbxlName:match("%.rbxl$") and not rbxlName:match("%.rbxlx$") then
		rbxlName = rbxlName .. ".rbxl"
	end
	local luaName = rbxlName:gsub("%.rbxlx?$", "") .. ".lua"

	Fluent:Notify({ Title = "KOI56", Content = "กำลังดำเนินการบันทึกแมพ...", Duration = 3 })

	if saveFn then
		local extra = {}
		if opts.IncludeReplicatedStorage then table.insert(extra, replicatedStorage) end
		if opts.IncludeLighting then table.insert(extra, lightingService) end
		if opts.IncludeStarterPack then table.insert(extra, starterPack) end
		if opts.IncludeStarterGui then table.insert(extra, starterGui) end

		local ok, err = pcall(saveFn, {
			FilePath = rbxlName,
			Decompile = true,
			NilInstances = true,
			RemovePlayer = opts.RemovePlayer,
			ExtraInstances = extra,
		})
		if ok then
			Fluent:Notify({ Title = "KOI56 Success", Content = "บันทึกไฟล์แมพ " .. rbxlName .. " สำเร็จ!", Duration = 6 })
			return
		end
		Fluent:Notify({ Title = "KOI56", Content = "saveinstance ล้มเหลว ใช้ serializer แทน...", Duration = 5 })
	end

	-- Serializer fallback (budgeted; yields every 5ms during the walk).
	local updateProgress, doneProgress = makeProgress("KOI56 · สำเนาแมพ")
	updateProgress(0, "เริ่มต้น...")
	-- buildNodeTable yields and walks the whole tree; pcall so a throw still
	-- closes the progress notification instead of leaving it stuck at 0%.
	local walkOk, nodes, order = pcall(buildNodeTable, opts, updateProgress)
	if not walkOk or not order or #order == 0 then
		doneProgress()
		Fluent:Notify({ Title = "KOI56 Error", Content = "สกัดโครงสร้างล้มเหลว: " .. tostring(nodes), Duration = 8 })
		return
	end
	updateProgress(100, "เขียนไฟล์...")
	local ok, code = pcall(emitReconstruction, nodes, order)
	if not ok or not code then
		doneProgress()
		Fluent:Notify({ Title = "KOI56 Error", Content = "สกัดโครงสร้างล้มเหลว: " .. tostring(code), Duration = 8 })
		return
	end

	local written = false
	if Cap.writefile then written = pcall(writefile, luaName, code) end
	setClipboardText(code)
	doneProgress()

	if written then
		Fluent:Notify({ Title = "KOI56 Success", Content = "เขียนไฟล์ " .. luaName .. " สำเร็จ (และคัดลอกลง Clipboard)", Duration = 6 })
	else
		Fluent:Notify({ Title = "KOI56", Content = "คัดลอกสคริปต์สร้างแมพลง Clipboard เรียบร้อย", Duration = 6 })
	end
end

-- ============================================================================
-- FUNCTION 2: SCRIPT & MAP SOURCE SCRAPER
-- Budgeted: scrape runs in task.spawn with Heartbeat yields. Metadata index is
-- cheap; source is decompiled LAZILY when a script is selected for preview,
-- never in bulk.
-- ============================================================================
local scrapeState = {
	scripts   = {},  -- array of { path, class, inst, source=nil }
	scriptsByPath = {},  -- map: path -> entry, for O(1) lookup on dropdown select
	tools     = {},  -- { name, class, path }
	-- 'source' is filled lazily by getScriptSource().
}

-- Lazy decompile: only invoked when the user selects a script to preview.
local function getScriptSource(entry)
	if entry.source ~= nil then return entry.source end
	local src = ""
	if Cap.decompile then
		pcall(function() src = decompile(entry.inst) or "" end)
	end
	if src == "" and Cap.getscriptbytecode then
		pcall(function()
			local bc = getscriptbytecode(entry.inst)
			src = bc and ("-- [bytecode, " .. #bc .. " bytes]\n" .. bc) or ""
		end)
	end
	if src == "" then
		pcall(function() src = entry.inst.Source or "" end)
	end
	if src == "" then src = "-- [Protected or Empty Script]" end
	entry.source = src
	return src
end

-- All scraper UI elements are created up-front but only populated on demand.
local scriptDropdown          -- created below, populated after a scrape.

-- Scrape action. Designed to minimize frame impact:
--   1. Walks descendants in budgeted chunks (yields every 5ms).
--   2. Classifies cheaply; never decompiles during the walk.
--   3. Stores only a weak-ish reference (we still need the instance to
--      decompile later, but we don't hold the whole tree).
--   4. Caps the dropdown so Fluent doesn't try to render 5000+ rows.
local MAX_DROPDOWN_ENTRIES = 400

local function runScrape()
	task.spawn(function()
		-- Reset.
		scrapeState.scripts = {}
		scrapeState.scriptsByPath = {}
		scrapeState.tools = {}

		local total = 0
		-- Budgeted walk. We iterate via numeric index into the descendants
		-- array captured once; the walk body itself is cheap.
		local i = 0
		local updateProgress, doneProgress = makeProgress("KOI56 · สแกนสคริปต์")

		budgetedWhile(
			function() return i < total or total == 0 end,
			function()
				-- First tick: capture the descendants array.
				if total == 0 then
					local all = game:GetDescendants()
					total = #all
					if total == 0 then total = 1 end
					scrapeState._all = all
					updateProgress(0, total .. " objects")
					return
				end
				i = i + 1
				local inst = scrapeState._all[i]
				scrapeState._all[i] = nil  -- free the slot; we don't need the array later
				if not inst then return end
				if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
					local entry = {
						path = inst:GetFullName(),
						class = inst.ClassName,
						inst = inst,
						source = nil,
					}
					table.insert(scrapeState.scripts, entry)
					scrapeState.scriptsByPath[entry.path] = entry
				elseif inst:IsA("Tool") or inst:IsA("HopperBin") then
					table.insert(scrapeState.tools, {
						name = inst.Name,
						class = inst.ClassName,
						path = inst:GetFullName(),
					})
				end
				-- Throttled progress (every 50 items).
				if i % 50 == 0 then
					updateProgress(i / total * 100, i .. "/" .. total)
				end
			end,
			0.005
		)
		scrapeState._all = nil  -- drop the reference entirely

		-- Build display labels for the dropdown (path [class]), capped.
		local labels = {}
		local cap = math.min(#scrapeState.scripts, MAX_DROPDOWN_ENTRIES)
		for n = 1, cap do
			local s = scrapeState.scripts[n]
			table.insert(labels, s.path .. "  [" .. s.class .. "]")
		end
		if #scrapeState.scripts > MAX_DROPDOWN_ENTRIES then
			table.insert(labels, string.format("... (%d more — use Dump ALL)", #scrapeState.scripts - MAX_DROPDOWN_ENTRIES))
		end
		if scriptDropdown and labels[1] then
			scrapeState.suppressNextSelect = true  -- SetValue below fires Callback; ignore it
			scriptDropdown:SetValues(labels)
			scriptDropdown:SetValue(labels[1])
		end

		updateProgress(100, "เสร็จสิ้น")
		task.wait(0.3)
		doneProgress()

		Fluent:Notify({
			Title = "KOI56 Dumper",
			Content = string.format("สแกนเสร็จ: %d สคริปต์ · %d Tools", #scrapeState.scripts, #scrapeState.tools),
			Duration = 6,
		})
	end)
end

-- Scraper tab controls (Fluent).
Tabs.Scraper:AddButton({
	Title = "Scrape all scripts",
	Description = "Builds a metadata index. Source is decompiled on demand when you pick a script.",
	Callback = runScrape,
})

-- Speed slider: controls how aggressively budgetedWhile runs (scrape / dump / serializer).
Tabs.Scraper:AddSlider("Speed", {
	Title = "ความเร็วดึงข้อมูล",
	Description = "1 = ช้า/นุ่ม (FPS ลื่น) · 10 = เร็ว/แรง (FPS กระตุกขณะทำงาน)",
	Default = settings.Speed,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Callback = function(val) settings.Speed = val end,
})

scriptDropdown = Tabs.Scraper:AddDropdown("ScriptList", {
	Title = "Select a script (copies source to clipboard)",
	Values = { "(scrape first)" },
	Default = 1,
	Callback = function(val)
		-- Suppress the automatic fire that happens when we SetValue() after a scrape.
		if scrapeState.suppressNextSelect then
			scrapeState.suppressNextSelect = false
			return
		end
		-- Match the label back to an entry via the path→entry map.
		local path = val:match("^(.+)%s+%[")
		if not path then return end
		local s = scrapeState.scriptsByPath[path]
		if not s then return end
		local src = getScriptSource(s)
		-- Fluent has no multiline element, so the full source is copied
		-- to clipboard on select and a size summary is shown.
		setClipboardText(src)
		Fluent:Notify({
			Title = "KOI56",
			Content = string.format("คัดลอกซอร์สของ %s (%d ตัวอักษร) ลง Clipboard", s.path, #src),
			Duration = 4,
		})
	end,
})

-- Dump-all button: writes the full source dump to disk/clipboard.
Tabs.Scraper:AddButton({
	Title = "Dump ALL to file/clipboard",
	Description = "Decompiles everything. Slow and freezes the game briefly — use sparingly.",
	Callback = function()
		task.spawn(function()
			if #scrapeState.scripts == 0 then
				Fluent:Notify({ Title = "KOI56", Content = "ยังไม่ได้สแกน — กด Scrape ก่อน", Duration = 4 })
				return
			end

			local updateProgress, doneProgress = makeProgress("KOI56 · Dump ทั้งหมด")

			local lines = {}
			table.insert(lines, "-- ============================================================================")
			table.insert(lines, "-- KOI56 SCRAPED GAME SOURCE CODE & HIERARCHY")
			table.insert(lines, string.format("-- PlaceId: %d | Game Name: %s", game.PlaceId, game.Name))
			table.insert(lines, "-- ============================================================================\n")

			local total = #scrapeState.scripts
			local i = 0
			budgetedWhile(
				function() return i < total end,
				function()
					i = i + 1
					local s = scrapeState.scripts[i]
					table.insert(lines, string.format("-- SCRIPT: %s [%s]", s.path, s.class))
					table.insert(lines, getScriptSource(s))
					table.insert(lines, "\n----------------------------------------------------------------------------\n")
					-- Throttled progress (every script — decompile is slow so each is visible).
					updateProgress(i / total * 100, i .. "/" .. total .. " decompiled")
				end,
				0.005
			)

			table.insert(lines, "\n-- [ SECTION 2: WEAPONS & TOOLS HIERARCHY ] --\n")
			for _, t in ipairs(scrapeState.tools) do
				table.insert(lines, string.format("Tool: %s | Class: %s | Path: %s", t.name, t.class, t.path))
			end

			updateProgress(100, "กำลังเขียนไฟล์...")

			local result = table.concat(lines, "\n")
			local written = false
			if Cap.writefile then written = pcall(writefile, settings.DumpFileName, result) end
			setClipboardText(result)

			doneProgress()

			Fluent:Notify({
				Title = "KOI56 Dumper",
				Content = written and ("Dump สำเร็จ: " .. settings.DumpFileName) or "คัดลอก dump ทั้งหมดลง Clipboard",
				Duration = 6,
			})
		end)
	end,
})

-- ============================================================================
-- Settings tab: wire SaveManager + InterfaceManager (replaces manual config).
-- ============================================================================
if SaveManager then
	SaveManager:SetLibrary(Fluent)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({})  -- all our toggles persist by default
	if InterfaceManager then
		InterfaceManager:SetLibrary(Fluent)
		InterfaceManager:SetFolder("KOI56")
	end
	SaveManager:SetFolder("KOI56/" .. tostring(game.PlaceId))
	SaveManager:BuildConfigSection(Tabs.Settings)
	if InterfaceManager then
		InterfaceManager:BuildInterfaceSection(Tabs.Settings)
	end
	SaveManager:LoadAutoloadConfig()
else
	Tabs.Settings:AddParagraph({
		Title = "SaveManager unavailable",
		Content = "Couldn't load the Fluent SaveManager addon. Configs won't persist across runs.",
	})
end

-- --------------------------------------------------------------------------
-- Filename inputs on the settings tab (convenience; synced with Map tab).
-- --------------------------------------------------------------------------
Tabs.Settings:AddInput("DumpFileNameSettings", {
	Title = "Dump file name",
	Default = settings.DumpFileName,
	Placeholder = "filename.txt",
	Callback = function(val) settings.DumpFileName = val end,
})

Window:SelectTab(1)

Fluent:Notify({
	Title = "KOI56 v3",
	Content = "Engine loaded. Acrylic off, budgeted scrape, lazy decompile.",
	Duration = 6,
})
