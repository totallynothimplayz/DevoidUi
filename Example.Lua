local Library = loadstring(readfile("DevoidUi.lua"))()

local Window = Library.new({
	Name = "Nexus Hub",
	Version = "3.0",
	Badge = "PRO",
	Status = "SAFE",
	StatusPosition = "BottomLeft",
	ToggleKey = Enum.KeyCode.RightShift,
	IsPremium = true,
	ToggleIcon = "rbxassetid://6031068421", -- Custom image or text for mobile float toggle
	Theme = {
		Bg = Color3.fromHex("#0B0B10"),
		Panel = Color3.fromHex("#12121A"),
		Accent = Color3.fromHex("#7AA2F7"), -- Custom accent color override
		Text = Color3.fromHex("#C0CAF5"),
	},
})

local CombatPage = Window:AddPage({ Name = "Combat", Group = "Main" })
local MainTab = CombatPage:AddTab("Main")
local VisualsTab = CombatPage:AddTab("Visuals")

-- Sections & Labels
MainTab:AddSection("Aimbot Settings")

MainTab:AddParagraph({
	Title = "System Notice",
	Content = "Adjust your combat configurations below. All settings auto-save to JSON.",
})

-- Toggles & Sliders
MainTab:AddToggle({
	Name = "Enable Aimbot",
	Desc = "Automatically lock onto targets.",
	Default = false,
	Key = Enum.KeyCode.Q,
	Callback = function(state)
		print("Aimbot state:", state)
	end,
})

MainTab:AddSlider({
	Name = "Field of View",
	Desc = "Targeting area radius.",
	Min = 30,
	Max = 300,
	Increment = 5,
	Default = 90,
	Suffix = "px",
	Callback = function(value)
		print("FOV:", value)
	end,
})

-- Inputs, Dropdowns & Keybinds
MainTab:AddInput({
	Name = "Target User",
	Desc = "Filter targeted player by username.",
	Placeholder = "Username...",
	Callback = function(text)
		print("Targeting username:", text)
	end,
})

MainTab:AddSegmented({
	Name = "Target Hitbox",
	Desc = "Select body part to lock onto.",
	Options = { "Head", "Torso" },
	Default = "Head",
	Callback = function(selected)
		print("Targeting hitbox:", selected)
	end,
})

MainTab:AddDropdown({
	Name = "Target Priority",
	Desc = "Method for selecting targets.",
	Options = { "Closest Distance", "Lowest Health", "FOV Center" },
	Default = "Closest Distance",
	Callback = function(selected)
		print("Priority:", selected)
	end,
})

MainTab:AddKeybind({
	Name = "Lock Keybind",
	Desc = "Key to activate targeted lock.",
	Default = Enum.KeyCode.F,
	Changed = function(newKey)
		print("Keybind set to:", newKey)
	end,
})

MainTab:AddDivider()
MainTab:AddSpace(5)

-- Colorpicker, Progress Bar & Actions
VisualsTab:AddSection("Visual Customization")

VisualsTab:AddColorpicker({
	Name = "ESP Accent Color",
	Desc = "Customize box and line highlighting.",
	Default = Color3.fromHex("#7AA2F7"),
	Callback = function(color)
		print("Color updated:", color)
	end,
})

local Progress = VisualsTab:AddProgressBar({
	Name = "Resource Loader",
	Default = 0.45,
})

VisualsTab:AddCode({
	Content = "-- Example custom callback snippet\nprint('DevoidUi system loaded successfully!')",
})

VisualsTab:AddAction({
	Name = "Reset All Settings",
	Desc = "Restore default configurations.",
	ButtonText = "Reset",
	Callback = function()
		Progress:Set(1)
		Window:Notify({
			Type = "info",
			Title = "Reset",
			Text = "Configurations reset successfully.",
			Duration = 3,
		})
	end,
})

Window:Notify({
	Type = "success",
	Title = "Initialized",
	Text = "DevoidUi running with custom theme and features!",
	Duration = 4,
})
