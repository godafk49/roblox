-- ============================================================================
-- KOI56 CORE ENGINE v2  (single-file upgrade)
-- 1. DUPLICATE MAP (.RBXL / .RBXLX)   -- with include-options + Animator guard
-- 2. SCRIPT & MAP SOURCE SCRAPER      -- with search / class filter / live stats
-- Improvements over v1:
--   * Bug fixes: gethui-before-create, deprecated Draggable, saveinstance name
--     variant, nil decompile global.
--   * Stealth/compat: cloneref'd services, correct gethui parenting, centralized
--     capability detection, pcall guards on every risky call.
--   * UX: custom mobile+PC drag (replaces dead Draggable), persisted config
--     (filename / map options / window position), search + filter pills.
-- NO KEY SYSTEM | MOBILE & PC OPTIMIZED | SINGLE FILE
-- ============================================================================

-- --------------------------------------------------------------------------
-- Capabilities. Detect once, branch later. Defensive pcall around each probe.
-- --------------------------------------------------------------------------
local Cap = {}
Cap.writefile       = type(writefile) == "function"
Cap.readfile        = type(readfile) == "function"
Cap.setclipboard    = type(setclipboard) == "function" or type(toclipboard) == "function"
Cap.cloneref        = type(cloneref) == "function"
Cap.gethui          = type(gethui) == "function"
Cap.synProtectGui   = syn and type(syn.protect_gui) == "function"
Cap.saveinstance    = type(saveinstance) == "function" or type(save_instance) == "function"
Cap.decompile       = type(decompile) == "function"
Cap.getscriptbytecode = type(getscriptbytecode) == "function"

-- Resolve the real saveinstance function regardless of spelling.
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

local gameRef          = cloneRef(game)
local tweenService     = gameRef:GetService("TweenService")
local playersService   = gameRef:GetService("Players")
local workspaceService = gameRef:GetService("Workspace")
local coreGuiService   = gameRef:GetService("CoreGui")
local starterGui       = gameRef:GetService("StarterGui")
local runService       = gameRef:GetService("RunService")
local userInputService = gameRef:GetService("UserInputService")
local httpService      = gameRef:GetService("HttpService")
local replicatedStorage = gameRef:GetService("ReplicatedStorage")
local lightingService  = gameRef:GetService("Lighting")
local starterPack      = gameRef:GetService("StarterPack")

-- Theme. Single table so recoloring is a one-line change.
local Theme = {
	Bg        = Color3.fromRGB(18, 20, 26),
	BgDark    = Color3.fromRGB(12, 14, 18),
	Sidebar   = Color3.fromRGB(14, 15, 20),
	Panel     = Color3.fromRGB(25, 27, 36),
	Accent    = Color3.fromRGB(255, 170, 0),
	AccentHi  = Color3.fromRGB(255, 150, 0),
	Text      = Color3.fromRGB(255, 255, 255),
	TextDim   = Color3.fromRGB(160, 165, 180),
	Code      = Color3.fromRGB(180, 220, 180),
	Ok        = Color3.fromRGB(35, 130, 90),
	Info      = Color3.fromRGB(0, 140, 220),
	Err       = Color3.fromRGB(215, 50, 50),
	Pill      = Color3.fromRGB(22, 24, 32),
	PillOn    = Color3.fromRGB(255, 150, 0),
}

local DRAG_THRESHOLD = 6 -- pixels before a press counts as a drag, not a click

-- --------------------------------------------------------------------------
-- Config store (persisted via readfile/writefile when available).
-- --------------------------------------------------------------------------
local ConfigStore = {
	path = "KOI56_Config.json",
	data = {
		MapFileName = "KOI56_Map_" .. tostring(game.PlaceId) .. ".rbxl",
		DumpFileName = "KOI56_ScriptSource_" .. tostring(game.PlaceId) .. ".txt",
		Options = {
			RemovePlayer        = true,  -- drop player chars -> avoids Animator Error in Studio
			ReplicatedStorage   = true,
			Lighting            = true,
			StarterPack         = true,
			StarterGui          = true,
		},
		WinX = nil, -- nil = keep default centered position
		WinY = nil,
	},
}

