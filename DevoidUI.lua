--[[
	DevoidUi - Roblox Luau UI library
	Updated with full component support, customizable themes, and mobile toggle icon options.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Library = {}
Library.__index = Library
local Page, Tab = {}, {}
Page.__index = Page
Tab.__index = Tab

----------------------------------------------------------------------
-- Default Theme & helpers
----------------------------------------------------------------------
local DefaultTheme = {
	Bg = Color3.fromHex("#0B0B0B"),
	Panel = Color3.fromHex("#121212"),
	Raised = Color3.fromHex("#1A1A1A"),
	Hover = Color3.fromHex("#242424"),
	Track = Color3.fromHex("#2A2A2A"),
	Stroke = Color3.fromHex("#262626"),
	Line = Color3.fromHex("#1E1E1E"),
	Text = Color3.fromHex("#F2F2F2"),
	Muted = Color3.fromHex("#8A8A8A"),
	Dim = Color3.fromHex("#5A5A5A"),
	Accent = Color3.fromHex("#E8333F"),
	AccentDark = Color3.fromHex("#2A1317"),
	Green = Color3.fromHex("#3ED598"),
	Blue = Color3.fromHex("#4C8DFF"),
	Yellow = Color3.fromHex("#F5B83D"),
	Sans = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
	Mono = Enum.Font.RobotoMono,
}

local X, Y = Enum.AutomaticSize.X, Enum.AutomaticSize.Y
local LEFT, RIGHT, CENTER = Enum.HorizontalAlignment.Left, Enum.HorizontalAlignment.Right, Enum.HorizontalAlignment.Center
local HORIZ, VERT = Enum.FillDirection.Horizontal, Enum.FillDirection.Vertical
local VCENTER = Enum.VerticalAlignment.Center
local ACCENT_DOT = '<font color="#E8333F">.</font>'

local NotifyColors = {}
local KEYS = { LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl", LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp" }

local function keyText(k)
	if not k then return "—" end
	return KEYS[k.Name] or k.Name
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function new(class, props, children)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
		if class ~= "Frame" and class ~= "ScrollingFrame" and class ~= "CanvasGroup" then
			o.BackgroundTransparency = 1
		end
	end
	if o:IsA("GuiButton") then o.AutoButtonColor = false end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
		o.Text = ""
		o.Font = Enum.Font.GothamMedium
		o.TextColor3 = Color3.new(1, 1, 1)
		o.TextSize = 14
	end
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then 
			parent = v 
		elseif k == "TextXAlignment" and typeof(v) == "EnumItem" and v.EnumType == Enum.HorizontalAlignment then
			o.TextXAlignment = Enum.TextXAlignment[v.Name]
		else 
			o[k] = v 
		end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	o.Parent = parent
	return o
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(c, t)
	return new("UIStroke", { Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0),
	})
end
local function list(dir, gap, h, v)
	return new("UIListLayout", {
		FillDirection = dir or VERT, Padding = UDim.new(0, gap or 0),
		HorizontalAlignment = h or LEFT, VerticalAlignment = v or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function hover(btn, target, normal, over)
	btn.MouseEnter:Connect(function() tween(target, 0.15, { BackgroundColor3 = over }) end)
	btn.MouseLeave:Connect(function() tween(target, 0.15, { BackgroundColor3 = normal }) end)
end

local function iconButton(parent, glyph, order, theme)
	local b = new("TextButton", {
		LayoutOrder = order, Size = UDim2.fromOffset(32, 32), BackgroundColor3 = theme.Raised, BackgroundTransparency = 0,
		Text = glyph, TextSize = 16, TextColor3 = theme.Muted, Parent = parent,
	}, { corner(8) })
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = theme.Hover, TextColor3 = theme.Text }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = theme.Raised, TextColor3 = theme.Muted }) end)
	return b
end

local function protect(gui)
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then gui.Parent = h return end
	end
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok or gui.Parent ~= CoreGui then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

----------------------------------------------------------------------
-- Window construction
----------------------------------------------------------------------
function Library.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Library)
	self.Name = opts.Name or "HUB"
	self.Version = opts.Version or "V1.0"
	self.Badge = opts.Badge
	self.Status = opts.Status or "SAFE"
	self.StatusColor = opts.StatusColor or DefaultTheme.Green
	self.StatusPosition = opts.StatusPosition or "BottomLeft"
	self.Logo = opts.Logo
	self.Avatar = opts.Avatar
	self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	self.IsPremium = opts.IsPremium or false
	self.IsTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled
	self.Layout = opts.Layout or (self.IsTouch and "Compact" or "Wide")
	self.ToggleIcon = opts.ToggleIcon -- Can be text or asset image string (e.g. "rbxassetid://...")
	self.Mode = "Hidden"

	-- Setup Theme customization
	self.Theme = table.clone(DefaultTheme)
	if opts.Theme then
		for k, v in pairs(opts.Theme) do
			self.Theme[k] = v
		end
	end
	NotifyColors = { info = self.Theme.Blue, success = self.Theme.Green, warning = self.Theme.Yellow, error = self.Theme.Accent }

	self.Flags, self.Objects, self.Pages, self.Binds, self.Features, self.Index, self._conns = {}, {}, {}, {}, {}, {}, {}
	self._groups, self._groupCount, self._notifOrder, self._winToken = {}, 0, 0, 0
	self.UI = {}
	self:_build(opts)
	self:_connect()
	self:_applyLayout()
	self:SetMode("Normal")
	return self
end

