local wezterm = require("wezterm")

wezterm.on("gui-startup", function(cmd)
	local _, main_pane, main_window = wezterm.mux.spawn_window(cmd or {})
	main_window:gui_window():maximize()
end)

wezterm.on("gui-attached", function(_)
	-- maximize all displayed windows on startup
	local workspace = wezterm.mux.get_active_workspace()
	for _, window in ipairs(wezterm.mux.all_windows()) do
		if window:get_workspace() == workspace then
			window:gui_window():maximize()
		end
	end
end)

local function spawn_lima_tab_with_cwd(window, pane)
	local cwd_uri = pane:get_current_working_dir()
	local args = { "/opt/homebrew/bin/limactl", "shell", "--shell", "zsh" }

	if cwd_uri then
		local path = cwd_uri.file_path
		table.insert(args, "--workdir")
		table.insert(args, path)
	end

	table.insert(args, "default")

	window:perform_action(
		wezterm.action.SpawnCommandInNewTab({
			args = args,
		}),
		pane
	)
end

return {
	send_composed_key_when_left_alt_is_pressed = false,
	send_composed_key_when_right_alt_is_pressed = false,
	-- font = wezterm.font("GoMono Nerd Font"),
	use_ime = true,
	font_size = 16.0,
	color_scheme = "Solarized (dark) (terminal.sexy)",
	-- color_scheme = "Solarized (light) (terminal.sexy)",
	-- color_scheme = "Catppuccin Latte",
	-- color_scheme = "Gruvbox Light",
	-- color_scheme = "Tokyo Night Light (Gogh)",
	-- color_scheme = "Tokyo Night Moon",
	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
	window_background_opacity = 1.0,
	scrollback_lines = 10000,
	enable_scroll_bar = true,
	mouse_bindings = {
		-- {
		--   event = { Up = { streak = 2, button = 'Left' } },
		--   mods = 'NONE',
		--   action = wezterm.action.EmitEvent 'double-click',
		-- },
	},

	keys = {
		{
			key = "t",
			mods = "CMD",
			action = wezterm.action_callback(spawn_lima_tab_with_cwd),
		},
		{
			key = "LeftArrow",
			mods = "SUPER",
			action = wezterm.action.ActivateTabRelative(-1),
		},
		{
			key = "RightArrow",
			mods = "SUPER",
			action = wezterm.action.ActivateTabRelative(1),
		},
		{
			key = "LeftArrow",
			mods = "SUPER|SHIFT",
			action = wezterm.action.MoveTabRelative(-1),
		},
		{
			key = "RightArrow",
			mods = "SUPER|SHIFT",
			action = wezterm.action.MoveTabRelative(1),
		},
	},
	default_prog = { "/opt/homebrew/bin/limactl", "shell", "--shell", "zsh", "default" },
}