function ConfigStore.load()
	if not Cap.readfile then return end
	local ok, raw = pcall(readfile, ConfigStore.path)
	if not ok or not raw or raw == "" then return end
	local ok2, decoded = pcall(function() return httpService:JSONDecode(raw) end)
	if not ok2 or type(decoded) ~= "table" then return end
	-- Merge defensively: only copy fields we expect, with type checks.
	if type(decoded.MapFileName) == "string" and decoded.MapFileName ~= "" then
		ConfigStore.data.MapFileName = decoded.MapFileName
	end
	if type(decoded.DumpFileName) == "string" then
		ConfigStore.data.DumpFileName = decoded.DumpFileName
	end
	if type(decoded.Options) == "table" then
		for k, v in pairs(decoded.Options) do
			if ConfigStore.data.Options[k] ~= nil and type(v) == "boolean" then
				ConfigStore.data.Options[k] = v
			end
		end
	end
	if type(decoded.WinX) == "number" then ConfigStore.data.WinX = decoded.WinX end
	if type(decoded.WinY) == "number" then ConfigStore.data.WinY = decoded.WinY end
end

function ConfigStore.save()
	if not Cap.writefile then return end
	local ok, encoded = pcall(function() return httpService:JSONEncode(ConfigStore.data) end)
	if not ok or not encoded then return end
	pcall(writefile, ConfigStore.path, encoded)
end

ConfigStore.load()

-- --------------------------------------------------------------------------
-- Small utilities.
-- --------------------------------------------------------------------------
local function sendNotify(title, text)
	pcall(function()
		starterGui:SetCore("SendNotification", {
			Title = title, Text = text, Duration = 4,
		})
	end)
end

local function setClipboardText(text)
	if Cap.setclipboard then
		if type(setclipboard) == "function" then
			return pcall(setclipboard, text)
		elseif type(toclipboard) == "function" then
			return pcall(toclipboard, text)
		end
	end
	return false
end

-- Stable Instance creation helper: sets Name + Parent last, applies UICorner.
local function new(class, name, parent)
	local inst = Instance.new(class)
	if name then inst.Name = name end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(inst, radius)
	local c = new("UICorner", nil, inst)
	c.CornerRadius = radius or UDim.new(0, 6)
	return c
end

-- --------------------------------------------------------------------------
-- Resolve the GUI parent. Prefer gethui (UNC/Potassium), then syn.protect_gui
-- + CoreGui, then plain CoreGui. Fixes v1's use-before-create bug.
-- --------------------------------------------------------------------------
local function resolveGuiParent()
	if Cap.gethui then
		local ok, parent = pcall(function() return gethui() end)
		if ok and parent and typeof(parent) == "Instance" then return parent end
	end
	return coreGuiService
end

-- ============================================================================
-- GUI SCAFFOLD
-- ============================================================================

-- Remove any previous instance of this UI before rebuilding.
local oldUi = coreGuiService:FindFirstChild("KOI56_CoreOnlyUI")
if Cap.gethui then
	local huiParent = resolveGuiParent()
	if huiParent and huiParent:FindFirstChild("KOI56_CoreOnlyUI") then
		huiParent.KOI56_CoreOnlyUI:Destroy()
	end
elseif oldUi then
	oldUi:Destroy()
end

local screenGui = new("ScreenGui", "KOI56_CoreOnlyUI")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 9999

-- syn.protect_gui must run BEFORE parenting.
if Cap.synProtectGui then pcall(syn.protect_gui, screenGui) end
screenGui.Parent = resolveGuiParent()

-- ---- Mobile floating toggle button (K) ----
local toggleBtn = new("TextButton", nil, screenGui)
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
toggleBtn.BackgroundColor3 = Theme.Bg
toggleBtn.Text = "K"
toggleBtn.TextColor3 = Theme.Accent
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 24
corner(toggleBtn, UDim.new(1, 0))

local toggleStroke = new("UIStroke", nil, toggleBtn)
toggleStroke.Color = Theme.Accent
toggleStroke.Thickness = 2

-- ---- Main window ----
local mainFrame = new("Frame", nil, screenGui)
mainFrame.Size = UDim2.new(0, 540, 0, 440)
mainFrame.Position = UDim2.new(0.5, -270, 0.5, -220)
mainFrame.BackgroundColor3 = Theme.Bg
mainFrame.BorderSizePixel = 0
corner(mainFrame, UDim.new(0, 10))

-- Restore persisted window position if present.
if ConfigStore.data.WinX and ConfigStore.data.WinY then
	mainFrame.Position = UDim2.new(0, ConfigStore.data.WinX, 0, ConfigStore.data.WinY)
end

