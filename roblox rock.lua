--[[
=================================================================================
  MobileUI  —  ไลบรารี UI สำหรับมือถือ (Roblox Luau)
=================================================================================
  วัตถุประสงค์:
    สร้างหน้าต่าง UI แบบ "ลากได้" (Draggable) พร้อมปุ่มลอย (Floating Action Button)
    สำหรับเกม Roblox ที่คุณเป็นเจ้าของ/กำลังพัฒนา เหมาะกับหน้าจอสัมผัส

  วิธีใช้งาน (วางใน StarterGui → StarterPlayerScripts หรือเรียกจาก LocalScript):
    local MobileUI = require(script.Parent.MobileUI)
    local win = MobileUI:CreateWindow({ Name = "ตั้งค่า", Size = UDim2.new(0,300,0,420) })
    win:AddButton("เริ่ม", function() print("กดแล้ว") end)
    win:AddToggle("เปิดเสียง", false, function(on) print(on) end)

  หมายเหตุ: ไลบรารีนี้ทำงานในกรอบมาตรฐานของ Roblox (parent ไปที่ PlayerGui)
=================================================================================
--]]

--// == Services == -- ดึง Service ที่จำเป็นจากเอนจิน
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
-- รอ PlayerGui ให้พร้อม (อาจยังไม่ถูกสร้างตอนเริ่มเกม)
local playerGui = player:WaitForChild("PlayerGui")

--// == โมดูลหลัก == --
local MobileUI = {}

--// == ชุดสี (Theme) == -- ปรับแต่งได้ตามใจ
MobileUI.Themes = {
	Dark = {
		Background   = Color3.fromRGB(24, 26, 31),
		Header       = Color3.fromRGB(34, 37, 44),
		Text         = Color3.fromRGB(235, 238, 244),
		Accent       = Color3.fromRGB(88, 133, 255),
		AccentText   = Color3.fromRGB(255, 255, 255),
		Stroke       = Color3.fromRGB(55, 59, 68),
		Button       = Color3.fromRGB(45, 48, 56),
		ButtonHover  = Color3.fromRGB(60, 64, 74),
		FAB          = Color3.fromRGB(88, 133, 255),
		TrackOff     = Color3.fromRGB(70, 74, 84),
	},
	Light = {
		Background   = Color3.fromRGB(245, 246, 248),
		Header       = Color3.fromRGB(255, 255, 255),
		Text         = Color3.fromRGB(28, 30, 35),
		Accent       = Color3.fromRGB(88, 133, 255),
		AccentText   = Color3.fromRGB(255, 255, 255),
		Stroke       = Color3.fromRGB(210, 214, 220),
		Button       = Color3.fromRGB(232, 234, 238),
		ButtonHover  = Color3.fromRGB(216, 220, 226),
		FAB          = Color3.fromRGB(88, 133, 255),
		TrackOff     = Color3.fromRGB(190, 195, 202),
	},
}

--// == ค่าคงที่ == --
local FAB_SIZE = 56          -- ขนาดปุ่มลอย (px) ใหญ่พอใช้นิ้วแตะสบาย
local TOUCH_MIN = 44         -- ขนาดน้อยสุดที่แนะนำสำหรับปุ่มสัมผัส
local TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_THEME = MobileUI.Themes.Dark

--// == ตัวช่วยสร้าง instance == -- ลดโค้ดซ้ำ
local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

-- เพิ่มมุมโค้งให้ instance
local function addCorner(inst, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = inst })
	return inst
end

-- เพิ่มเส้นขอบ
local function addStroke(inst, color, thickness, transparency)
	local s = make("UIStroke", {
		Color = color or Color3.new(0,0,0),
		Thickness = thickness or 1,
		Transparency = transparency or 0.5,
		Parent = inst,
	})
	return s
end

--// == ระบบลากหน้าต่าง (Drag) == -- รองรับทั้งเมาส์และสัมผัสมือถือ
local function makeDraggable(frame, handle)
	-- handle คือส่วนที่ใช้ "จับ" ลาก (ปกติคือแถบหัวข้อ)
	local dragging = false
	local startInput, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// == ปุ่มปรับสีตอน hover/แตะ == --
local function bindHover(button, normalColor, hoverColor)
	button.MouseEnter:Connect(function()
		if UserInputService.TouchEnabled then return end -- มือถือไม่มี hover
		TweenService:Create(button, TWEEN_INFO, { BackgroundColor3 = hoverColor }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TWEEN_INFO, { BackgroundColor3 = normalColor }):Play()
	end)
end