function Library:_build(opts)
	local ui = self.UI
	local theme = self.Theme
	local gui = new("ScreenGui", {
		Name = "DevoidUi_" .. math.random(1000, 9999), ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	protect(gui)
	ui.Gui = gui

	ui.Holder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(720, 460),
		BackgroundTransparency = 1, Visible = false, Parent = gui,
	})
	local win = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(720, 460),
		BackgroundColor3 = theme.Bg, Parent = ui.Holder,
	}, { corner(14), stroke(theme.Stroke) })
	ui.Win = win
	ui.WinScale = new("UIScale", { Parent = win })
	ui.Anim = Instance.new("NumberValue")
	ui.Anim.Value = 1
	ui.Anim.Changed:Connect(function() self:_applyScale() end)
	self._base = 1

	-- Top bar
	ui.Top = new("Frame", {
		Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 48), BackgroundColor3 = theme.Panel, Parent = win,
	}, { corner(12), stroke(theme.Stroke) })

	local left = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = X, BackgroundTransparency = 1, Parent = ui.Top,
	}, { pad(14, 0, 0, 0), list(HORIZ, 8, LEFT, VCENTER) })

	if self.Logo then
		new("ImageLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(22, 22), Image = self.Logo, Parent = left })
	else
		new("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(18, 22), Text = "D", Font = theme.Black, TextSize = 22, TextColor3 = theme.Accent, Parent = left })
	end
	new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 20), AutomaticSize = X, Text = self.Name, Font = theme.Bold, TextSize = 15, TextColor3 = theme.Text, Parent = left })
	ui.Version = new("TextLabel", {
		LayoutOrder = 3, Size = UDim2.fromOffset(0, 12), AutomaticSize = X, Text = "HUB " .. self.Version,
		Font = theme.Mono, TextSize = 10, TextColor3 = theme.Dim, Parent = left,
	})
	if self.Badge then
		ui.BadgePill = new("Frame", {
			LayoutOrder = 4, Size = UDim2.fromOffset(0, 22), AutomaticSize = X, BackgroundColor3 = theme.Raised, Parent = left,
		}, { corner(11), pad(9, 0, 10, 0), list(HORIZ, 6, LEFT, VCENTER) })
		new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(6, 6), BackgroundColor3 = theme.Green, Parent = ui.BadgePill }, { corner(3) })
		new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 14), AutomaticSize = X, Text = self.Badge, TextSize = 11, TextColor3 = theme.Text, Parent = ui.BadgePill })
	end

	-- wide right side
	ui.RightWide = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(0, 32),
		AutomaticSize = X, BackgroundTransparency = 1, Parent = ui.Top,
	}, { list(HORIZ, 8, RIGHT, VCENTER) })
	ui.SearchBtn = new("TextButton", {
		LayoutOrder = 1, Size = UDim2.fromOffset(190, 32), BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Parent = ui.RightWide,
	}, { corner(8), stroke(theme.Stroke) })
	new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -80, 1, 0), Text = "Search features", TextSize = 12, TextColor3 = theme.Muted, TextXAlignment = LEFT, Parent = ui.SearchBtn })
	new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, 20), AutomaticSize = X,
		BackgroundTransparency = 0, BackgroundColor3 = theme.Bg, Text = "Ctrl K", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, Parent = ui.SearchBtn,
	}, { corner(5), stroke(theme.Stroke), pad(6, 0, 6, 0) })
	hover(ui.SearchBtn, ui.SearchBtn, theme.Raised, theme.Hover)
	ui.MinBtn = iconButton(ui.RightWide, "–", 2, theme)
	ui.CloseBtn = iconButton(ui.RightWide, "×", 3, theme)

	-- compact right side
	ui.RightCompact = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, 32),
		AutomaticSize = X, BackgroundTransparency = 1, Visible = false, Parent = ui.Top,
	}, { list(HORIZ, 6, RIGHT, VCENTER) })
	if self.Avatar then
		ui.MenuBtn = new("TextButton", { LayoutOrder = 10, Size = UDim2.fromOffset(32, 32), BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Parent = ui.RightCompact }, { corner(8), stroke(theme.Accent) })
		new("ImageLabel", { Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), Image = self.Avatar, Parent = ui.MenuBtn }, { corner(6) })
	else
		ui.MenuBtn = iconButton(ui.RightCompact, "≡", 10, theme)
	end
	ui.CmdBtn = iconButton(ui.RightCompact, "⌘", 11, theme)
	ui.ExpandBtn = iconButton(ui.RightCompact, "⤢", 12, theme)

	-- Sidebar
	ui.Sidebar = new("Frame", { Position = UDim2.fromOffset(12, 72), Size = UDim2.new(0, 150, 1, -84), BackgroundTransparency = 1, Parent = win })
	ui.SideScroll = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -30), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Y,
		CanvasSize = UDim2.new(), Parent = ui.Sidebar,
	}, { list(VERT, 2) })

	local statusPosProps = {
		BottomLeft = { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1) },
		BottomRight = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1) },
		TopLeft = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromScale(0, 0) },
		TopRight = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0) },
	}
	local chosenPos = statusPosProps[self.StatusPosition] or statusPosProps.BottomLeft

	local status = new("Frame", { AnchorPoint = chosenPos.AnchorPoint, Position = chosenPos.Position, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = ui.Sidebar }, { pad(10, 0, 0, 0), list(HORIZ, 7, LEFT, VCENTER) })
	ui.StatusDot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(6, 6), BackgroundColor3 = self.StatusColor, Parent = status }, { corner(3) })
	ui.StatusText = new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 12), AutomaticSize = X, Text = self.Status, Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, Parent = status })
	ui.Divider = new("Frame", { Position = UDim2.fromOffset(172, 72), Size = UDim2.new(0, 1, 1, -84), BackgroundColor3 = theme.Line, Parent = win })

	-- Menu bar + footer
	ui.MenuBar = new("Frame", { Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 0, 18), BackgroundTransparency = 1, Visible = false, Parent = win })
	ui.MenuLink = new("TextButton", { Size = UDim2.fromOffset(0, 18), AutomaticSize = X, Text = "←  MENU", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, Parent = ui.MenuBar })
	ui.OnWrap = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = X, BackgroundTransparency = 1, Parent = ui.MenuBar }, { list(HORIZ, 6, RIGHT, VCENTER) })
	new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(5, 5), BackgroundColor3 = theme.Accent, Parent = ui.OnWrap }, { corner(3) })
	ui.OnLabel = new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 12), AutomaticSize = X, Text = "", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, Parent = ui.OnWrap })

	ui.Footer = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -10), Size = UDim2.new(1, -24, 0, 18), BackgroundTransparency = 1, Visible = false, Parent = win })
	new("Frame", { Position = UDim2.fromOffset(0, -8), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Line, Parent = ui.Footer })
	new("TextLabel", { Size = UDim2.fromScale(0.5, 1), Text = self.ToggleKey.Name:upper() .. " — HIDE", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, TextXAlignment = LEFT, Parent = ui.Footer })
	new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.5, 1), Text = "CTRL K — SEARCH", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Muted, TextXAlignment = RIGHT, Parent = ui.Footer })

	-- Content
	ui.Content = new("Frame", { BackgroundTransparency = 1, Parent = win })
	ui.Header = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = ui.Content })
	new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Line, Parent = ui.Header })
	ui.Title = new("TextLabel", { Size = UDim2.new(0, 0, 1, -2), AutomaticSize = X, RichText = true, Font = theme.Black, TextSize = 30, TextColor3 = theme.Text, Parent = ui.Header })
	ui.TabsHost = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = X, BackgroundTransparency = 1, Parent = ui.Header })
	ui.Body = new("CanvasGroup", { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1, Parent = ui.Content })

	-- Menu overlay
	ui.Menu = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Bg, GroupTransparency = 1, Visible = false, ZIndex = 5, Parent = ui.Content })
	ui.MenuList = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 0, AutomaticCanvasSize = Y, CanvasSize = UDim2.new(), Parent = ui.Menu }, { list(VERT, 6), pad(2, 8, 2, 8) })

	-- Search palette
	ui.Palette = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 20, Parent = win })
	ui.PaletteBox = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 80), Size = UDim2.new(0.82, 0, 0, 0), AutomaticSize = Y,
		BackgroundColor3 = theme.Panel, ZIndex = 21, Parent = ui.Palette,
	}, { corner(12), stroke(theme.Stroke), list(VERT, 0), new("UISizeConstraint", { MaxSize = Vector2.new(400, 9999) }) })
	ui.SearchBox = new("TextBox", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 44), PlaceholderText = "Search features...", PlaceholderColor3 = theme.Dim, ClearTextOnFocus = false,
		TextSize = 14, TextXAlignment = LEFT, ZIndex = 22, Parent = ui.PaletteBox,
	}, { pad(14, 0, 14, 0) })
	ui.SearchResults = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, ZIndex = 22, Parent = ui.PaletteBox }, { list(VERT, 0), pad(6, 0, 6, 6) })

	-- Toast pills & notifications
	ui.Toast = new("Frame", { Position = UDim2.fromOffset(16, 64), Size = UDim2.fromOffset(440, 0), AutomaticSize = Y, BackgroundTransparency = 1, Visible = false, Parent = gui })
	local tl = list(HORIZ, 10)
	tl.Wraps = true
	tl.Parent = ui.Toast

	ui.Notifs = new("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(380, 0), AutomaticSize = Y,
		BackgroundTransparency = 1, Parent = gui,
	}, { list(VERT, 10, RIGHT, Enum.VerticalAlignment.Bottom) })

	-- Floating Action Button (FAB) supporting custom icons/text
	ui.Fab = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0, Text = (not self.ToggleIcon or self.ToggleIcon:match("^rbxassetid://")) and (self.ToggleIcon and "" or "D") or self.ToggleIcon,
		Font = theme.Black, TextSize = 22, TextColor3 = theme.Accent, Parent = gui, ZIndex = 1000,
	}, { corner(23), stroke(theme.Stroke) })
	
	if self.ToggleIcon and self.ToggleIcon:match("^rbxassetid://") then
		new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24),
			Image = self.ToggleIcon, BackgroundTransparency = 1, Parent = ui.Fab,
		})
	end

	ui.Fab.MouseButton1Click:Connect(function() self:Toggle() end)

	ui.SearchBtn.MouseButton1Click:Connect(function() self:OpenSearch() end)
	ui.CmdBtn.MouseButton1Click:Connect(function() self:OpenSearch() end)
	ui.MinBtn.MouseButton1Click:Connect(function() self:SetMode("Toast") end)
	ui.CloseBtn.MouseButton1Click:Connect(function() self:SetMode("Hidden") end)
	ui.ExpandBtn.MouseButton1Click:Connect(function() self:SetLayout("Wide") end)
	ui.MenuBtn.MouseButton1Click:Connect(function() self:_toggleMenu() end)
	ui.MenuLink.MouseButton1Click:Connect(function() self:_toggleMenu() end)
	ui.Palette.MouseButton1Click:Connect(function() self:CloseSearch() end)
	ui.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() self:_search(ui.SearchBox.Text) end)
	ui.SearchBox.FocusLost:Connect(function(enter)
		if enter then
			local first = ui.SearchResults:FindFirstChildWhichIsA("TextButton")
			if first then first:Activate() end
		end
	end)