-- ---- Top bar (drag handle) ----
local topBar = new("Frame", nil, mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Theme.BgDark
corner(topBar, UDim.new(0, 10)) -- rounded top; bottom covered by body

local titleLbl = new("TextLabel", nil, topBar)
titleLbl.Size = UDim2.new(1, -50, 1, 0)
titleLbl.Position = UDim2.new(0, 15, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "KOI56 ENGINE v2  |  CORE 2-IN-1 SUITE"
titleLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = new("TextButton", nil, topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Theme.Err
closeBtn.Text = "✕"
closeBtn.TextColor3 = Theme.Text
closeBtn.Font = Enum.Font.GothamBold
corner(closeBtn, UDim.new(0, 6))

closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- ---- Sidebar ----
local sidebar = new("Frame", nil, mainFrame)
sidebar.Size = UDim2.new(0, 130, 1, -68)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = Theme.Sidebar

local tabLayout = new("UIListLayout", nil, sidebar)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)

local tabPad = new("UIPadding", nil, sidebar)
tabPad.PaddingTop = UDim.new(0, 10)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)

local pageContainer = new("Frame", nil, mainFrame)
pageContainer.Size = UDim2.new(1, -140, 1, -78)
pageContainer.Position = UDim2.new(0, 135, 0, 45)
pageContainer.BackgroundTransparency = 1

-- ---- Status bar ----
local statusBg = new("Frame", nil, mainFrame)
statusBg.Size = UDim2.new(1, 0, 0, 26)
statusBg.Position = UDim2.new(0, 0, 1, -26)
statusBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)

local statusFill = new("Frame", nil, statusBg)
statusFill.Size = UDim2.new(0, 0, 1, 0)
statusFill.BackgroundColor3 = Theme.Accent

local statusLbl = new("TextLabel", nil, statusBg)
statusLbl.Size = UDim2.new(1, -10, 1, 0)
statusLbl.Position = UDim2.new(0, 10, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "[0%] Ready."
statusLbl.TextColor3 = Theme.Text
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local function updateStatus(pct, msg, isErr)
	pct = math.clamp(pct, 0, 100)
	tweenService:Create(statusFill, TweenInfo.new(0.15), { Size = UDim2.new(pct / 100, 0, 1, 0) }):Play()
	if isErr then
		statusFill.BackgroundColor3 = Theme.Err
		statusLbl.Text = " ❌ " .. tostring(msg)
	else
		statusFill.BackgroundColor3 = Theme.Accent
		statusLbl.Text = string.format(" [%d%%] %s", pct, tostring(msg))
	end
end

-- Camera ref for viewport clamping (declared BEFORE makeDraggable so the
-- closure binds this local as an upvalue, not a global).
local cameraRef = workspaceService.CurrentCamera
workspaceService:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	cameraRef = workspaceService.CurrentCamera
end)

-- --------------------------------------------------------------------------
-- Custom drag (mobile + PC). Replaces the deprecated `Draggable` property.
-- A press under DRAG_THRESHOLD counts as a click -> fires onClick.
-- Uses AbsolutePosition so Scale-based initial positions (e.g. the floating
-- button's 0.4 Y) don't snap to 0 on the first drag.
-- --------------------------------------------------------------------------
local function makeDraggable(handle, target, onClick, persistPos)
	local dragging, dragStart, startAbs, dragMoved

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragMoved = false
			dragStart = input.Position
			startAbs = target.AbsolutePosition
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			if delta.Magnitude > DRAG_THRESHOLD then dragMoved = true end
			local viewSize = cameraRef and cameraRef.ViewportSize or Vector2.new(800, 600)
			-- Convert Scale/Offset mix to pure offset via the captured absolute pos.
			local newX = startAbs.X + delta.X
			local newY = startAbs.Y + delta.Y
			-- Clamp so the handle stays at least partly on-screen.
			newX = math.clamp(newX, -target.AbsoluteSize.X + 80, viewSize.X - 80)
			newY = math.clamp(newY, 0, viewSize.Y - 30)
			target.Position = UDim2.new(0, newX, 0, newY)
		end
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging and not dragMoved and onClick then onClick() end
			dragging = false
			-- Only the main window persists its position across re-executions.
			if persistPos then
				ConfigStore.data.WinX = target.Position.X.Offset
				ConfigStore.data.WinY = target.Position.Y.Offset
				ConfigStore.save()
			end
		end
	end)
end