--//===================================================================================
--//   สร้างหน้าต่างหลัก (Window)
--//===================================================================================
function MobileUI:CreateWindow(config)
	config = config or {}
	local theme = config.Theme or DEFAULT_THEME
	local winName = config.Name or "Window"
	local winSize = config.Size or UDim2.new(0, 300, 0, 420)
	local winPos = config.Position or UDim2.new(0.5, -winSize.X.Offset/2, 0.5, -winSize.Y.Offset/2)

	-- ScreenGui หลัก (ResetOnSpawn=false เพื่อไม่ให้หายเมื่อเกิดใหม่)
	local screen = make("ScreenGui", {
		Name = winName .. "_MobileUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = config.DisplayOrder or 50,
		IgnoreGuiInset = true,
		Parent = playerGui,
	})

	-- ===== ปุ่มลอย (Floating Action Button) =====
	local fab = addCorner(make("TextButton", {
		Name = "FAB",
		Size = UDim2.new(0, FAB_SIZE, 0, FAB_SIZE),
		Position = UDim2.new(1, -(FAB_SIZE + 16), 1, -(FAB_SIZE + 16)),
		BackgroundColor3 = theme.FAB,
		Text = "+",
		TextColor3 = Color3.new(1,1,1),
		Font = Enum.Font.GothamBold,
		TextSize = 32,
		AutoButtonColor = false,
		Parent = screen,
	}), FAB_SIZE/2)
	addStroke(fab, Color3.new(0,0,0), 1, 0.6)
	make("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = theme.FAB, Parent = fab })

	-- ===== กรอบหน้าต่างหลัก =====
	local window = addCorner(make("Frame", {
		Name = "Window",
		Size = winSize,
		Position = winPos,
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Visible = false, -- เริ่มต้นซ่อน กด FAB เพื่อเปิด
		Parent = screen,
	}), 12)
	addStroke(window, theme.Stroke, 1.5, 0.2)

	-- ===== แถบหัวข้อ (ใช้ลากได้) =====
	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		Parent = window,
	})
	addCorner(header, 12) -- โค้งบน ล่างจะถูกปิดด้วยเนื้อหา

	-- ปิดมุมล่างของ header ด้วยแถบเล็ก ให้ตรงกับมุมบนของเนื้อหา
	make("Frame", {
		Name = "HeaderFill",
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		Parent = header,
	})

	local title = make("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -90, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = winName,
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- ปุ่มปิด/ย่อ (ซ่อนหน้าต่าง)
	local closeBtn = make("TextButton", {
		Name = "Close",
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -38, 0.5, -16),
		BackgroundColor3 = theme.Header,
		Text = "✕",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = false,
		Parent = header,
	})

	-- ===== พื้นที่เนื้อหาแบบเลื่อนได้ (ScrollingFrame) =====
	local content = make("ScrollingFrame", {
		Name = "Content",
		Size = UDim2.new(1, -16, 1, -52),
		Position = UDim2.new(0, 8, 0, 46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = window,
	})
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = content,
	})
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = content,
	})

	-- ===== ตรรกะเปิด/ปิดด้วย FAB =====
	local isOpen = false
	local function setOpen(open)
		isOpen = open
		TweenService:Create(fab, TWEEN_INFO, { Rotation = open and 135 or 0 }):Play()
		TweenService:Create(window, TWEEN_INFO, {
			Visible = open,
		}):Play()
		if open then
			window.Visible = true -- ให้ visible ก่อนค่อยทำแอนิเมชัน
		end
	end

	fab.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)

	makeDraggable(window, header)

	-- ===== API สำหรับเพิ่ม component =====
	local windowObj = {}
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	-- ปุ่มธรรมดา
	function windowObj:AddButton(label, callback)
		local btn = addCorner(make("TextButton", {
			Name = "Btn_" .. tostring(label),
			Size = UDim2.new(1, -16, 0, TOUCH_MIN),
			BackgroundColor3 = theme.Button,
			Text = label or "Button",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			AutoButtonColor = false,
			LayoutOrder = nextOrder(),
			Parent = content,
		}), 8)
		addStroke(btn, theme.Stroke, 1, 0.4)
		bindHover(btn, theme.Button, theme.ButtonHover)

		btn.MouseButton1Click:Connect(function()
			-- เอฟเฟกต์กด
			TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = theme.Accent }):Play()
			task.delay(0.12, function()
				TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = theme.Button }):Play()
			end)
			if callback then
				task.spawn(callback) -- รัน callback ใน thread แยก ป้องกันบล็อก UI
			end
		end)
		return btn
	end

	-- สวิตช์เปิด/ปิด
	function windowObj:AddToggle(label, default, callback)
		local state = default and true or false
		local holder = make("Frame", {
			Name = "Toggle_" .. tostring(label),
			Size = UDim2.new(1, -16, 0, TOUCH_MIN),
			BackgroundColor3 = theme.Button,
			BorderSizePixel = 0,
			LayoutOrder = nextOrder(),
			Parent = content,
		})
		addCorner(holder, 8)
		addStroke(holder, theme.Stroke, 1, 0.4)

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			Text = label or "Toggle",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
		})

		-- รางสวิตช์
		local track = addCorner(make("Frame", {
			Name = "Track",
			Size = UDim2.new(0, 44, 0, 24),
			Position = UDim2.new(1, -56, 0.5, -12),
			BackgroundColor3 = state and theme.Accent or theme.TrackOff,
			Parent = holder,
		}), 12)

		-- ปุ่มกลมในราง
		local knob = addCorner(make("Frame", {
			Name = "Knob",
			Size = UDim2.new(0, 18, 0, 18),
			Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
			BackgroundColor3 = Color3.new(1,1,1),
			Parent = track,
		}), 9)

		local hit = make("TextButton", {
			Name = "Hit",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			Parent = holder,
		})

		local function render()
			TweenService:Create(track, TWEEN_INFO, {
				BackgroundColor3 = state and theme.Accent or theme.TrackOff,
			}):Play()
			TweenService:Create(knob, TWEEN_INFO, {
				Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
			}):Play()
		end

		hit.MouseButton1Click:Connect(function()
			state = not state
			render()
			if callback then
				task.spawn(callback, state)
			end
		end)

		local toggleObj = {}
		function toggleObj:Set(value)
			state = value and true or false
			render()
			if callback then task.spawn(callback, state) end
		end
		function toggleObj:Get()
			return state
		end
		return toggleObj
	end

	-- แถบเลื่อนค่าตัวเลข (Slider)
	function windowObj:AddSlider(label, min, max, default, callback)
		min = min or 0
		max = max or 100
		local value = math.clamp(default or min, min, max)

		local holder = make("Frame", {
			Name = "Slider_" .. tostring(label),
			Size = UDim2.new(1, -16, 0, 54),
			BackgroundColor3 = theme.Button,
			BorderSizePixel = 0,
			LayoutOrder = nextOrder(),
			Parent = content,
		})
		addCorner(holder, 8)
		addStroke(holder, theme.Stroke, 1, 0.4)

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -24, 0, 20),
			Position = UDim2.new(0, 12, 0, 6),
			BackgroundTransparency = 1,
			Text = label or "Slider",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
		})
		local valLabel = make("TextLabel", {
			Size = UDim2.new(0, 60, 0, 20),
			Position = UDim2.new(1, -72, 0, 6),
			BackgroundTransparency = 1,
			Text = tostring(value),
			TextColor3 = theme.Accent,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = holder,
		})

		local bar = addCorner(make("Frame", {
			Name = "Bar",
			Size = UDim2.new(1, -24, 0, 8),
			Position = UDim2.new(0, 12, 0, 36),
			BackgroundColor3 = theme.TrackOff,
			Parent = holder,
		}), 4)
		local fill = addCorner(make("Frame", {
			Name = "Fill",
			Size = UDim2.new((value - min) / math.max(1, max - min), 0, 1, 0),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Parent = bar,
		}), 4)
		local knob = addCorner(make("Frame", {
			Name = "Knob",
			Size = UDim2.new(0, 18, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1,1,1),
			Parent = bar,
		}), 9)

		local dragging = false
		local function updateFromInput(inputPos)
			local rel = (inputPos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
			rel = math.clamp(rel, 0, 1)
			value = math.floor(min + rel * (max - min) + 0.5)
			local pct = (value - min) / math.max(1, max - min)
			fill.Size = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, 0, 0.5, 0)
			valLabel.Text = tostring(value)
			if callback then task.spawn(callback, value) end
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input.Position)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInput(input.Position)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		local sliderObj = {}
		function sliderObj:Set(v)
			value = math.clamp(v, min, max)
			local pct = (value - min) / math.max(1, max - min)
			fill.Size = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, 0, 0.5, 0)
			valLabel.Text = tostring(value)
			if callback then task.spawn(callback, value) end
		end
		function sliderObj:Get()
			return value
		end
		return sliderObj
	end

	-- ข้อความแสดงผล
	function windowObj:AddLabel(text)
		local lbl = make("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -16, 0, 24),
			BackgroundTransparency = 1,
			Text = text or "",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamRegular,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = nextOrder(),
			Parent = content,
		})
		return lbl
	end

	-- เส้นแบ่ง
	function windowObj:AddDivider()
		make("Frame", {
			Name = "Divider",
			Size = UDim2.new(1, -16, 0, 1),
			BackgroundColor3 = theme.Stroke,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			LayoutOrder = nextOrder(),
			Parent = content,
		})
	end

	-- เปิด/ปิดด้วยโค้ด
	function windowObj:SetOpen(open)
		setOpen(open)
	end
	function windowObj:IsOpen()
		return isOpen
	end

	-- ทำลายทั้งหมด (cleanup)
	function windowObj:Destroy()
		screen:Destroy()
	end

	-- เริ่มต้นซ่อนหน้าต่างไว้ก่อน (แสดง FAB)
	return windowObj
end

return MobileUI
