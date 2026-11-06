local Library = loadstring(readfile("TzarUI.lua"))()

local Window = Library.new({
	Name = "Nexus Hub",
	Version = "2.5",
	Badge = "PRO",
	Status = "SAFE",
	StatusPosition = "BottomLeft",
	ToggleKey = Enum.KeyCode.RightShift,
	IsPremium = true,
})

local CombatPage = Window:AddPage({ Name = "Combat", Group = "Main" })
local AimbotTab = CombatPage:AddTab("Aimbot")

AimbotTab:AddSection("Aimbot Settings")

AimbotTab:AddToggle({
	Name = "Enable Aimbot",
	Desc = "Automatically lock onto targets.",
	Default = false,
	Key = Enum.KeyCode.Q,
	Callback = function(state)
		print("Aimbot state:", state)
	end,
})

AimbotTab:AddSlider({
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

AimbotTab:AddSegmented({
	Name = "Target Hitbox",
	Desc = "Select body part to lock onto.",
	Options = { "Head", "Torso" },
	Default = "Head",
	Callback = function(selected)
		print("Targeting:", selected)
	end,
})

AimbotTab:AddDropdown({
	Name = "Target Priority",
	Desc = "Method for selecting targets.",
	Options = { "Closest Distance", "Lowest Health", "FOV Center" },
	Default = "Closest Distance",
	Callback = function(selected)
		print("Priority:", selected)
	end,
})

AimbotTab:AddKeybind({
	Name = "Lock Keybind",
	Desc = "Key to activate targeted lock.",
	Default = Enum.KeyCode.F,
	Changed = function(newKey)
		print("Keybind set to:", newKey)
	end,
})

AimbotTab:AddAction({
	Name = "Reset Settings",
	Desc = "Restore aimbot configurations.",
	ButtonText = "Reset",
	Callback = function()
		Window:Notify({
			Type = "info",
			Title = "Reset",
			Text = "Aimbot settings restored.",
			Duration = 3,
		})
	end,
})

Window:Notify({
	Type = "success",
	Title = "Loaded",
	Text = "Nexus Hub initialized successfully!",
	Duration = 4,
})