-- Drag the window by its top bar (persist position); click the floating K
-- toggles visibility (don't persist the button's position).
makeDraggable(topBar, mainFrame, nil, true)
makeDraggable(toggleBtn, toggleBtn, function()
	mainFrame.Visible = not mainFrame.Visible
end, false)

-- --------------------------------------------------------------------------
-- Tab system.
-- --------------------------------------------------------------------------
local Tabs = {}

local function createTab(name, layoutOrder)
	local btn = new("TextButton", nil, sidebar)
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Theme.Pill
	btn.Text = name
	btn.TextColor3 = Theme.TextDim
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 11
	btn.LayoutOrder = layoutOrder
	corner(btn, UDim.new(0, 6))

	local page = new("Frame", nil, pageContainer)
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false

	btn.MouseButton1Click:Connect(function()
		for _, tab in ipairs(Tabs) do
			tab.Page.Visible = false
			tab.Btn.BackgroundColor3 = Theme.Pill
			tab.Btn.TextColor3 = Theme.TextDim
		end
		page.Visible = true
		btn.BackgroundColor3 = Theme.PillOn
		btn.TextColor3 = Theme.Text
	end)

	table.insert(Tabs, { Btn = btn, Page = page })
	if #Tabs == 1 then
		page.Visible = true
		btn.BackgroundColor3 = Theme.PillOn
		btn.TextColor3 = Theme.Text
	end
	return page
end

-- ============================================================================
-- FUNCTION 1: DUPLICATE MAP ENGINE  (with include-options)
-- ============================================================================
local mapPage = createTab("🗺️ Dupe Map", 1)

-- Filename input.
local fileBoxBg = new("Frame", nil, mapPage)
fileBoxBg.Size = UDim2.new(1, -10, 0, 32)
fileBoxBg.Position = UDim2.new(0, 5, 0, 8)
fileBoxBg.BackgroundColor3 = Theme.Panel
corner(fileBoxBg)

local fileBox = new("TextBox", nil, fileBoxBg)
fileBox.Size = UDim2.new(1, -20, 1, 0)
fileBox.Position = UDim2.new(0, 10, 0, 0)
fileBox.BackgroundTransparency = 1
fileBox.Text = ConfigStore.data.MapFileName
fileBox.TextColor3 = Theme.Text
fileBox.Font = Enum.Font.Gotham
fileBox.TextSize = 11
fileBox.TextXAlignment = Enum.TextXAlignment.Left
fileBox.PlaceholderText = "filename.rbxl"

fileBox.FocusLost:Connect(function()
	if fileBox.Text ~= "" then
		ConfigStore.data.MapFileName = fileBox.Text
		ConfigStore.save()
	end
end)

-- Checkbox helper for include-options.
local function createCheckbox(parent, label, default, posY, key)
	local box = new("TextButton", nil, parent)
	box.Size = UDim2.new(0.5, -8, 0, 26)
	box.Position = posY
	box.BackgroundColor3 = Theme.Pill
	box.Text = (default and "☑ " or "☐ ") .. label
	box.TextColor3 = Theme.Text
	box.Font = Enum.Font.Gotham
	box.TextSize = 11
	box.TextXAlignment = Enum.TextXAlignment.Left
	corner(box)
	local pad = new("UIPadding", nil, box)
	pad.PaddingLeft = UDim.new(0, 10)

	local state = default
	box.MouseButton1Click:Connect(function()
		state = not state
		ConfigStore.data.Options[key] = state
		box.Text = (state and "☑ " or "☐ ") .. label
		ConfigStore.save()
	end)
	return box, function() return state end
end

-- Two columns of toggles.
local mapOptions = ConfigStore.data.Options
local cb1 = createCheckbox(mapPage, "RemovePlayer (Animator guard)", mapOptions.RemovePlayer, UDim2.new(0, 5, 0, 46), "RemovePlayer")
local cb2 = createCheckbox(mapPage, "ReplicatedStorage", mapOptions.ReplicatedStorage, UDim2.new(0.5, 3, 0, 46), "ReplicatedStorage")
local cb3 = createCheckbox(mapPage, "Lighting", mapOptions.Lighting, UDim2.new(0, 5, 0, 76), "Lighting")
local cb4 = createCheckbox(mapPage, "StarterPack", mapOptions.StarterPack, UDim2.new(0.5, 3, 0, 76), "StarterPack")
local cb5 = createCheckbox(mapPage, "StarterGui", mapOptions.StarterGui, UDim2.new(0, 5, 0, 106), "StarterGui")