end

function Library:_applyScale()
	self.UI.WinScale.Scale = self._base * self.UI.Anim.Value
end

function Library:_fit()
	local ui = self.UI
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s = self.Layout == "Compact" and Vector2.new(380, self.IsTouch and 440 or 470) or Vector2.new(720, 460)
	self._base = math.clamp(math.min((vp.X - 16) / s.X, (vp.Y - 16) / s.Y), 0.4, 1)
	ui.Win.Size = UDim2.fromOffset(s.X, s.Y)
	ui.Holder.Size = UDim2.fromOffset(s.X * self._base, s.Y * self._base)
	ui.Toast.Size = UDim2.fromOffset(math.min(440, vp.X - 32), 0)
	ui.Notifs.Size = UDim2.fromOffset(math.min(380, vp.X - 32), 0)
	self:_applyScale()
end

function Library:_applyLayout()
	local ui = self.UI
	local c = self.Layout == "Compact"
	ui.Top.Size = UDim2.new(1, -24, 0, c and 44 or 48)
	ui.Version.Visible = not c
	if ui.BadgePill then ui.BadgePill.Visible = not c end
	ui.RightWide.Visible = not c
	ui.RightCompact.Visible = c
	ui.Sidebar.Visible = not c
	ui.Divider.Visible = not c
	ui.MenuBar.Visible = c
	local footer = c and not self.IsTouch
	ui.Footer.Visible = footer
	if c then
		ui.Content.Position = UDim2.fromOffset(12, 90)
		ui.Content.Size = UDim2.new(1, -24, 1, footer and -128 or -102)
	else
		ui.Content.Position = UDim2.fromOffset(186, 72)
		ui.Content.Size = UDim2.new(1, -198, 1, -84)
	end
	ui.Title.TextSize = c and 26 or 30
	self:_closeOverlays()
	self:_fit()
end

----------------------------------------------------------------------
-- Modes & layouts
----------------------------------------------------------------------
function Library:SetLayout(layout)
	if layout == self.Layout then return end
	self.Layout = layout
	if self.Mode == "Normal" then
		task.spawn(function()
			tween(self.UI.Win, 0.12, { GroupTransparency = 1 })
			task.wait(0.13)
			self:_applyLayout()
			tween(self.UI.Win, 0.25, { GroupTransparency = 0 })
		end)
	else
		self:_applyLayout()
	end
end

function Library:SetMode(mode)
	if mode == "Compact" or mode == "Wide" then
		self:SetLayout(mode)
		mode = "Normal"
	end
	if mode == self.Mode then return end
	self.Mode = mode
	if mode == "Normal" then self:_showWin() else self:_hideWin() end
	if mode == "Toast" then self:_showToast() else self.UI.Toast.Visible = false end
end

function Library:Toggle()
	if self.Mode == "Normal" then
		self:SetMode("Hidden")
	else
		self:SetMode("Normal")
	end
end

function Library:_showWin()
	local ui = self.UI
	self._winToken += 1
	ui.Holder.Visible = true
	ui.Anim.Value = 0.9
	ui.Win.GroupTransparency = 1
	tween(ui.Anim, 0.45, { Value = 1 }, Enum.EasingStyle.Back)
	tween(ui.Win, 0.25, { GroupTransparency = 0 })
end

function Library:_hideWin()
	local ui = self.UI
	self._winToken += 1
	local token = self._winToken
	self:_closeOverlays()
	tween(ui.Anim, 0.2, { Value = 0.94 })
	tween(ui.Win, 0.2, { GroupTransparency = 1 })
	task.delay(0.22, function()
		if token == self._winToken then ui.Holder.Visible = false end
	end)
end

function Library:_showToast()
	local ui = self.UI
	ui.Toast.Visible = true
	local i = 0
	for _, f in ipairs(self.Features) do
		i += 1
		local sc = f.Pill.Scale
		sc.Scale = 0.6
		task.delay(i * 0.04, function() tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) end)
	end
end

----------------------------------------------------------------------
-- Input
----------------------------------------------------------------------
function Library:_connect()
	local ui = self.UI
	local function add(c) table.insert(self._conns, c) end

	local dragging, startMouse, startPos
	ui.Top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startMouse, startPos = true, i.Position, ui.Holder.Position
		end
	end)
	add(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			ui.Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	add(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))

	add(UIS.InputBegan:Connect(function(i, gpe)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if self._listening then return end
		if i.KeyCode == Enum.KeyCode.Escape and (ui.Palette.Visible or ui.Menu.Visible) then
			self:_closeOverlays()
			return
		end
		if gpe or UIS:GetFocusedTextBox() then return end
		if i.KeyCode == self.ToggleKey then self:Toggle() return end
		if i.KeyCode == Enum.KeyCode.K and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
			if self.Mode == "Normal" then
				if ui.Palette.Visible then self:CloseSearch() else self:OpenSearch() end
			end
			return
		end
		for _, b in ipairs(self.Binds) do
			if b.get() == i.KeyCode then b.fire() end
		end
	end))

	local cam = workspace.CurrentCamera
	if cam then add(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_fit() end)) end
end

