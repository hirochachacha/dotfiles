-- Git status window functionality
local M = {}

-- Get git status information
function M.get_status()
  local cwd = vim.fn.getcwd()
  local cmd = { "git", "-C", cwd, "status", "--porcelain", "-uall" }
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return nil, "Not a git repository"
  end
  
  local files = {}
  for line in vim.gsplit(result, "\n") do
    if line ~= "" then
      local status = line:sub(1, 2)
      local file = line:sub(4)
      table.insert(files, { status = status, file = file, line = line })
    end
  end
  
  return files
end

-- Format status for display
function M.format_status(status)
  local index = status:sub(1, 1)
  local worktree = status:sub(2, 2)
  
  local symbols = {
    ["M"] = "M",
    ["A"] = "+",
    ["D"] = "-",
    ["R"] = "→",
    ["C"] = "C",
    ["U"] = "U",
    ["?"] = "?",
    ["!"] = "!",
    [" "] = " ",
  }
  
  local colors = {
    ["M"] = "DiagnosticWarn",
    ["A"] = "DiagnosticOk",
    ["D"] = "DiagnosticError",
    ["R"] = "DiagnosticInfo",
    ["C"] = "DiagnosticInfo",
    ["U"] = "DiagnosticError",
    ["?"] = "Comment",
    ["!"] = "Comment",
    [" "] = "Normal",
  }
  
  local idx_sym = symbols[index] or index
  local wt_sym = symbols[worktree] or worktree
  local idx_color = colors[index] or "Normal"
  local wt_color = colors[worktree] or "Normal"
  
  return {
    { idx_sym, idx_color },
    { wt_sym, wt_color },
  }
end

-- Stage/unstage file
function M.toggle_stage(file, status)
  local cwd = vim.fn.getcwd()
  local cmd
  
  if status:sub(1, 1) ~= " " and status:sub(1, 1) ~= "?" then
    -- File is staged, unstage it
    cmd = { "git", "-C", cwd, "reset", "HEAD", file }
  else
    -- File is not staged, stage it
    cmd = { "git", "-C", cwd, "add", file }
  end
  
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

-- Refresh window content
function M.refresh(win_info)
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    vim.api.nvim_win_close(win_info.win, true)
    return
  end
  
  win_info.files = files
  M.render(win_info)
end

-- Render window content
function M.render(win_info)
  local lines = {}
  local highlights = {}
  
  for i, file_info in ipairs(win_info.files) do
    local status_parts = M.format_status(file_info.status)
    local line = status_parts[1][1] .. status_parts[2][1] .. " " .. file_info.file
    table.insert(lines, line)
    
    -- Add highlights
    table.insert(highlights, {
      line = i - 1,
      col = 0,
      end_col = 1,
      hl_group = status_parts[1][2],
    })
    table.insert(highlights, {
      line = i - 1,
      col = 1,
      end_col = 2,
      hl_group = status_parts[2][2],
    })
  end
  
  -- Set buffer content
  vim.api.nvim_set_option_value("modifiable", true, { buf = win_info.buf })
  vim.api.nvim_buf_set_lines(win_info.buf, 0, -1, false, lines)
  
  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(win_info.buf, win_info.ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      win_info.buf,
      win_info.ns,
      hl.hl_group,
      hl.line,
      hl.col,
      hl.end_col
    )
  end
  
  -- Set buffer options
  vim.api.nvim_set_option_value("modifiable", false, { buf = win_info.buf })
  vim.api.nvim_set_option_value("modified", false, { buf = win_info.buf })
end

-- Create git status window
function M.open()
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create namespace for highlights
  local ns = vim.api.nvim_create_namespace("git_status")
  
  -- Calculate window size
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " Git Status ",
    title_pos = "center",
  })
  
  -- Window info object
  local win_info = {
    buf = buf,
    win = win,
    files = files,
    ns = ns,
  }
  
  -- Set buffer options
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "git_status", { buf = buf })
  
  -- Set window options
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  
  -- Set up keymaps
  local function map(key, func)
    vim.keymap.set("n", key, func, { buffer = buf, nowait = true })
  end
  
  -- Stage/unstage on Enter or 's'
  local function toggle_stage_current()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local file_info = win_info.files[line]
    if file_info then
      if M.toggle_stage(file_info.file, file_info.status) then
        M.refresh(win_info)
      end
    end
  end
  
  map("<CR>", toggle_stage_current)
  map("s", toggle_stage_current)
  
  -- Refresh
  map("r", function()
    M.refresh(win_info)
  end)
  
  -- Close
  map("q", function()
    vim.api.nvim_win_close(win, true)
  end)
  map("<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end)
  
  -- Initial render
  M.render(win_info)
  
  return win_info
end

return M