-- Save button.
local saveMapBtn = new("TextButton", nil, mapPage)
saveMapBtn.Size = UDim2.new(1, -10, 0, 40)
saveMapBtn.Position = UDim2.new(0, 5, 0, 140)
saveMapBtn.BackgroundColor3 = Theme.Accent
saveMapBtn.Text = "💾 SAVE MAP FILE (.RBXL)"
saveMapBtn.TextColor3 = Theme.Text
saveMapBtn.Font = Enum.Font.GothamBold
saveMapBtn.TextSize = 12
corner(saveMapBtn)

local mapInfoLbl = new("TextLabel", nil, mapPage)
mapInfoLbl.Size = UDim2.new(1, -10, 0, 150)
mapInfoLbl.Position = UDim2.new(0, 5, 0, 188)
mapInfoLbl.BackgroundTransparency = 1
mapInfoLbl.Text = "📌 คำแนะนำฟังก์ชัน Duplicate Map:\n\n"
	.. "• ดึงโครงสร้างแมพ วัตถุ 3D ฉาก และอาวุธทั้งหมด\n"
	.. "• เปิด/ปิดส่วนที่จะรวมได้ที่ตัวเลือกด้านบน (toggle)\n"
	.. "• RemovePlayer ป้องกัน Animator Error ตอนเปิดใน Studio\n"
	.. "• หาก executor ล็อกสิทธิ์เขียนไฟล์ ระบบจะคัดลอกสรุปลง Clipboard ให้อัตโนมัติ"
mapInfoLbl.TextColor3 = Theme.TextDim
mapInfoLbl.TextSize = 11
mapInfoLbl.Font = Enum.Font.Gotham
mapInfoLbl.TextWrapped = true
mapInfoLbl.TextYAlignment = Enum.TextYAlignment.Top

saveMapBtn.MouseButton1Click:Connect(function()
	local fileName = ConfigStore.data.MapFileName
	if not fileName:match("%.rbxl$") and not fileName:match("%.rbxlx$") then
		fileName = fileName .. ".rbxl"
	end

	local opts = ConfigStore.data.Options
	local saveFn = getSaveInstance()

	if not saveFn then
		updateStatus(100, "saveinstance not supported on this executor", true)
		sendNotify("KOI56", "ตัวรันนี้ไม่รองรับ saveinstance — จะคัดลอกสรุปลง Clipboard แทน")
		-- Still hand the user a structure summary.
		local total = #workspaceService:GetDescendants()
		setClipboardText(string.format("-- KOI56 MAP BACKUP\n-- PlaceId: %d\n-- Workspace objects: %d\n", game.PlaceId, total))
		return
	end

	sendNotify("KOI56", "เริ่มสแกนคัดลอกแมพและอาวุธ...")
	updateStatus(10, "Indexing game objects...")

	task.spawn(function()
		local targets = workspaceService:GetDescendants()
		local total = #targets
		if total == 0 then total = 1 end

		-- Progress sweep (UI feedback while indexing).
		for i = 1, total, 50 do
			local pct = math.floor((i / total) * 70)
			updateStatus(pct, string.format("Scanning: %d/%d objects", i, total))
			task.wait(0.002)
		end

		-- Build ExtraInstances from toggles.
		local extra = {}
		if opts.ReplicatedStorage then table.insert(extra, replicatedStorage) end
		if opts.Lighting then table.insert(extra, lightingService) end
		if opts.StarterPack then table.insert(extra, starterPack) end
		if opts.StarterGui then table.insert(extra, starterGui) end

		updateStatus(80, "Writing place file: " .. fileName)
		task.wait(0.2)

		local saved = false
		local err
		saved, err = pcall(function()
			saveFn({
				FilePath = fileName,
				Decompile = true,
				NilInstances = true,
				RemovePlayer = opts.RemovePlayer,
				ExtraInstances = extra,
			})
		end)

		if saved then
			updateStatus(100, "MAP DUMP COMPLETE! File: " .. fileName)
			sendNotify("KOI56 Success", "บันทึกไฟล์แมพ " .. fileName .. " สำเร็จ 100%!")
		else
			-- Disk write blocked / unsupported flag: fall back to clipboard summary.
			local summary = string.format(
				"-- KOI56 MAP BACKUP\n-- PlaceId: %d\n-- Objects: %d\n-- saveinstance error: %s\n",
				game.PlaceId, total, tostring(err)
			)
			setClipboardText(summary)
			updateStatus(100, "COPIED TO CLIPBOARD (saveinstance failed)")
			sendNotify("KOI56 Alert", "เซฟไม่สำเร็จ จึงคัดลอกสรุปลง Clipboard แทน")
		end
	end)
end)