----------------------------------------------------------------------
-- Pages
----------------------------------------------------------------------
function Library:AddPage(o)
	local ui = self.UI
	local theme = self.Theme
	local page = setmetatable({
		Hub = self, Name = o.Name, Group = o.Group or "GAME", Tabs = {}, Toggles = {}, Count = 0, FixedCount = o.Count,
	}, Page)

	local g = self._groups[page.Group]
	if not g then
		self._groupCount += 1
		g = { Order = self._groupCount * 1000, n = 0 }
		self._groups[page.Group] = g
		new("TextLabel", {
			LayoutOrder = g.Order, Size = UDim2.new(1, 0, 0, 30), Text = page.Group:upper(), Font = theme.Mono, TextSize = 10,
			TextColor3 = theme.Dim, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Bottom, Parent = ui.SideScroll,
		}, { pad(10, 0, 0, 6) })
	end
	g.n += 1

	page.Button = new("TextButton", { LayoutOrder = g.Order + g.n, Size = UDim2.new(1, 0, 0, 32), Parent = ui.SideScroll })
	page.NameLabel = new("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -40, 1, 0), RichText = true, Text = page.Name, TextSize = 14,
		TextColor3 = theme.Muted, TextXAlignment = LEFT, Parent = page.Button,
	})
	page.CountLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), Size = UDim2.new(0, 28, 1, 0), Font = theme.Mono,
		TextSize = 11, TextColor3 = theme.Dim, TextXAlignment = RIGHT, Parent = page.Button,
	})
	page.Button.MouseEnter:Connect(function()
		if self.CurrentPage ~= page then tween(page.NameLabel, 0.15, { TextColor3 = theme.Text }) end
	end)
	page.Button.MouseLeave:Connect(function()
		if self.CurrentPage ~= page then tween(page.NameLabel, 0.15, { TextColor3 = theme.Muted }) end
	end)
	page.Button.MouseButton1Click:Connect(function() self:Select(page) end)

	page.TabStrip = new("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = X, BackgroundTransparency = 1, Visible = false, Parent = ui.TabsHost }, { list(HORIZ, 20) })

	table.insert(self.Pages, page)
	if #self.Pages <= 2 then
		page.NavBtn = new("TextButton", {
			LayoutOrder = #self.Pages, Size = UDim2.fromOffset(0, 32), AutomaticSize = X, Text = page.Name, TextSize = 13,
			TextColor3 = theme.Muted, Parent = ui.RightCompact,
		}, { pad(8, 0, 8, 0) })
		page.NavBtn.MouseButton1Click:Connect(function() self:Select(page) end)
	end
	page:_refreshCount()
	if not self.CurrentPage then self:Select(page) end
	return page
end

function Page:_setActive(a)
	local theme = self.Hub.Theme
	self.NameLabel.Text = a and (self.Name .. ACCENT_DOT) or self.Name
	tween(self.NameLabel, 0.2, { TextColor3 = a and theme.Text or theme.Muted })
	if self.NavBtn then tween(self.NavBtn, 0.2, { TextColor3 = a and theme.Text or theme.Muted }) end
end

function Page:_refreshCount()
	local n = self.FixedCount or self.Count
	self.CountLabel.Text = n > 0 and tostring(n) or ""
end

function Page:AddTab(name)
	local hub = self.Hub
	local theme = hub.Theme
	local tab = setmetatable({ Hub = hub, Page = self, Name = name, Order = 0 }, Tab)
	tab.Scroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = theme.Stroke,
		AutomaticCanvasSize = Y, CanvasSize = UDim2.new(), Visible = false, Parent = hub.UI.Body,
	}, { list(VERT, 0), pad(0, 0, 4, 16) })
	tab.Button = new("TextButton", {
		LayoutOrder = #self.Tabs + 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = X, Text = name, TextSize = 13,
		TextColor3 = theme.Muted, Parent = self.TabStrip,
	})
	tab.Underline = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = theme.Accent, BackgroundTransparency = 1, Parent = tab.Button,
	})
	tab.Button.MouseButton1Click:Connect(function() hub:Select(self, tab) end)
	table.insert(self.Tabs, tab)
	if not self.ActiveTab then self.ActiveTab = tab end
	if hub.CurrentPage == self then
		if #self.Tabs == 1 then hub:Select(self, tab) else self.TabStrip.Visible = true end
	end
	return tab
end

function Tab:_setActive(a)
	local theme = self.Hub.Theme
	tween(self.Button, 0.2, { TextColor3 = a and theme.Text or theme.Muted })
	tween(self.Underline, 0.2, { BackgroundTransparency = a and 0 or 1 })
end

function Page:_default()
	if not self.Tabs[1] then self:AddTab("Main") end
	return self.Tabs[1]
end

for _, n in ipairs({ 
	"AddToggle", "AddSlider", "AddSegmented", "AddDropdown", "AddKeybind", 
	"AddAction", "AddButton", "AddSection", "AddLabel", "AddEmpty",
	"AddParagraph", "AddColorpicker", "AddCode", "AddDivider", "AddSpace", 
	"AddImage", "AddHStack", "AddVStack", "AddProgressBar", "AddInput" 
}) do
	Page[n] = function(self, ...)
		local t = self:_default()
		return t[n](t, ...)
	end
end

function Library:Select(page, tab)
	if not page then return end
	local ui = self.UI
	tab = tab or page.ActiveTab or page.Tabs[1]
	if self.CurrentTab and self.CurrentTab ~= tab then self.CurrentTab.Scroll.Visible = false end
	for _, p in ipairs(self.Pages) do
		p.TabStrip.Visible = (p == page) and #p.Tabs > 1
		p:_setActive(p == page)
	end
	self.CurrentPage, self.CurrentTab = page, tab
	page.ActiveTab = tab
	for _, t in ipairs(page.Tabs) do t:_setActive(t == tab) end
	ui.Title.Text = page.Name:upper() .. ACCENT_DOT
	if tab then
		tab.Scroll.Visible = true
		tab.Scroll.CanvasPosition = Vector2.zero
	end
	self:_updateOn()
	self:_closeOverlays()
	ui.Body.GroupTransparency = 1
	ui.Body.Position = UDim2.fromOffset(0, 62)
	tween(ui.Body, 0.35, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 52) })
end

