# DevoidUi
A Customizable UI To Your Desires.
A sleek, modern, and lightweight Roblox Luau UI library featuring smooth animations, multiple layout modes, built-in search, and cross-platform support (Desktop & Mobile).
Features
 * Multiple Layout Modes: Switch between Wide (Desktop sidebar layout) and Compact (Mobile/Navbar layout).
 * Display Modes: Supports Normal (full window), Toast (feature pills), and Hidden.
 * Built-in Search Palette: Quickly find features using the search bar or Ctrl + K.
 * Customizable Status & Indicators: Configure custom status labels and alignment positions.
 * Config Management: Easily save and load user configurations to/from .json files.
 * Cross-Platform Accessibility: Fully responsive with touch support and a floating accessibility toggle button.
Installation
Via loadstring (Exploit Environments)
local Library = loadstring(readfile("TzarUI.lua"))()

Via ModuleScript
Place TzarUI inside a ModuleScript in your project and require it:
local Library = require(script.TzarUI)

Quick Start Guide
local Library = loadstring(readfile("TzarUI.lua"))()

-- Initialize the Window
local Window = Library.new({
    Name = "Nexus Hub",
    Version = "2.5",
    Badge = "PRO",
    Status = "SAFE",
    StatusPosition = "BottomLeft", -- Options: "BottomLeft", "BottomRight", "TopLeft", "TopRight"
    ToggleKey = Enum.KeyCode.RightShift,
    IsPremium = true,
})

-- Create a Page and Tab
local CombatPage = Window:AddPage({ Name = "Combat", Group = "Main" })
local AimbotTab = CombatPage:AddTab("Aimbot")

-- Add a Toggle
AimbotTab:AddToggle({
    Name = "Enable Aimbot",
    Desc = "Automatically lock onto targets.",
    Default = false,
    Key = Enum.KeyCode.Q,
    Callback = function(state)
        print("Aimbot state:", state)
    end,
})

-- Add a Slider
AimbotTab:AddSlider({
    Name = "Field of View",
    Min = 30,
    Max = 300,
    Increment = 5,
    Default = 90,
    Suffix = "px",
    Callback = function(value)
        print("FOV:", value)
    end,
})

API Reference
Library.new(opts)
Initializes the main window.
| Option | Type | Default | Description |
|---|---|---|---|
| Name | string | "HUB" | Title of your hub. |
| Version | string | "V1.0" | Version subtitle. |
| Badge | string | nil | Optional badge tag on the header. |
| Status | string | "SAFE" | Status text indicator. |
| StatusPosition | string | "BottomLeft" | Position of status (BottomLeft, BottomRight, TopLeft, TopRight). |
| ToggleKey | Enum.KeyCode | RightShift | Keyboard key to show/hide the UI. |
| IsPremium | boolean | false | Unlocks premium-restricted controls. |
Page & Tab Methods
Window:AddPage(opts)
Creates a new page in the sidebar or menu list.
 * opts.Name: String name of the page.
 * opts.Group: Category group header (default: "GAME").
Page:AddTab(name)
Creates a sub-tab strip at the top of the content area.
Control Elements
1. Toggle
Tab:AddToggle({
    Name = "Feature Name",
    Desc = "Description text",
    Default = false,
    Key = Enum.KeyCode.E, -- Optional shortcut
    Premium = false,      -- Locks if IsPremium is false
    Callback = function(state) end,
})

2. Slider
Tab:AddSlider({
    Name = "Slider Name",
    Desc = "Description text",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 50,
    Suffix = "studs",
    Callback = function(value) end,
})

3. Dropdown
Tab:AddDropdown({
    Name = "Dropdown Name",
    Options = {"Option 1", "Option 2"},
    Default = "Option 1",
    Callback = function(selected) end,
})

4. Segmented Selector
Tab:AddSegmented({
    Name = "Mode Selector",
    Options = {"Auto", "Manual"},
    Default = "Auto",
    Callback = function(selected) end,
})

5. Keybind
Tab:AddKeybind({
    Name = "Bind Name",
    Default = Enum.KeyCode.F,
    Changed = function(newKey) end,
})

6. Action / Button
Tab:AddAction({
    Name = "Action Name",
    ButtonText = "Execute",
    Callback = function() end,
})

Notifications
Send slide-in status notifications from anywhere:
Window:Notify({
    Type = "success", -- Options: "info", "success", "warning", "error"
    Title = "Success",
    Text = "Action performed successfully!",
    Duration = 4,     -- Time in seconds before closing
})

Configuration Management
-- Save settings to file
Window:SaveConfig("config_name")

-- Load settings from file
Window:LoadConfigFile("config_name")