-- ============================================================================
-- FUNCTION 2: SCRIPT & DATA SCRAPER  (with search + class filter + stats)
-- ============================================================================
local dumpPage = createTab("📜 Script Scraper", 2)

-- Top: scrape button.
local scrapeBtn = new("TextButton", nil, dumpPage)
scrapeBtn.Size = UDim2.new(1, -10, 0, 32)
scrapeBtn.Position = UDim2.new(0, 5, 0, 6)
scrapeBtn.BackgroundColor3 = Theme.Ok
scrapeBtn.Text = "⚡ SCRAPE ALL SCRIPTS & MAP STRUCTURE"
scrapeBtn.TextColor3 = Theme.Text
scrapeBtn.Font = Enum.Font.GothamBold
scrapeBtn.TextSize = 11
corner(scrapeBtn)

-- Search box.
local searchBg = new("Frame", nil, dumpPage)
searchBg.Size = UDim2.new(1, -10, 0, 28)
searchBg.Position = UDim2.new(0, 5, 0, 42)
searchBg.BackgroundColor3 = Theme.Panel
corner(searchBg)

local searchBox = new("TextBox", nil, searchBg)
searchBox.Size = UDim2.new(1, -20, 1, 0)
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 ค้นหาตามชื่อ / พาธ (เช่น MainModule, ReplicatedStorage)"
searchBox.TextColor3 = Theme.Text
searchBox.PlaceholderColor3 = Theme.TextDim
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false

-- Filter pills row.
local pillsRow = new("Frame", nil, dumpPage)
pillsRow.Size = UDim2.new(1, -10, 0, 24)
pillsRow.Position = UDim2.new(0, 5, 0, 74)
pillsRow.BackgroundTransparency = 1

local pillsLayout = new("UIListLayout", nil, pillsRow)
pillsLayout.FillDirection = Enum.FillDirection.Horizontal
pillsLayout.SortOrder = Enum.SortOrder.LayoutOrder
pillsLayout.Padding = UDim.new(0, 6)

-- Stats line.
local statsLbl = new("TextLabel", nil, dumpPage)
statsLbl.Size = UDim2.new(1, -10, 0, 18)
statsLbl.Position = UDim2.new(0, 5, 0, 100)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "ยังไม่ได้สแกน — กดปุ่ม SCRAPE ด้านบน"
statsLbl.TextColor3 = Theme.TextDim
statsLbl.TextSize = 10
statsLbl.Font = Enum.Font.Gotham
statsLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Copy button.
local copyBtn = new("TextButton", nil, dumpPage)
copyBtn.Size = UDim2.new(1, -10, 0, 26)
copyBtn.Position = UDim2.new(0, 5, 0, 120)
copyBtn.BackgroundColor3 = Theme.Info
copyBtn.Text = "📋 COPY CURRENTLY SHOWN CODE TO CLIPBOARD"
copyBtn.TextColor3 = Theme.Text
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 10
corner(copyBtn)

-- Output box.
local outBg = new("Frame", nil, dumpPage)
outBg.Size = UDim2.new(1, -10, 1, -156)
outBg.Position = UDim2.new(0, 5, 0, 152)
outBg.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
corner(outBg)

local outBox = new("TextBox", nil, outBg)
outBox.Size = UDim2.new(1, -12, 1, -12)
outBox.Position = UDim2.new(0, 6, 0, 6)
outBox.BackgroundTransparency = 1
outBox.TextColor3 = Theme.Code
outBox.Font = Enum.Font.Code
outBox.TextSize = 10
outBox.TextXAlignment = Enum.TextXAlignment.Left
outBox.TextYAlignment = Enum.TextYAlignment.Top
outBox.ClearTextOnFocus = false
outBox.MultiLine = true
outBox.Text = "-- กด 'SCRAPE ALL SCRIPTS' ด้านบนเพื่อสกัดซอร์สโค้ดของเกม...\n-- โค้ดจะแสดงที่นี่ ใช้ช่องค้นหา/ตัวกรองด้านบนเพื่อกรองผลลัพธ์"