function Library:_updateOn()
	local p = self.CurrentPage
	if not p then return end
	local on = 0
	for _, t in ipairs(p.Toggles) do if t.Value then on += 1 end end
	self.UI.OnLabel.Text = string.format("%d OF %d ON", on, #p.Toggles)
	self.UI.OnWrap.Visible = #p.Toggles > 0
end

----------------------------------------------------------------------
-- Overlays
----------------------------------------------------------------------
function Library:OpenSearch()
	local ui = self.UI
	if self.Mode ~= "Normal" then return end
	self:_closeMenu()
	ui.Palette.Visible = true
	ui.SearchBox.Text = ""
	ui.PaletteBox.Position = UDim2.new(0.5, 0, 0, 66)
	tween(ui.Palette, 0.25, { BackgroundTransparency = 0.45 })
	tween(ui.PaletteBox, 0.35, { Position = UDim2.new(0.5, 0, 0, 80) }, Enum.EasingStyle.Back)
	self:_search("")
	task.defer(function() ui.SearchBox:CaptureFocus() end)
end

function Library:CloseSearch()
	local ui = self.UI
	if not ui.Palette.Visible then return end
	ui.SearchBox:ReleaseFocus()
	tween(ui.Palette, 0.2, { BackgroundTransparency = 1 })
	task.delay(0.2, function()
		if ui.Palette.BackgroundTransparency >= 0.99 then ui.Palette.Visible = false end
	end)
end

function Library:_search(q)
	local ui = self.UI
	local theme = self.Theme
	for _, c in ipairs(ui.SearchResults:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	q = q:lower()
	local n = 0
	for _, e in ipairs(self.Index) do
		if q == "" or e.Name:lower():find(q, 1, true) or e.Desc:lower():find(q, 1, true) then
			n += 1
			if n > 6 then break end
			local b = new("TextButton", { LayoutOrder = n, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = theme.Hover, BackgroundTransparency = 1, ZIndex = 23, Parent = ui.SearchResults }, { corner(8) })
			new("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.55, 0, 1, 0), Text = e.Name, TextSize = 13, TextColor3 = theme.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 24, Parent = b })
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), Font = theme.Mono, TextSize = 10,
				TextColor3 = theme.Dim, TextXAlignment = RIGHT, ZIndex = 24,
				Text = e.Page.Name:upper() .. (#e.Page.Tabs > 1 and (" / " .. e.Tab.Name:upper()) or ""), Parent = b,
			})
			b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0 }) end)
			b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 1 }) end)
			b.MouseButton1Click:Connect(function()
				self:CloseSearch()
				self:Select(e.Page, e.Tab)
			end)
		end
	end
end

function Library:_toggleMenu()
	if self.UI.Menu.Visible then self:_closeMenu() else self:_openMenu() end
end

function Library:_openMenu()
	local ui = self.UI
	local theme = self.Theme
	self:CloseSearch()
	for _, c in ipairs(ui.MenuList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for i, p in ipairs(self.Pages) do
		local active = p == self.CurrentPage
		local b = new("TextButton", {
			LayoutOrder = i, Size = UDim2.fromOffset(0, 46), AutomaticSize = X, Text = p.Name:upper() .. (active and ACCENT_DOT or ""), RichText = true,
			Font = theme.Black, TextSize = 32, TextColor3 = active and theme.Text or theme.Dim, TextXAlignment = LEFT, Parent = ui.MenuList,
		})
		new("TextLabel", {
			Position = UDim2.new(1, 6, 0, 8), Size = UDim2.fromOffset(30, 12), Font = theme.Mono, TextSize = 10, TextXAlignment = LEFT,
			TextColor3 = active and theme.Accent or theme.Dim, Text = tostring(p.FixedCount or p.Count), Parent = b,
		})
		b.MouseEnter:Connect(function() if not active then tween(b, 0.15, { TextColor3 = theme.Muted }) end end)
		b.MouseLeave:Connect(function() if not active then tween(b, 0.15, { TextColor3 = theme.Dim }) end end)
		b.MouseButton1Click:Connect(function() self:Select(p) end)
	end
	ui.Menu.Visible = true
	ui.MenuList.Position = UDim2.fromOffset(0, 12)
	tween(ui.Menu, 0.25, { GroupTransparency = 0 })
	tween(ui.MenuList, 0.35, { Position = UDim2.fromOffset(0, 0) })
end

function Library:_closeMenu()
	local ui = self.UI
	if not ui.Menu.Visible then return end
	tween(ui.Menu, 0.2, { GroupTransparency = 1 })
	task.delay(0.2, function()
		if ui.Menu.GroupTransparency >= 0.99 then ui.Menu.Visible = false end
	end)
end

function Library:_closeOverlays()
	self:CloseSearch()
	self:_closeMenu()
end

----------------------------------------------------------------------
-- Toast pills & notifications
----------------------------------------------------------------------
function Library:_addPill(obj)
	local theme = self.Theme
	local pill = new("TextButton", {
		AutomaticSize = X, Size = UDim2.fromOffset(0, 36), BackgroundColor3 = theme.Panel, BackgroundTransparency = 0, Parent = self.UI.Toast,
	}, { corner(18), stroke(theme.Stroke), pad(5, 0, 6, 0), list(HORIZ, 10, LEFT, VCENTER) })
	local sc = new("UIScale", { Parent = pill })
	local cap = new("TextLabel", {
		LayoutOrder = 1, Size = UDim2.fromOffset(24, 24), AutomaticSize = X, BackgroundTransparency = 0, BackgroundColor3 = theme.Raised,
		Font = theme.Mono, TextSize = 11, TextColor3 = theme.Muted, Parent = pill,
	}, { corner(7), stroke(theme.Stroke), pad(6, 0, 6, 0) })
	new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 16), AutomaticSize = X, Text = obj.Name, TextSize = 13, TextColor3 = theme.Text, Parent = pill })
	local chip = new("Frame", { LayoutOrder = 3, Size = UDim2.fromOffset(40, 22), BackgroundColor3 = theme.Raised, Parent = pill }, { corner(11) })
	local ct = new("TextLabel", { Size = UDim2.fromScale(1, 1), Font = theme.Mono, TextSize = 10, Parent = chip })

	local p = { Frame = pill, Scale = sc }
	function p:Update()
		cap.Visible = obj.Key ~= nil
		cap.Text = keyText(obj.Key)
		ct.Text = obj.Value and "ON" or "OFF"
		tween(chip, 0.2, { BackgroundColor3 = obj.Value and theme.Accent or theme.Raised })
		tween(ct, 0.2, { TextColor3 = obj.Value and Color3.new(1, 1, 1) or theme.Muted })
	end
	pill.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
	obj.Pill = p
	table.insert(self.Features, obj)
	p:Update()
end

