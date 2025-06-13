local wezterm = require 'wezterm';

-- local function split_pane(main_pane)
--   local cwd_pane
--
--   local mode = ""
--   local cwd = ""
--
--   wezterm.on('user-var-changed', function(_, pane, name, value)
--     if pane:pane_id() == main_pane:pane_id() then
--       if name == 'mode' then
--         if value ~= mode then
--           mode = value
--
--           if mode == "split" then
--             cwd_pane = main_pane:split {
--               direction = 'Top',
--               -- direction = 'Right',
--             }
--
--             cwd_pane:send_text ' PROMPT=""\n'
--             cwd_pane:send_text ' clear && ls -l\n'
--
--             local url = cwd_pane:get_current_working_dir()
--             if url ~= nil then
--               cwd = url.file_path
--               cwd_pane:tab():set_title(cwd)
--             end
--
--             main_pane:activate()
--           elseif mode == "full" then
--             cwd_pane:send_text ' exit\n'
--             -- elseif mode == "exit" then
--             -- wezterm.log_error("aaa")
--             -- cwd_pane:send_text 'exit\n'
--           end
--         end
--       elseif name == 'cwd' then
--         if value ~= cwd then
--           cwd = value
--
--           cwd_pane:send_text(" cd " .. cwd .. "\n")
--           cwd_pane:send_text ' clear && ls -l\n'
--
--           cwd_pane:tab():set_title(cwd)
--         end
--       end
--     end
--   end)
--
--   wezterm.on('double-click', function(window, pane)
--     if pane:pane_id() == cwd_pane:pane_id() then
--       local text = window:get_selection_text_for_pane(pane)
--
--       main_pane:send_text(" magic-open " .. text .. "\n")
--       main_pane:activate()
--     else
--       wezterm.action.SelectTextAtMouseCursor("Word")
--     end
--   end)
-- end

wezterm.on('gui-startup', function(cmd)
  local _, main_pane, main_window = wezterm.mux.spawn_window(cmd or {})
  main_window:gui_window():maximize()

  -- split_pane(main_pane)
end)

wezterm.on('gui-attached', function(_)
  -- maximize all displayed windows on startup
  local workspace = wezterm.mux.get_active_workspace()
  for _, window in ipairs(wezterm.mux.all_windows()) do
    if window:get_workspace() == workspace then
      window:gui_window():maximize()
    end
  end

  -- split_pane(main_pane)
end)

-- wezterm.on('new-tab', function(window, _)
--   local _, main_pane, _ = window:mux_window():spawn_tab {}
--
--   -- split_pane(main_pane)
-- end)


return {
  font = wezterm.font("GoMono Nerd Font"),
  use_ime = true,
  font_size = 16.0,
  color_scheme = 'Solarized (dark) (terminal.sexy)',
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  window_background_opacity = 0.9,
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
    -- {
    --   key = 't',
    --   mods = 'CTRL|SHIFT',
    --   action = wezterm.action.EmitEvent 'new-tab',
    -- },
    -- {
    --   key = 't',
    --   mods = 'SUPER',
    --   action = wezterm.action.EmitEvent 'new-tab',
    -- },
    {
      key = 'LeftArrow',
      mods = 'SUPER',
      action = wezterm.action.ActivateTabRelative(-1),
    },
    {
      key = 'RightArrow',
      mods = 'SUPER',
      action = wezterm.action.ActivateTabRelative(1),
    },
    {
      key = 'LeftArrow',
      mods = 'SUPER|SHIFT',
      action = wezterm.action.MoveTabRelative(-1),
    },
    {
      key = 'RightArrow',
      mods = 'SUPER|SHIFT',
      action = wezterm.action.MoveTabRelative(1),
    },
  },
  unix_domains = {
    {
      name = 'dev',
      proxy_command = { 'podman', 'exec', '-i', 'dev', 'wezterm', 'cli', 'proxy' },
    },
  },
}