-- --------------------------------------------------------------------------
-- Scrape state + filtered render.
-- --------------------------------------------------------------------------
local scrape = {
	scripts = {},  -- { path=string, class=string ("LocalScript"|"ModuleScript"), source=string }
	tools    = {}, -- { name=string, class=string, path=string }
	workspace = {},-- { name=string, class=string }
}

-- Active filters: map of className -> bool. "All" resets the others.
local activeFilters = { All = true, LocalScript = false, ModuleScript = false, Tool = false }

-- Build the text currently shown given search + filters.
local function buildFilteredText()
	local q = searchBox.Text:gsub("%s+", " ")
	q = q:lower()
	if q == " " then q = "" end

	local showLS   = activeFilters.All or activeFilters.LocalScript
	local showMS   = activeFilters.All or activeFilters.ModuleScript
	local showTool = activeFilters.All or activeFilters.Tool

	local lines = {}
	table.insert(lines, "-- ============================================================================")
	table.insert(lines, "-- KOI56 SCRAPED GAME SOURCE CODE & HIERARCHY")
	table.insert(lines, string.format("-- PlaceId: %d | Game Name: %s", game.PlaceId, game.Name))
	table.insert(lines, "-- ============================================================================\n")

	local shownScripts, shownTools = 0, 0

	if showLS or showMS then
		table.insert(lines, "-- [ SECTION 1: SOURCE SCRIPTS ] --\n")
		for _, s in ipairs(scrape.scripts) do
			local classOk = (s.class == "LocalScript" and showLS) or (s.class == "ModuleScript" and showMS)
			if classOk then
				local hay = (s.path .. " " .. s.class):lower()
				if q == "" or hay:find(q, 1, true) then
					shownScripts = shownScripts + 1
					table.insert(lines, string.format("-- SCRIPT: %s [%s]", s.path, s.class))
					if s.source and s.source ~= "" then
						table.insert(lines, s.source)
					else
						table.insert(lines, "-- [Protected or Empty Script]")
					end
					table.insert(lines, "\n----------------------------------------------------------------------------\n")
				end
			end
		end
	end

	if showTool then
		table.insert(lines, "\n-- [ SECTION 2: WEAPONS & TOOLS HIERARCHY ] --\n")
		for _, t in ipairs(scrape.tools) do
			local hay = (t.path .. " " .. t.name .. " " .. t.class):lower()
			if q == "" or hay:find(q, 1, true) then
				shownTools = shownTools + 1
				table.insert(lines, string.format("Tool: %s | Class: %s | Path: %s", t.name, t.class, t.path))
			end
		end
	end

	-- Workspace tree only shows when "All" and no query (avoid noise).
	if activeFilters.All and q == "" then
		table.insert(lines, "\n-- [ SECTION 3: WORKSPACE OBJECTS ] --\n")
		for _, w in ipairs(scrape.workspace) do
			table.insert(lines, string.format("Workspace Tree: %s [%s]", w.name, w.class))
		end
	end

	local totalScripts = #scrape.scripts
	local lsCount, msCount = 0, 0
	for _, s in ipairs(scrape.scripts) do
		if s.class == "LocalScript" then lsCount = lsCount + 1 else msCount = msCount + 1 end
	end

	statsLbl.Text = string.format(
		"แสดง %d / %d สคริปต์ · %d / %d Tools  |  รวม: LocalScript %d · ModuleScript %d",
		shownScripts, totalScripts, shownTools, #scrape.tools, lsCount, msCount
	)

	return table.concat(lines, "\n")
end

local function rerender()
	if #scrape.scripts == 0 and #scrape.tools == 0 then return end -- nothing scraped yet
	outBox.Text = buildFilteredText()
end