function Library:Notify(o)
	o = o or {}
	local theme = self.Theme
	local color = NotifyColors[(o.Type or "info"):lower()] or theme.Blue
	self._notifOrder += 1
	local holder = new("Frame", { LayoutOrder = self._notifOrder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, Parent = self.UI.Notifs })
	local slide = new("Frame", { Position = UDim2.fromOffset(420, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, Parent = holder })

	if self.Avatar then
		new("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(44, 44), Image = self.Avatar, Parent = slide })
	end
	local card = new("Frame", {
		Position = UDim2.fromOffset(self.Avatar and 54 or 0, 0), Size = UDim2.new(1, self.Avatar and -54 or 0, 0, 0), AutomaticSize = Y,
		BackgroundColor3 = theme.Panel, Parent = slide,
	}, { corner(12), stroke(theme.Stroke), pad(14, 11, 14, 13), list(VERT, 6) })
	local head = new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = card })
	new("Frame", { Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = color, Parent = head }, { corner(3) })
	new("TextLabel", { Position = UDim2.fromOffset(13, 0), Size = UDim2.new(0.7, 0, 1, 0), Text = (o.Title or "NOTICE"):upper(), Font = theme.Mono, TextSize = 11, TextColor3 = color, TextXAlignment = LEFT, Parent = head })
	new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.25, 0, 1, 0), Text = "NOW", Font = theme.Mono, TextSize = 10, TextColor3 = theme.Dim, TextXAlignment = RIGHT, Parent = head })
	new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Text = o.Text or "", TextSize = 14, TextWrapped = true,
		TextColor3 = theme.Text, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Parent = card,
	})

	tween(slide, 0.5, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	task.delay(o.Duration or 4, function()
		if not holder.Parent then return end
		local t = tween(slide, 0.35, { Position = UDim2.fromOffset(420, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Wait()
		holder:Destroy()
	end)
end

----------------------------------------------------------------------
-- Controls & Requested Elements
----------------------------------------------------------------------
function Tab:_row(o, h, noLine)
	h = h or 56
	local theme = self.Hub.Theme
	self.Order += 1
	local row = new("Frame", { LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Scroll })
	if not noLine then
		new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Line, Parent = row })
	end
	if o.Name then
		local tr = new("Frame", {
			Position = UDim2.fromOffset(2, o.Desc and 11 or (h == 56 and 20 or 11)), Size = UDim2.new(1, -150, 0, 16), BackgroundTransparency = 1, Parent = row,
		}, { list(HORIZ, 8, LEFT, VCENTER) })
		new("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(0, 16), AutomaticSize = X, Text = o.Name, TextSize = 14, TextColor3 = theme.Text, Parent = tr })
		if o.Premium then
			local b = new("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 18), AutomaticSize = X, BackgroundColor3 = theme.AccentDark, Parent = tr }, { corner(9), pad(7, 0, 8, 0), list(HORIZ, 5, LEFT, VCENTER) })
			new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(5, 5), BackgroundColor3 = theme.Accent, Parent = b }, { corner(3) })
			new("TextLabel", { LayoutOrder = 2, Size = UDim2.fromOffset(0, 12), AutomaticSize = X, Text = "Premium", TextSize = 10, TextColor3 = theme.Accent, Parent = b })
		end
	end
	if o.Desc then
		new("TextLabel", {
			Position = UDim2.fromOffset(2, 31), Size = UDim2.new(1, -150, 0, 14), Text = o.Desc, TextSize = 12, TextColor3 = theme.Muted,
			TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
	end
	return row
end

function Tab:_reg(o, obj, row)
	local hub, page = self.Hub, self.Page
	local flag = o.Flag or o.Name
	obj.Flag = flag
	if flag then hub.Objects[flag] = obj end
	page.Count += 1
	page:_refreshCount()
	table.insert(hub.Index, { Name = o.Name or "", Desc = o.Desc or "", Page = page, Tab = self })
	obj.Row = row
	return obj
end

function Tab:_premiumLocked(o)
	if o.Premium and not self.Hub.IsPremium then
		self.Hub:Notify({ Type = "warning", Title = "Premium", Text = (o.Name or "This feature") .. " needs a premium key." })
		return true
	end
	return false
end

function Tab:AddSection(o)
	if type(o) == "string" then o = { Name = o } end
	local theme = self.Hub.Theme
	self.Order += 1
	local f = new("Frame", { LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = self.Scroll })
	new("TextLabel", { Size = UDim2.fromScale(0.6, 1), Text = (o.Name or ""):upper(), Font = theme.Mono, TextSize = 10, TextColor3 = theme.Dim, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Bottom, Parent = f }, { pad(2, 0, 0, 8) })
	if o.Right then
		new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0.4, 1), Text = o.Right, Font = theme.Mono, TextSize = 10, TextColor3 = theme.Dim, TextXAlignment = RIGHT, TextYAlignment = Enum.TextYAlignment.Bottom, Parent = f }, { pad(0, 0, 2, 8) })
	end
	return f
end

function Tab:AddLabel(text)
	local theme = self.Hub.Theme
	self.Order += 1
	return new("TextLabel", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Text = text, TextSize = 12, TextColor3 = theme.Muted,
		TextWrapped = true, TextXAlignment = LEFT, Parent = self.Scroll,
	}, { pad(2, 10, 2, 10) })
end

function Tab:AddParagraph(o)
	o = o or {}
	local theme = self.Hub.Theme
	self.Order += 1
	local f = new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y,
		BackgroundColor3 = theme.Panel, Parent = self.Scroll,
	}, { corner(8), stroke(theme.Stroke), pad(12, 10, 12, 10), list(VERT, 4) })
	if o.Title then
		new("TextLabel", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), Text = o.Title, Font = theme.Bold, TextSize = 13, TextColor3 = theme.Text, Parent = f })
	end
	new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, Text = o.Content or "", TextSize = 12, TextColor3 = theme.Muted,
		TextWrapped = true, TextXAlignment = LEFT, Parent = f,
	})
	return f
end

function Tab:AddToggle(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local locked = o.Premium and not hub.IsPremium
	local flag = o.Flag or o.Name
	local obj = { Value = false, Key = o.Key, Name = o.Name, Type = "Toggle" }

	local track = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = theme.Track,
		BackgroundTransparency = locked and 0.4 or 0, Parent = row,
	}, { corner(11) })
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromHex("#CFCFCF"), Parent = track }, { corner(8) })

	function obj:Set(v, silent)
		v = v and true or false
		if locked and v then return end
		obj.Value = v
		tween(track, 0.2, { BackgroundColor3 = v and theme.Accent or theme.Track })
		tween(knob, 0.25, { Position = v and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = v and Color3.new(1, 1, 1) or Color3.fromHex("#CFCFCF") }, Enum.EasingStyle.Back)
		if flag then hub.Flags[flag] = v end
		if obj.Pill then obj.Pill:Update() end
		hub:_updateOn()
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end

	track.MouseButton1Click:Connect(function()
		if self:_premiumLocked(o) then return end
		obj:Set(not obj.Value)
	end)
	table.insert(self.Page.Toggles, obj)
	table.insert(hub.Binds, { get = function() return obj.Key end, fire = function() obj:Set(not obj.Value) end })
	self:_reg(o, obj, row)
	if o.Toast ~= false then hub:_addPill(obj) end
	obj:Set(o.Default or false, not o.Default)
	return obj
end

function Tab:AddSlider(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 80)
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local suffix = (o.Suffix or ""):upper()
	local obj = { Value = o.Default or min, Type = "Slider" }
	local flag = o.Flag or o.Name

	local chip = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 9), Size = UDim2.fromOffset(0, 24), AutomaticSize = X,
		BackgroundTransparency = 0, BackgroundColor3 = theme.Raised, Font = theme.Mono, TextSize = 12, RichText = true, TextColor3 = theme.Text, Parent = row,
	}, { corner(6), stroke(theme.Stroke), pad(9, 0, 9, 0) })
	local track = new("Frame", { Position = UDim2.new(0, 2, 0, 60), Size = UDim2.new(1, -4, 0, 4), BackgroundColor3 = theme.Track, Parent = row }, { corner(2) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Accent, Parent = track }, { corner(2) })
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track }, { corner(7) })
	local hit = new("TextButton", { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 28), Parent = row })

	function obj:Set(v, silent)
		v = math.clamp(math.round((v - min) / inc) * inc + min, min, max)
		v = tonumber(string.format("%.4f", v))
		obj.Value = v
		local a = (max == min) and 0 or (v - min) / (max - min)
		tween(fill, 0.08, { Size = UDim2.fromScale(a, 1) })
		tween(knob, 0.08, { Position = UDim2.fromScale(a, 0.5) })
		chip.Text = string.format('%s <font color="#5A5A5A" size="9">%s</font>', tostring(v), suffix)
		if flag then hub.Flags[flag] = v end
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end

	local dragging = false
	local function fromInput(i)
		local a = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		obj:Set(min + (max - min) * a)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			self.Scroll.ScrollingEnabled = false
			tween(knob, 0.12, { Size = UDim2.fromOffset(18, 18) })
			fromInput(i)
		end
	end)
	table.insert(hub._conns, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromInput(i) end
	end))
	table.insert(hub._conns, UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			self.Scroll.ScrollingEnabled = true
			tween(knob, 0.12, { Size = UDim2.fromOffset(14, 14) })
		end
	end))

	self:_reg(o, obj, row)
	obj:Set(obj.Value, true)
	return obj