-- Filter pill builder.
local function createPill(label, key)
	local pill = new("TextButton", nil, pillsRow)
	pill.Size = UDim2.new(0, 90, 1, 0)
	pill.BackgroundColor3 = activeFilters[key] and Theme.PillOn or Theme.Pill
	pill.Text = label
	pill.TextColor3 = activeFilters[key] and Theme.Text or Theme.TextDim
	pill.Font = Enum.Font.GothamMedium
	pill.TextSize = 10
	pill.LayoutOrder = ({ All = 1, LocalScript = 2, ModuleScript = 3, Tool = 4 })[key]
	corner(pill, UDim.new(0, 6))

	pill.MouseButton1Click:Connect(function()
		if key == "All" then
			for k in pairs(activeFilters) do activeFilters[k] = (k == "All") end
		else
			activeFilters.All = false
			activeFilters[key] = not activeFilters[key]
			-- If everything off, fall back to All.
			local any = false
			for k, v in pairs(activeFilters) do if k ~= "All" and v then any = true break end end
			if not any then activeFilters.All = true end
		end
		-- Refresh pill colors.
		for _, child in ipairs(pillsRow:GetChildren()) do
			if child:IsA("TextButton") and child:GetAttribute("key") then
				local k = child:GetAttribute("key")
				child.BackgroundColor3 = activeFilters[k] and Theme.PillOn or Theme.Pill
				child.TextColor3 = activeFilters[k] and Theme.Text or Theme.TextDim
			end
		end
		rerender()
	end)
	pill:SetAttribute("key", key)
	return pill
end

createPill("All", "All")
createPill("LocalScript", "LocalScript")
createPill("ModuleScript", "ModuleScript")
createPill("Tool", "Tool")

-- Re-render on search typing (debounced lightly).
local searchConn
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if searchConn then searchConn:Disconnect() end
	searchConn = runService.Heartbeat:Wait()
	rerender()
end)

-- ---- Scrape action ----
scrapeBtn.MouseButton1Click:Connect(function()
	if not Cap.decompile and not Cap.getscriptbytecode then
		updateStatus(100, "decompile/getscriptbytecode not available", true)
		sendNotify("KOI56", "ตัวรันนี้ไม่รองรับ decompile — จะสแกนเฉพาะโครงสร้าง")
	end

	updateStatus(10, "Scraping LocalScripts, Modules & Tools...")

	task.spawn(function()
		-- Reset cache.
		scrape.scripts = {}
		scrape.tools = {}
		scrape.workspace = {}

		local function decompileScript(inst)
			local src = nil
			if Cap.decompile then
				pcall(function() src = decompile(inst) end)
			end
			if (not src or src == "") and Cap.getscriptbytecode then
				pcall(function()
					local bc = getscriptbytecode(inst)
					src = bc and ("-- [bytecode, " .. #bc .. " bytes]\n" .. bc) or nil
				end)
			end
			if not src or src == "" then
				pcall(function() src = inst.Source end)
			end
			return src
		end

		local scriptCount = 0
		local toolCount = 0
		local total = #game:GetDescendants()
		if total == 0 then total = 1 end

		for i, inst in ipairs(game:GetDescendants()) do
			if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
				scriptCount = scriptCount + 1
				table.insert(scrape.scripts, {
					path = inst:GetFullName(),
					class = inst.ClassName,
					source = decompileScript(inst) or "",
				})
			elseif inst:IsA("Tool") or inst:IsA("HopperBin") then
				toolCount = toolCount + 1
				table.insert(scrape.tools, {
					name = inst.Name,
					class = inst.ClassName,
					path = inst:GetFullName(),
				})
			end
			if i % 100 == 0 then
				updateStatus(math.floor((i / total) * 90), string.format("Scraping: %d/%d", i, total))
				task.wait(0.001)
			end
		end

		for _, child in ipairs(workspaceService:GetChildren()) do
			table.insert(scrape.workspace, { name = child.Name, class = child.ClassName })
		end

		-- Render + persist + clipboard.
		outBox.Text = buildFilteredText()

		if Cap.writefile then
			pcall(writefile, ConfigStore.data.DumpFileName, outBox.Text)
		end
		setClipboardText(outBox.Text)

		updateStatus(100, string.format("Scraped %d Scripts & %d Tools!", scriptCount, toolCount))
		sendNotify("KOI56 Dumper", string.format("สกัดโค้ดสำเร็จ! %d สคริปต์ · %d Tools", scriptCount, toolCount))
	end)
end)

copyBtn.MouseButton1Click:Connect(function()
	if outBox.Text ~= "" then
		setClipboardText(outBox.Text)
		updateStatus(100, "SHOWN CODE COPIED TO CLIPBOARD!")
		sendNotify("KOI56", "คัดลอกซอร์สโค้ดที่แสดงอยู่ลง Clipboard เรียบร้อย!")
	end
end)

-- Persist config when the UI is destroyed (re-execution / leave).
screenGui.AncestryChanged:Connect(function(_, parent)
	if not parent then ConfigStore.save() end
end)

updateStatus(100, "KOI56 Core Engine v2 Ready.")