end

function Tab:AddSegmented(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local obj = { Value = o.Default or o.Options[1], Type = "Segmented" }
	local flag = o.Flag or o.Name
	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(0, 32), AutomaticSize = X,
		BackgroundColor3 = theme.Panel, Parent = row,
	}, { corner(8), stroke(theme.Stroke), pad(3), list(HORIZ, 0, LEFT, VCENTER) })
	local btns = {}
	local function render(animate)
		for name, b in pairs(btns) do
			local sel = name == obj.Value
			local t = animate and 0.2 or 0
			tween(b, t, { BackgroundTransparency = sel and 0 or 1, TextColor3 = sel and Color3.fromHex("#0B0B0B") or theme.Muted })
		end
	end
	for i, name in ipairs(o.Options) do
		local b = new("TextButton", {
			LayoutOrder = i, Size = UDim2.fromOffset(0, 26), AutomaticSize = X, BackgroundColor3 = Color3.fromHex("#F2F2F2"), Text = name,
			TextSize = 12, Parent = box,
		}, { corner(6), pad(12, 0, 12, 0) })
		btns[name] = b
		b.MouseButton1Click:Connect(function() obj:Set(name) end)
	end
	function obj:Set(v, silent)
		if not btns[v] then return end
		obj.Value = v
		render(true)
		if flag then hub.Flags[flag] = v end
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end
	self:_reg(o, obj, row)
	render(false)
	if flag then hub.Flags[flag] = obj.Value end
	return obj
end

function Tab:AddDropdown(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local obj = { Value = o.Default, Options = o.Options or {}, Type = "Dropdown" }
	local flag = o.Flag or o.Name
	local open = false

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 12), Size = UDim2.fromOffset(160, 32),
		BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Parent = row,
	}, { corner(8), stroke(theme.Stroke) })
	local txt = new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -34, 1, 0), TextSize = 13, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn })
	local arrow = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(14, 14), Text = "▾", TextSize = 13, TextColor3 = theme.Muted, Parent = btn })
	local listF = new("ScrollingFrame", {
		Position = UDim2.fromOffset(2, 58), Size = UDim2.new(1, -4, 0, 0), BackgroundColor3 = theme.Panel, ScrollBarThickness = 2,
		AutomaticCanvasSize = Y, CanvasSize = UDim2.new(), Visible = false, Parent = row,
	}, { corner(10), stroke(theme.Stroke), list(VERT, 0), pad(4) })
	hover(btn, btn, theme.Raised, theme.Hover)

	local function renderText()
		txt.Text = obj.Value ~= nil and tostring(obj.Value) or (o.Placeholder or "Select")
		txt.TextColor3 = obj.Value ~= nil and theme.Text or theme.Muted
	end
	local function height() return math.min(#obj.Options, 5) * 30 + 8 end
	local function setOpen(v)
		open = v
		tween(arrow, 0.25, { Rotation = v and 180 or 0 })
		if v then
			listF.Visible = true
			tween(row, 0.3, { Size = UDim2.new(1, 0, 0, 56 + height() + 10) })
			tween(listF, 0.3, { Size = UDim2.new(1, -4, 0, height()) })
		else
			tween(row, 0.25, { Size = UDim2.new(1, 0, 0, 56) })
			tween(listF, 0.25, { Size = UDim2.new(1, -4, 0, 0) })
			task.delay(0.25, function() if not open then listF.Visible = false end end)
		end
	end
	local function build()
		for _, c in ipairs(listF:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, name in ipairs(obj.Options) do
			local b = new("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = theme.Hover, Text = tostring(name), TextSize = 13,
				TextColor3 = name == obj.Value and theme.Text or theme.Muted, TextXAlignment = LEFT, Parent = listF,
			}, { corner(6), pad(10, 0, 10, 0) })
			b.BackgroundTransparency = 1
			b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundTransparency = 0 }) end)
			b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundTransparency = 1 }) end)
			b.MouseButton1Click:Connect(function()
				obj:Set(name)
				setOpen(false)
			end)
		end
	end
	function obj:Set(v, silent)
		obj.Value = v
		renderText()
		build()
		if flag then hub.Flags[flag] = v end
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end
	function obj:SetOptions(list2)
		obj.Options = list2
		if not table.find(list2, obj.Value) then obj.Value = nil end
		renderText()
		build()
		if open then setOpen(true) end
	end
	btn.MouseButton1Click:Connect(function() setOpen(not open) end)
	self:_reg(o, obj, row)
	renderText()
	build()
	return obj
end

function Tab:AddKeybind(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local target = o.Toggle
	local obj = { Key = o.Default or (target and target.Key), Type = "Keybind" }
	local flag = o.Flag or o.Name
	local cap = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(28, 28), AutomaticSize = X,
		BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Font = theme.Mono, TextSize = 12, TextColor3 = theme.Muted, Parent = row,
	}, { corner(7), stroke(theme.Stroke), pad(8, 0, 8, 0) })

	function obj:Set(k, silent)
		if type(k) == "string" then k = Enum.KeyCode[k] end
		obj.Key = k
		cap.Text = keyText(k)
		if flag then hub.Flags[flag] = k and k.Name or "" end
		if target then
			target.Key = k
			if target.Pill then target.Pill:Update() end
		end
		if not silent and o.Changed then task.spawn(o.Changed, k) end
	end
	if not target then
		table.insert(hub.Binds, {
			get = function() return obj.Key end,
			fire = function() if o.Callback then task.spawn(o.Callback) end end,
		})
	end
	cap.MouseButton1Click:Connect(function()
		if hub._listening then return end
		hub._listening = true
		cap.Text = "…"
		tween(cap, 0.15, { TextColor3 = theme.Accent })
		local conn
		conn = UIS.InputBegan:Connect(function(i)
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			tween(cap, 0.15, { TextColor3 = theme.Muted })
			obj:Set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode or nil)
			task.defer(function() hub._listening = false end)
		end)
	end)
	self:_reg(o, obj, row)
	obj:Set(obj.Key, true)
	return obj
end

function Tab:AddColorpicker(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local obj = { Value = o.Default or Color3.new(1, 1, 1), Type = "Colorpicker" }
	local flag = o.Flag or o.Name

	local preview = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(36, 24),
		BackgroundColor3 = obj.Value, Parent = row,
	}, { corner(6), stroke(theme.Stroke) })

	function obj:Set(v, silent)
		obj.Value = v
		preview.BackgroundColor3 = v
		if flag then hub.Flags[flag] = v end
		if not silent and o.Callback then task.spawn(o.Callback, v) end
	end

	preview.MouseButton1Click:Connect(function()
		-- Simple cycling fallback or trigger callback if color picker menu isn't explicitly expanded
		local colors = { Color3.new(1, 1, 1), Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1) }
		local currentIndex = 1
		for i, c in ipairs(colors) do
			if c == obj.Value then currentIndex = i break end
		end
		obj:Set(colors[(currentIndex % #colors) + 1])
	end)

	self:_reg(o, obj, row)
	return obj
end

function Tab:AddCode(o)
	o = o or {}
	local theme = self.Hub.Theme
	self.Order += 1
	local f = new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 100), BackgroundColor3 = theme.Panel, Parent = self.Scroll,
	}, { corner(8), stroke(theme.Stroke), pad(10) })
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), Text = o.Content or "", Font = theme.Mono, TextSize = 11, TextColor3 = theme.Text,
		TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = f,
	})
	return f
end

function Tab:AddDivider()
	local theme = self.Hub.Theme
	self.Order += 1
	return new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Parent = self.Scroll,
	}, { new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = theme.Line }) })
end

function Tab:AddSpace(h)
	self.Order += 1
	return new("Frame", { LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h or 10), BackgroundTransparency = 1, Parent = self.Scroll })
end

function Tab:AddImage(o)
	o = o or {}
	local theme = self.Hub.Theme
	self.Order += 1
	local f = new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, o.Height or 150), BackgroundColor3 = theme.Panel, Parent = self.Scroll,
	}, { corner(8), stroke(theme.Stroke) })
	new("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0), Image = o.Image or "", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Parent = f,
	}, { corner(8) })
	return f
end

function Tab:AddHStack()
	self.Order += 1
	return new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = self.Scroll,
	}, { list(HORIZ, 8, LEFT, VCENTER) })
end

function Tab:AddVStack()
	self.Order += 1
	return new("Frame", {
		LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Y, BackgroundTransparency = 1, Parent = self.Scroll,
	}, { list(VERT, 6) })
end

function Tab:AddProgressBar(o)
	o = o or {}
	local theme = self.Hub.Theme
	local row = self:_row(o, 40)
	local obj = { Value = o.Default or 0, Type = "ProgressBar" }
	local track = new("Frame", { Position = UDim2.new(0, 2, 0, 20), Size = UDim2.new(1, -4, 0, 6), BackgroundColor3 = theme.Track, Parent = row }, { corner(3) })
	local fill = new("Frame", { Size = UDim2.fromScale(math.clamp(obj.Value, 0, 1), 1), BackgroundColor3 = theme.Accent, Parent = track }, { corner(3) })

	function obj:Set(v)
		obj.Value = math.clamp(v, 0, 1)
		tween(fill, 0.15, { Size = UDim2.fromScale(obj.Value, 1) })
	end

	self:_reg(o, obj, row)
	return obj
end

function Tab:AddInput(o)
	local hub = self.Hub
	local theme = hub.Theme
	local row = self:_row(o, 56)
	local obj = { Value = o.Default or "", Type = "Input" }
	local flag = o.Flag or o.Name

	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(160, 32),
		BackgroundColor3 = theme.Raised, Text = obj.Value, PlaceholderText = o.Placeholder or "Enter text...",
		PlaceholderColor3 = theme.Dim, TextSize = 13, TextColor3 = theme.Text, ClearTextOnFocus = false, Parent = row,
	}, { corner(8), stroke(theme.Stroke), pad(10, 0, 10, 0) })

	box.FocusLost:Connect(function(enter)
		obj.Value = box.Text
		if flag then hub.Flags[flag] = box.Text end
		if o.Callback then task.spawn(o.Callback, box.Text) end
	end)

	function obj:Set(v)
		obj.Value = v
		box.Text = v
		if flag then hub.Flags[flag] = v end
	end

	self:_reg(o, obj, row)
	return obj
end

function Tab:AddAction(o)
	local theme = self.Hub.Theme
	local row = self:_row(o, 56)
	local obj = { Type = "Action" }
	local btn
	if o.ButtonText then
		btn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(0, 32), AutomaticSize = X,
			BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Text = o.ButtonText, TextSize = 13, TextColor3 = theme.Text, Parent = row,
		}, { corner(8), stroke(theme.Stroke), pad(14, 0, 14, 0) })
	else
		btn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = theme.Raised, BackgroundTransparency = 0, Parent = row,
		}, { corner(8) })
		if o.Icon then
			new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Image = o.Icon, ImageColor3 = theme.Muted, Parent = btn })
		else
			local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(13, 13), BackgroundTransparency = 1, Parent = btn }, { corner(7), stroke(theme.Muted, 2) })
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(3, 3), BackgroundColor3 = theme.Muted, Parent = ring }, { corner(2) })
		end
	end
	hover(btn, btn, theme.Raised, theme.Hover)
	btn.MouseButton1Click:Connect(function()
		if self:_premiumLocked(o) then return end
		tween(btn, 0.08, { BackgroundColor3 = theme.Accent })
		task.delay(0.12, function() tween(btn, 0.25, { BackgroundColor3 = theme.Raised }) end)
		if o.Callback then task.spawn(o.Callback) end
	end)
	return self:_reg(o, obj, row)
end
Tab.AddButton = Tab.AddAction

function Tab:AddEmpty(o)
	local theme = self.Hub.Theme
	self.Order += 1
	local f = new("Frame", { LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 260), BackgroundTransparency = 1, Parent = self.Scroll }, { list(VERT, 8, CENTER, VCENTER) })
	local icon = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(36, 36), BackgroundColor3 = theme.Raised, Parent = f }, { corner(10), stroke(theme.Stroke) })
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 11), BackgroundTransparency = 1, Parent = icon }, { corner(3), stroke(theme.Muted, 1.5) })
	new("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 22), Text = o.Title or "Nothing here yet", TextSize = 14, TextColor3 = theme.Text, Parent = f })
	new("TextLabel", { LayoutOrder = 3, Size = UDim2.fromOffset(300, 34), Text = o.Text or "", TextSize = 12, TextColor3 = theme.Muted, TextWrapped = true, Parent = f })
	if o.Button then
		local b = new("TextButton", {
			LayoutOrder = 4, Size = UDim2.fromOffset(0, 36), AutomaticSize = X, BackgroundColor3 = theme.Raised, BackgroundTransparency = 0,
			Text = o.Button, TextSize = 13, TextColor3 = theme.Text, Parent = f,
		}, { corner(10), stroke(theme.Stroke), pad(18, 0, 18, 0) })
		hover(b, b, theme.Raised, theme.Hover)
		b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
	end
	return f
end

----------------------------------------------------------------------
-- Configs & cleanup
----------------------------------------------------------------------
function Library:GetConfig()
	local t = {}
	for k, v in pairs(self.Flags) do t[k] = v end
	return t
end

function Library:LoadConfig(t)
	for flag, v in pairs(t) do
		local o = self.Objects[flag]
		if o and o.Set then o:Set(v) end
	end
end

function Library:SaveConfig(name)
	if not writefile then return false end
	if isfolder and makefolder and not isfolder(self.Name) then makefolder(self.Name) end
	writefile(string.format("%s/%s.json", self.Name, name), HttpService:JSONEncode(self:GetConfig()))
	return true
end

function Library:LoadConfigFile(name)
	if not (readfile and isfile) then return false end
	local path = string.format("%s/%s.json", self.Name, name)
	if not isfile(path) then return false end
	self:LoadConfig(HttpService:JSONDecode(readfile(path)))
	return true
end

function Library:Destroy()
	for _, c in ipairs(self._conns) do c:Disconnect() end
	self.UI.Gui:Destroy()
end

return Library
