local M = {}

-- Default configuration
local config = {
  debounce_delay = 50,
  icons = {
    modified = "M",
    added = "A",
    deleted = "D",
    renamed = "R",
    copied = "C",
    untracked = "?",
    ignored = "!",
  },
  colors = {
    use_theme = true, -- Use theme colors or custom colors
    staged = nil, -- Custom color for staged files
    unstaged = nil, -- Custom color for unstaged files
    untracked = nil, -- Custom color for untracked files
  },
  keymaps = {
    toggle = "<CR>",
    show_diff = "d",
    open_file = "o",
    delete = "D",
    stage_all = nil,
    track_all = nil,
    unstage_all = nil,
    refresh = "R",
    help = "?",
    commit = "c",
    quit = { "q", "<Esc>" },
  },
  window = {
    width = 80,
    height = 30,
    border = "rounded",
  },
}

-- Debounce timer for refresh operations
local refresh_timer = nil

-- Help content
local help_lines = {
  "",
  "  Git Status - Help",
  "  " .. string.rep("─", 76),
  "",
  "  Navigation:",
  "    j/k         - Move up/down",
  "    g/G         - Go to first/last file",
  "    Tab         - Cycle between sections",
  "",
  "  Actions:",
  "    <CR>        - Toggle file or selection",
  "    d           - Show diff",
  "    o           - Open file",
  "    D           - Delete unstaged changes/file",
  "    c           - Commit staged changes",
  "    R           - Refresh status",
  "",
  "  Visual Mode:",
  "    v           - Start visual selection",
  "    <CR>        - Toggle selected files",
  "",
  "  Other:",
  "    ?           - Toggle this help",
  "    q/<Esc>     - Close window",
  "",
  "  Status Icons:",
  "    M Modified  A Added  D Deleted  R Renamed",
  "    C Copied    ? Untracked  ! Ignored",
  "",
  "  Press any key to close help...",
  "",
}

-- Git operations (reused from original implementation)
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

-- Get branch and remote info
function M.get_branch_info()
  local cwd = vim.fn.getcwd()

  -- Get current branch
  local branch_cmd = { "git", "-C", cwd, "branch", "--show-current" }
  local branch = vim.trim(vim.fn.system(branch_cmd))
  if vim.v.shell_error ~= 0 then
    branch = "detached"
  end

  -- Get remote tracking info
  local ahead_behind = ""
  if branch ~= "detached" then
    local upstream_cmd = { "git", "-C", cwd, "rev-parse", "--abbrev-ref", "@{upstream}" }
    local upstream = vim.trim(vim.fn.system(upstream_cmd))

    if vim.v.shell_error == 0 then
      -- Get ahead/behind counts
      local ahead_cmd = { "git", "-C", cwd, "rev-list", "--count", upstream .. "..HEAD" }
      local behind_cmd = { "git", "-C", cwd, "rev-list", "--count", "HEAD.." .. upstream }

      local ahead = tonumber(vim.trim(vim.fn.system(ahead_cmd))) or 0
      local behind = tonumber(vim.trim(vim.fn.system(behind_cmd))) or 0

      if ahead > 0 or behind > 0 then
        local parts = {}
        if ahead > 0 then
          table.insert(parts, "↑" .. ahead)
        end
        if behind > 0 then
          table.insert(parts, "↓" .. behind)
        end
        ahead_behind = " (" .. table.concat(parts, " ") .. ")"
      end
    end
  end

  -- Get latest commit message (first line only)
  local commit_msg = ""
  local commit_cmd = { "git", "-C", cwd, "log", "-1", "--pretty=format:%s" }
  local msg = vim.trim(vim.fn.system(commit_cmd))
  if vim.v.shell_error == 0 and msg ~= "" then
    commit_msg = " - " .. msg
  end

  return branch, ahead_behind, commit_msg
end

-- Get theme-aware colors
function M.get_theme_colors()
  -- Get color scheme colors dynamically
  local colors = {}

  -- Helper to brighten colors
  local function brighten_color(hex)
    if not hex then
      return nil
    end
    -- Convert hex to RGB
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)

    -- Increase brightness by 20%
    r = math.min(255, math.floor(r * 1.2 + 30))
    g = math.min(255, math.floor(g * 1.2 + 30))
    b = math.min(255, math.floor(b * 1.2 + 30))

    return string.format("#%02x%02x%02x", r, g, b)
  end

  -- Try to get colors from current theme
  local function get_hl_color(group, attr, brighten)
    local hl = vim.api.nvim_get_hl(0, { name = group })
    if hl and hl[attr] then
      local color = string.format("#%06x", hl[attr])
      return brighten and brighten_color(color) or color
    end
    return nil
  end

  -- Define color mappings based on theme's main/accent colors
  -- Staged: Use main theme color (usually blue/primary color)
  colors.staged = config.colors.staged
    or (config.colors.use_theme and (get_hl_color("Function", "fg", true) or get_hl_color("Keyword", "fg", true) or get_hl_color(
      "Special",
      "fg",
      true
    ) or get_hl_color("Title", "fg", true) or get_hl_color("Type", "fg", true)))
    or "#3b82f6" -- Blue fallback

  -- Unstaged: Use accent color (usually warm color like orange/yellow)
  colors.unstaged = config.colors.unstaged
    or (config.colors.use_theme and (get_hl_color("String", "fg", true) or get_hl_color("Number", "fg", true) or get_hl_color(
      "Constant",
      "fg",
      true
    ) or get_hl_color("DiagnosticWarn", "fg", true) or get_hl_color("WarningMsg", "fg", true)))
    or "#f59e0b" -- Orange fallback

  -- Deleted: Keep red for deletions
  colors.deleted = get_hl_color("DiagnosticError", "fg", true)
    or get_hl_color("ErrorMsg", "fg", true)
    or get_hl_color("Exception", "fg", true)
    or "#ef4444" -- Red fallback

  -- Untracked: Use subdued comment color (no brightening)
  colors.untracked = config.colors.untracked
    or (config.colors.use_theme and (get_hl_color("Comment", "fg") or get_hl_color("NonText", "fg")))
    or "#6b7280" -- Gray fallback

  -- Section headers match their content
  colors.section_staged = colors.staged
  colors.section_unstaged = colors.unstaged
  colors.section_untracked = colors.untracked

  return colors
end

-- Create custom highlight groups based on current theme
function M.setup_theme_highlights()
  local colors = M.get_theme_colors()

  -- Define custom highlight groups (bg = "NONE" to respect transparency)
  vim.api.nvim_set_hl(0, "GitStatusStaged", { fg = colors.staged, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusUnstaged", { fg = colors.unstaged, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusDeleted", { fg = colors.deleted, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusUntracked", { fg = colors.untracked, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusSectionStaged", { fg = colors.section_staged, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusSectionUnstaged", { fg = colors.section_unstaged, bold = true, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusSectionUntracked", { fg = colors.section_untracked, bg = "NONE" })

  -- Lighter versions for filenames (no bold, slightly dimmed)
  vim.api.nvim_set_hl(0, "GitStatusStagedFile", { fg = colors.staged, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusUnstagedFile", { fg = colors.unstaged, bg = "NONE" })
  vim.api.nvim_set_hl(0, "GitStatusUntrackedFile", { fg = colors.untracked, bg = "NONE" })

  -- Check if we need to set transparent border
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  if not normal_hl.bg then
    -- Get current FloatBorder color
    local float_border_hl = vim.api.nvim_get_hl(0, { name = "FloatBorder" })
    local border_fg = float_border_hl.fg or colors.untracked

    -- Override FloatBorder to have transparent background
    vim.api.nvim_set_hl(0, "GitStatusFloatBorder", { fg = border_fg, bg = "NONE" })
  end
end

-- Format status for display with theme-aware colors
function M.format_status(status)
  local index = status:sub(1, 1)
  local worktree = status:sub(2, 2)

  local staged_status = ""
  local unstaged_status = ""
  local staged_color = "Normal"
  local unstaged_color = "Normal"

  -- Index (staged) status with icons
  if index == "M" then
    staged_status = config.icons.modified
    staged_color = "GitStatusStaged"
  elseif index == "A" then
    staged_status = config.icons.added
    staged_color = "GitStatusStaged"
  elseif index == "D" then
    staged_status = config.icons.deleted
    staged_color = "GitStatusDeleted"
  elseif index == "R" then
    staged_status = config.icons.renamed
    staged_color = "GitStatusStaged"
  elseif index == "C" then
    staged_status = config.icons.copied
    staged_color = "GitStatusStaged"
  else
    staged_status = "·"
    staged_color = "Comment"
  end

  -- Worktree (unstaged) status with icons
  if worktree == "M" then
    unstaged_status = config.icons.modified
    unstaged_color = "GitStatusUnstaged"
  elseif worktree == "D" then
    unstaged_status = config.icons.deleted
    unstaged_color = "GitStatusDeleted"
  elseif worktree == "?" then
    unstaged_status = config.icons.untracked
    unstaged_color = "GitStatusUntracked"
  elseif worktree == "!" then
    unstaged_status = config.icons.ignored
    unstaged_color = "GitStatusUntracked"
  else
    unstaged_status = "·"
    unstaged_color = "Comment"
  end

  return {
    { staged_status, staged_color },
    { unstaged_status, unstaged_color },
  }
end

-- Format filename for display with wrapping
function M.format_filename(file, status)
  local max_width = config.window.width - 8 -- Account for indent and status symbol
  local lines = {}

  -- Handle renamed files specially
  if status:sub(1, 1) == "R" and file:match("->") then
    local old_file, new_file = file:match("^(.+)%s*%->%s*(.+)$")
    if old_file and new_file then
      old_file = vim.trim(old_file)
      new_file = vim.trim(new_file)

      -- Format as "old_file"
      -- "     -> new_file"
      if #old_file <= max_width then
        table.insert(lines, old_file)

        -- Add continuation line with arrow and new filename
        local arrow_line = "-> " .. new_file
        if #arrow_line <= max_width - 4 then
          table.insert(lines, "    " .. arrow_line)
        else
          -- If arrow + new filename is too long, put arrow on separate line
          table.insert(lines, "    ->")
          local wrapped_new = M.wrap_text(new_file, max_width - 4)
          for _, wrapped_line in ipairs(wrapped_new) do
            table.insert(lines, "    " .. wrapped_line)
          end
        end
      else
        -- If old filename is too long, wrap it
        local wrapped_old = M.wrap_text(old_file, max_width)
        for _, wrapped_line in ipairs(wrapped_old) do
          table.insert(lines, wrapped_line)
        end

        -- Add arrow and new filename
        local arrow_line = "-> " .. new_file
        if #arrow_line <= max_width - 4 then
          table.insert(lines, "    " .. arrow_line)
        else
          table.insert(lines, "    ->")
          local wrapped_new = M.wrap_text(new_file, max_width - 4)
          for _, wrapped_line in ipairs(wrapped_new) do
            table.insert(lines, "    " .. wrapped_line)
          end
        end
      end
    else
      -- Fallback for malformed rename
      local wrapped = M.wrap_text(file, max_width)
      for _, wrapped_line in ipairs(wrapped) do
        table.insert(lines, wrapped_line)
      end
    end
  else
    -- Regular file, just wrap if too long
    if #file <= max_width then
      table.insert(lines, file)
    else
      local wrapped = M.wrap_text(file, max_width)
      for _, wrapped_line in ipairs(wrapped) do
        table.insert(lines, wrapped_line)
      end
    end
  end

  return lines
end

-- Wrap text to specified width
function M.wrap_text(text, width)
  local lines = {}
  local current_line = ""

  -- Split by path separator to try to break at logical points
  local parts = vim.split(text, "/", { plain = true })

  for i, part in ipairs(parts) do
    local separator = (i < #parts) and "/" or ""
    local addition = part .. separator

    if #current_line == 0 then
      current_line = addition
    elseif #current_line + #addition <= width then
      current_line = current_line .. addition
    else
      -- Current line would be too long, start a new line
      if #current_line > 0 then
        table.insert(lines, current_line)
        current_line = addition
      else
        -- Even the single part is too long, force break
        if #addition <= width then
          current_line = addition
        else
          -- Break the part itself
          while #addition > 0 do
            local chunk = addition:sub(1, width)
            table.insert(lines, chunk)
            addition = addition:sub(width + 1)
          end
          current_line = ""
        end
      end
    end
  end

  if #current_line > 0 then
    table.insert(lines, current_line)
  end

  return lines
end

-- Stage/unstage file (reused from original)
function M.toggle_stage(file, status)
  local cwd = vim.fn.getcwd()
  local success = true

  if status:sub(1, 1) ~= " " and status:sub(1, 1) ~= "?" then
    -- File is staged, unstage it
    if status:sub(1, 1) == "R" and file:match("->") then
      -- Handle renamed files: "old.txt -> new.txt"
      local old_file, new_file = file:match("^(.+)%s*%->%s*(.+)$")
      if old_file and new_file then
        old_file = vim.trim(old_file)
        new_file = vim.trim(new_file)

        -- Unstage the rename operation completely
        -- First, reset the new file
        local cmd1 = { "git", "-C", cwd, "reset", "HEAD", new_file }
        vim.fn.system(cmd1)
        if vim.v.shell_error ~= 0 then
          success = false
        end

        -- Then, restore the old file to staged if it was deleted
        local cmd2 = { "git", "-C", cwd, "reset", "HEAD", old_file }
        vim.fn.system(cmd2)
        if vim.v.shell_error ~= 0 then
          -- If reset fails, it might mean the old file didn't exist in HEAD
          -- In that case, this is likely a new file rename, which is fine
        end
      else
        -- Fallback for malformed rename
        local cmd = { "git", "-C", cwd, "reset", "HEAD", file }
        vim.fn.system(cmd)
        success = vim.v.shell_error == 0
      end
    else
      -- Regular staged file
      local cmd = { "git", "-C", cwd, "reset", "HEAD", file }
      vim.fn.system(cmd)
      success = vim.v.shell_error == 0
    end
  else
    -- File is not staged, stage it
    local cmd = { "git", "-C", cwd, "add", file }
    vim.fn.system(cmd)
    success = vim.v.shell_error == 0
  end

  return success
end

-- Delete unstaged changes or files
function M.delete_changes(file, status, silent)
  local cwd = vim.fn.getcwd()
  local success = true
  
  local index_status = status:sub(1, 1)
  local worktree_status = status:sub(2, 2)
  
  if worktree_status == "?" then
    -- Untracked file - delete the file
    local cmd = { "rm", file }
    vim.fn.system(cmd)
    success = vim.v.shell_error == 0
    
    if not silent then
      if success then
        vim.notify("Deleted file: " .. file, vim.log.levels.INFO)
      else
        vim.notify("Failed to delete file: " .. file, vim.log.levels.ERROR)
      end
    end
  elseif worktree_status ~= " " then
    -- Unstaged changes - discard them
    if worktree_status == "D" then
      -- File was deleted in worktree, restore it
      local cmd = { "git", "-C", cwd, "restore", file }
      vim.fn.system(cmd)
      success = vim.v.shell_error == 0
      
      if not silent then
        if success then
          vim.notify("Restored file: " .. file, vim.log.levels.INFO)
        else
          vim.notify("Failed to restore file: " .. file, vim.log.levels.ERROR)
        end
      end
    else
      -- Modified/added file, discard changes
      local cmd = { "git", "-C", cwd, "restore", file }
      vim.fn.system(cmd)
      success = vim.v.shell_error == 0
      
      if not silent then
        if success then
          vim.notify("Discarded changes: " .. file, vim.log.levels.INFO)
        else
          vim.notify("Failed to discard changes: " .. file, vim.log.levels.ERROR)
        end
      end
    end
  else
    -- File has no unstaged changes
    if not silent then
      vim.notify("No unstaged changes to delete for: " .. file, vim.log.levels.WARN)
    end
    success = false
  end
  
  return success
end

-- Separate files into sections (reused logic)
function M.categorize_files(files)
  local staged_files = {}
  local unstaged_files = {}
  local untracked_files = {}

  for _, file_info in ipairs(files) do
    local index = file_info.status:sub(1, 1)
    local worktree = file_info.status:sub(2, 2)

    if index ~= " " and index ~= "?" then
      table.insert(staged_files, file_info)
    elseif worktree == "?" then
      table.insert(untracked_files, file_info)
    elseif worktree ~= " " then
      table.insert(unstaged_files, file_info)
    end
  end

  return {
    staged = staged_files,
    unstaged = unstaged_files,
    untracked = untracked_files,
  }
end

-- Create content lines for snacks.win
function M.create_content(files_by_section)
  local lines = {}
  local highlights = {}
  local sections = {}
  local file_lines = {} -- Track which lines correspond to actual files (not continuations)

  -- Get branch info
  local branch, remote_info, commit_msg = M.get_branch_info()

  -- Header with padding
  table.insert(lines, "") -- Top padding
  table.insert(lines, "  " .. branch .. remote_info .. commit_msg)
  table.insert(lines, "  " .. string.rep("─", 76)) -- Use single line like Scratch
  table.insert(lines, "")

  -- Staged section
  if #files_by_section.staged > 0 then
    table.insert(lines, "  ▼ Staged for commit (" .. #files_by_section.staged .. " files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "GitStatusSectionStaged",
    })

    local header_line = #lines
    local start_line = #lines + 1 -- Will be the first file line

    for _, file_info in ipairs(files_by_section.staged) do
      local status_parts = M.format_status(file_info.status)
      local formatted_lines = M.format_filename(file_info.file, file_info.status)

      for i, file_line in ipairs(formatted_lines) do
        local line = "    " .. (i == 1 and status_parts[1][1] or " ") .. " " .. file_line
        table.insert(lines, line)

        -- Mark only the first line as selectable
        file_lines[#lines] = (i == 1) and file_info or nil

        -- Highlight status symbol (only on first line)
        if i == 1 then
          table.insert(highlights, {
            line = #lines - 1,
            col = 4, -- Adjusted for 4 spaces indent
            end_col = 5,
            hl_group = status_parts[1][2],
          })
        end

        -- Highlight filename with lighter color
        table.insert(highlights, {
          line = #lines - 1,
          col = 6, -- After status symbol and space
          end_col = -1,
          hl_group = "GitStatusStagedFile",
        })
      end
    end

    sections.staged = {
      header_line = header_line,
      start_line = start_line,
      end_line = #lines, -- Last file line
      files = files_by_section.staged,
    }
  else
    table.insert(lines, "  ▼ Staged for commit (no files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "Comment",
    })

    sections.staged = {
      header_line = #lines, -- Store header line
      start_line = #lines + 1,
      end_line = #lines,
      files = {},
    }
  end

  -- Unstaged section
  table.insert(lines, "")
  if #files_by_section.unstaged > 0 then
    table.insert(lines, "  ▼ Unstaged changes (" .. #files_by_section.unstaged .. " files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "GitStatusSectionUnstaged",
    })

    local header_line = #lines
    local start_line = #lines + 1

    for _, file_info in ipairs(files_by_section.unstaged) do
      local status_parts = M.format_status(file_info.status)
      local formatted_lines = M.format_filename(file_info.file, file_info.status)

      for i, file_line in ipairs(formatted_lines) do
        local line = "    " .. (i == 1 and status_parts[2][1] or " ") .. " " .. file_line
        table.insert(lines, line)

        -- Mark only the first line as selectable
        file_lines[#lines] = (i == 1) and file_info or nil

        -- Highlight status symbol (only on first line)
        if i == 1 then
          table.insert(highlights, {
            line = #lines - 1,
            col = 4,
            end_col = 5,
            hl_group = status_parts[2][2],
          })
        end

        -- Highlight filename with lighter color
        table.insert(highlights, {
          line = #lines - 1,
          col = 6, -- After status symbol and space
          end_col = -1,
          hl_group = "GitStatusUnstagedFile",
        })
      end
    end

    sections.unstaged = {
      header_line = header_line,
      start_line = start_line,
      end_line = #lines,
      files = files_by_section.unstaged,
    }
  else
    table.insert(lines, "  ▼ Unstaged changes (no files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "Comment",
    })

    sections.unstaged = {
      header_line = #lines, -- Store header line
      start_line = #lines + 1,
      end_line = #lines,
      files = {},
    }
  end

  -- Untracked section
  table.insert(lines, "")
  if #files_by_section.untracked > 0 then
    table.insert(lines, "  ▼ Untracked files (" .. #files_by_section.untracked .. " files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "GitStatusSectionUntracked",
    })

    local header_line = #lines
    local start_line = #lines + 1

    for _, file_info in ipairs(files_by_section.untracked) do
      local status_parts = M.format_status(file_info.status)
      local formatted_lines = M.format_filename(file_info.file, file_info.status)

      for i, file_line in ipairs(formatted_lines) do
        local line = "    " .. (i == 1 and status_parts[2][1] or " ") .. " " .. file_line
        table.insert(lines, line)

        -- Mark only the first line as selectable
        file_lines[#lines] = (i == 1) and file_info or nil

        -- Highlight status symbol (only on first line)
        if i == 1 then
          table.insert(highlights, {
            line = #lines - 1,
            col = 4,
            end_col = 5,
            hl_group = status_parts[2][2],
          })
        end

        -- Highlight filename with lighter color
        table.insert(highlights, {
          line = #lines - 1,
          col = 6, -- After status symbol and space
          end_col = -1,
          hl_group = "GitStatusUntrackedFile",
        })
      end
    end

    sections.untracked = {
      header_line = header_line,
      start_line = start_line,
      end_line = #lines,
      files = files_by_section.untracked,
    }
  else
    table.insert(lines, "  ▼ Untracked files (no files)")
    table.insert(highlights, {
      line = #lines - 1,
      col = 2,
      end_col = -1,
      hl_group = "Comment",
    })

    sections.untracked = {
      header_line = #lines, -- Store header line
      start_line = #lines + 1,
      end_line = #lines,
      files = {},
    }
  end

  -- Bottom padding
  table.insert(lines, "")

  return {
    lines = lines,
    highlights = highlights,
    sections = sections,
    file_lines = file_lines,
  }
end

-- Main function to open git status using snacks.nvim
function M.open()
  -- Setup theme-aware highlights
  M.setup_theme_highlights()

  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local files_by_section = M.categorize_files(files)
  
  -- Check if there are any files to display
  if #files_by_section.staged == 0 and #files_by_section.unstaged == 0 and #files_by_section.untracked == 0 then
    vim.notify("No staged, unstaged, or untracked files", vim.log.levels.INFO)
    return
  end
  
  local content_data = M.create_content(files_by_section)

  -- Check if Normal has transparent background
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local has_transparent_bg = not normal_hl.bg

  -- Create snacks.win with our content
  local win = require("snacks").win({
    title = " Git Status ",
    title_pos = "center",
    width = config.window.width,
    height = config.window.height,
    border = config.window.border,
    backdrop = not has_transparent_bg, -- Disable backdrop if transparent background
    wo = {
      number = false,
      relativenumber = false,
      signcolumn = "no",
      wrap = false,
      winblend = 0, -- No transparency for the window itself
      cursorline = true, -- Enable cursor line highlight
      winhighlight = has_transparent_bg
          and "Normal:Normal,FloatBorder:GitStatusFloatBorder,NormalFloat:Normal,FloatTitle:GitStatusFloatBorder,CursorLine:CursorLine"
        or "CursorLine:CursorLine",
    },
    bo = {
      buftype = "nofile",
      bufhidden = "wipe",
      swapfile = false,
      filetype = "git_status_snacks",
    },
    keys = {
      ["q"] = "close",
      ["<CR>"] = function(self)
        local mode = vim.api.nvim_get_mode().mode
        if mode == "v" or mode == "V" or mode == "\22" then
          M.handle_toggle_visual(self, content_data)
        else
          M.handle_toggle(self, content_data)
        end
      end,
      ["d"] = function(self)
        M.handle_show_diff(self, content_data)
      end,
      ["o"] = function(self)
        M.handle_open_file(self, content_data)
      end,
      ["D"] = function(self)
        M.handle_delete(self, content_data)
      end,
      ["R"] = function(self)
        M.refresh(self)
      end,
      ["j"] = function(self)
        M.smart_move_down(self, content_data)
      end,
      ["k"] = function(self)
        M.smart_move_up(self, content_data)
      end,
      ["<Tab>"] = function(self)
        M.toggle_section(self, content_data)
      end,
      ["g"] = function(self)
        M.goto_first_file(self, content_data)
      end,
      ["G"] = function(self)
        M.goto_last_file(self, content_data)
      end,
      ["?"] = function(self)
        M.show_help(self)
      end,
      ["c"] = function(self)
        M.open_commit(self)
      end,
    },
    on_buf = function(self)
      -- Set buffer content
      vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, content_data.lines)

      -- Apply highlights
      local ns = vim.api.nvim_create_namespace("git_status_snacks")
      for _, hl in ipairs(content_data.highlights) do
        vim.api.nvim_buf_add_highlight(self.buf, ns, hl.hl_group, hl.line, hl.col, hl.end_col)
      end

      -- Set buffer as read-only after content is set
      vim.schedule(function()
        vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
        vim.api.nvim_set_option_value("readonly", true, { buf = self.buf })
      end)

      -- Store sections data for later use
      self.sections = content_data.sections
      self.files_by_section = files_by_section
      self.file_lines = content_data.file_lines

      -- Add visual line mode keymaps and disable other visual modes
      vim.schedule(function()
        -- Visual line mode (V) keymaps  
        vim.keymap.set("x", "<CR>", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.handle_toggle_visual(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("x", "D", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.handle_delete_visual(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("x", "j", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.visual_move_down(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("x", "k", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.visual_move_up(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("x", "g", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.visual_goto_first_file(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("x", "G", function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "V" then -- Visual line mode only
            M.visual_goto_last_file(self, content_data)
          end
        end, { buffer = self.buf, nowait = true })

        -- Disable Tab in visual mode
        vim.keymap.set("x", "<Tab>", function()
          -- Do nothing - prevent section switching in visual mode
        end, { buffer = self.buf, nowait = true })

        -- Disable character-wise visual mode (v) and block visual mode (Ctrl-V)
        vim.keymap.set("n", "v", function()
          -- Force visual line mode instead
          vim.cmd("normal! V")
        end, { buffer = self.buf, nowait = true })

        vim.keymap.set("n", "<C-v>", function()
          -- Force visual line mode instead
          vim.cmd("normal! V")
        end, { buffer = self.buf, nowait = true })

        -- Disable common editing keys that might interfere
        local disabled_keys = { "s", "S", "x", "X", "i", "I", "a", "A", "u", "O", "p", "P", "r" }
        for _, key in ipairs(disabled_keys) do
          vim.keymap.set("n", key, function() end, { buffer = self.buf, nowait = true })
        end
      end)
    end,
    on_win = function(self)
      -- Set initial cursor position after window is created
      local initial_line = 1
      if content_data.sections.staged and #content_data.sections.staged.files > 0 then
        initial_line = content_data.sections.staged.start_line
      elseif content_data.sections.unstaged and #content_data.sections.unstaged.files > 0 then
        initial_line = content_data.sections.unstaged.start_line
      elseif content_data.sections.untracked and #content_data.sections.untracked.files > 0 then
        initial_line = content_data.sections.untracked.start_line
      end
      vim.api.nvim_win_set_cursor(self.win, { initial_line, 0 })
    end,
  })

  return win
end

-- Helper function to get current file from cursor position
function M.get_current_file(win)
  local line = vim.api.nvim_win_get_cursor(win.win)[1]

  -- Use file_lines mapping to get the actual file info
  return win.file_lines and win.file_lines[line] or nil
end

-- Get file info at specific line
function M.get_file_at_line(win, line_number)
  if not win.file_lines or not line_number then
    return nil
  end
  
  local total_lines = vim.api.nvim_buf_line_count(win.buf)
  if line_number < 1 or line_number > total_lines then
    return nil
  end
  
  return win.file_lines[line_number]
end

-- Get current section info
function M.get_current_section(win)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]

  -- Check staged section (including header)
  if win.sections.staged then
    if current_line == win.sections.staged.header_line then
      return "staged", win.sections.staged
    elseif
      #win.sections.staged.files > 0
      and current_line >= win.sections.staged.start_line
      and current_line <= win.sections.staged.end_line
    then
      return "staged", win.sections.staged
    end
  end

  -- Check unstaged section (including header)
  if win.sections.unstaged then
    if current_line == win.sections.unstaged.header_line then
      return "unstaged", win.sections.unstaged
    elseif
      #win.sections.unstaged.files > 0
      and current_line >= win.sections.unstaged.start_line
      and current_line <= win.sections.unstaged.end_line
    then
      return "unstaged", win.sections.unstaged
    end
  end

  -- Check untracked section (including header)
  if win.sections.untracked then
    if current_line == win.sections.untracked.header_line then
      return "untracked", win.sections.untracked
    elseif
      #win.sections.untracked.files > 0
      and current_line >= win.sections.untracked.start_line
      and current_line <= win.sections.untracked.end_line
    then
      return "untracked", win.sections.untracked
    end
  end

  return nil, nil
end

-- Helper function to set cursor after operations
function M.set_cursor_after_operation(win, section_type, prefer_same_position, was_on_header)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]

  -- Helper to avoid placing cursor on header line
  local function get_safe_line(section)
    if section and #section.files > 0 then
      return section.start_line -- First file line
    end
    return nil
  end

  -- Calculate the relative position in the old section
  local relative_position = 0
  if prefer_same_position then
    local old_section = nil
    if section_type == "staged" then
      old_section = win.sections.staged
    elseif section_type == "unstaged" then
      old_section = win.sections.unstaged
    elseif section_type == "untracked" then
      old_section = win.sections.untracked
    end

    if old_section and old_section.start_line then
      relative_position = current_line - old_section.start_line
    end
  end

  -- Try to stay in the same section if it still has files
  if section_type == "staged" and win.sections.staged and #win.sections.staged.files > 0 then
    if prefer_same_position and not was_on_header then
      -- Calculate new position based on relative position, but ensure we're on a file line
      local new_line = win.sections.staged.start_line + math.min(relative_position, #win.sections.staged.files - 1)
      vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
    else
      vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
    end
  elseif section_type == "unstaged" and win.sections.unstaged and #win.sections.unstaged.files > 0 then
    if prefer_same_position and not was_on_header then
      local new_line = win.sections.unstaged.start_line + math.min(relative_position, #win.sections.unstaged.files - 1)
      vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
    else
      vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
    end
  elseif section_type == "untracked" and win.sections.untracked and #win.sections.untracked.files > 0 then
    if prefer_same_position and not was_on_header then
      local new_line = win.sections.untracked.start_line
        + math.min(relative_position, #win.sections.untracked.files - 1)
      vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
    else
      vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
    end
  else
    -- Original section is empty, move to appropriate section based on the operation
    if section_type == "staged" then
      -- Staged files were unstaged, go to unstaged section
      local line = get_safe_line(win.sections.unstaged) or get_safe_line(win.sections.untracked)
      if line then
        vim.api.nvim_win_set_cursor(win.win, { line, 0 })
      end
    elseif section_type == "unstaged" then
      -- Unstaged files were staged, go to untracked section first (or staged)
      local line = get_safe_line(win.sections.untracked) or get_safe_line(win.sections.staged)
      if line then
        vim.api.nvim_win_set_cursor(win.win, { line, 0 })
      end
    elseif section_type == "untracked" then
      -- Untracked files were staged, go to staged section
      local line = get_safe_line(win.sections.staged) or get_safe_line(win.sections.unstaged)
      if line then
        vim.api.nvim_win_set_cursor(win.win, { line, 0 })
      end
    end
  end
end

-- Show diff for current file
function M.handle_show_diff(win, content_data)
  local file_info = M.get_current_file(win)
  if file_info then
    local file_path = file_info.file
    local status = file_info.status
    local index_status = status:sub(1, 1)
    local worktree_status = status:sub(2, 2)
    
    -- Handle renamed files - show diff for the new file
    if index_status == "R" and file_path:match("->") then
      local old_file, new_file = file_path:match("^(.+)%s*%->%s*(.+)$")
      if new_file then
        file_path = vim.trim(new_file)
      end
    end
    
    local diff_cmd
    local diff_title
    
    -- Determine which diff to show based on file status
    if index_status ~= " " and index_status ~= "?" then
      -- File is staged, show staged diff (diff --cached)
      diff_cmd = { "git", "diff", "--cached", file_path }
      diff_title = "Staged changes: " .. file_path
    elseif worktree_status ~= " " and worktree_status ~= "?" then
      -- File has unstaged changes
      diff_cmd = { "git", "diff", file_path }
      diff_title = "Unstaged changes: " .. file_path
    elseif worktree_status == "?" then
      -- Untracked file, show the entire file content
      diff_cmd = { "git", "show", "HEAD:" .. file_path }
      diff_title = "Untracked file: " .. file_path
      -- If that fails, just show the file content
      if vim.fn.system("git show HEAD:" .. vim.fn.shellescape(file_path)) == "" then
        diff_cmd = { "cat", file_path }
      end
    else
      vim.notify("No changes to show for: " .. file_path, vim.log.levels.INFO)
      return
    end
    
    -- Execute diff command
    local result = vim.fn.system(diff_cmd)
    
    -- Handle errors
    if vim.v.shell_error ~= 0 then
      if worktree_status == "?" then
        -- For untracked files, try to read the file directly
        local ok, file_content = pcall(vim.fn.readfile, file_path)
        if ok and file_content then
          result = table.concat(file_content, "\n")
        else
          vim.notify("File not found or cannot be read: " .. file_path, vim.log.levels.ERROR)
          return
        end
      else
        -- For tracked files, check if file exists
        if vim.fn.filereadable(file_path) == 0 then
          vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
          return
        else
          vim.notify("Git diff failed for: " .. file_path, vim.log.levels.ERROR)
          return
        end
      end
    end
    
    if result == "" or result == nil then
      vim.notify("No diff content for: " .. file_path, vim.log.levels.INFO)
      return
    end
    
    -- Show diff in a floating window
    M.show_diff_window(result, diff_title)
  end
end

-- Delete unstaged changes or files
function M.handle_delete(win, content_data)
  local file_info = M.get_current_file(win)
  if file_info then
    local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
    local section_type, section = M.get_current_section(win)
    
    -- Show confirmation dialog
    local action_text = ""
    local worktree_status = file_info.status:sub(2, 2)
    
    if worktree_status == "?" then
      action_text = "Delete file: " .. file_info.file
    elseif worktree_status == "D" then
      action_text = "Restore deleted file: " .. file_info.file
    elseif worktree_status ~= " " then
      action_text = "Discard changes: " .. file_info.file
    else
      vim.notify("No unstaged changes to delete for: " .. file_info.file, vim.log.levels.WARN)
      return
    end
    
    local choice = vim.fn.confirm(action_text .. "?", "&Yes\n&No", 2)
    if choice == 1 then
      if M.delete_changes(file_info.file, file_info.status) then
        M.refresh(win, true) -- Use immediate refresh
        
        -- Position cursor appropriately after delete
        vim.schedule(function()
          if section_type == "unstaged" then
            -- For unstaged files, try to stay in unstaged section first
            if win.sections.unstaged and #win.sections.unstaged.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.unstaged)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            elseif win.sections.untracked and #win.sections.untracked.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.untracked)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            elseif win.sections.staged and #win.sections.staged.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.staged)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            end
          elseif section_type == "untracked" then
            -- For untracked files, try to stay in untracked section first
            if win.sections.untracked and #win.sections.untracked.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.untracked)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.unstaged)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            elseif win.sections.staged and #win.sections.staged.files > 0 then
              local target_line = M.find_next_selectable_line_in_section(win, win.sections.staged)
              if target_line then
                vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
              end
            end
          end
        end)
      end
    end
  end
end

-- Open current file
function M.handle_open_file(win, content_data)
  local file_info = M.get_current_file(win)
  if file_info then
    local file_path = file_info.file
    
    -- Check if file is deleted
    local status = file_info.status
    local index_status = status:sub(1, 1)
    local worktree_status = status:sub(2, 2)
    
    if index_status == "D" or worktree_status == "D" then
      vim.notify("Cannot open deleted file: " .. file_path, vim.log.levels.WARN)
      return
    end

    -- Handle renamed files - open the new file
    if index_status == "R" and file_path:match("->") then
      local old_file, new_file = file_path:match("^(.+)%s*%->%s*(.+)$")
      if new_file then
        file_path = vim.trim(new_file)
      end
    end

    -- Check if file exists before opening
    if vim.fn.filereadable(file_path) == 0 then
      vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
      return
    end
    
    -- Open the file in background (don't change focus or refresh git status)
    vim.schedule(function()
      -- Save current window
      local current_win = vim.api.nvim_get_current_win()

      -- Find a suitable window to open the file (not floating windows)
      local target_win = nil
      for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(winid)
        if config.relative == "" and winid ~= current_win then
          target_win = winid
          break
        end
      end
      
      -- If no suitable window found, create one
      if not target_win then
        vim.cmd("silent! split")
        target_win = vim.api.nvim_get_current_win()
      end
      
      -- Open file in target window
      vim.api.nvim_set_current_win(target_win)
      local success = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(file_path))
      if not success then
        vim.notify("Failed to open file: " .. file_path, vim.log.levels.ERROR)
      end

      -- Return focus to git status window
      vim.api.nvim_set_current_win(current_win)
    end)
  end
end

-- Toggle current file
function M.handle_toggle(win, content_data)
  local file_info = M.get_current_file(win)
  if file_info then
    local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
    local section_type, section = M.get_current_section(win)

    if M.toggle_stage(file_info.file, file_info.status) then
      M.refresh(win, true) -- Use immediate refresh

      -- Try to stay in the same section if it still has files
      if section_type == "staged" and win.sections.staged and #win.sections.staged.files > 0 then
        local new_line = math.min(current_line, win.sections.staged.end_line)
        new_line = math.max(new_line, win.sections.staged.start_line)
        vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
      elseif section_type == "unstaged" and win.sections.unstaged and #win.sections.unstaged.files > 0 then
        local new_line = math.min(current_line, win.sections.unstaged.end_line)
        new_line = math.max(new_line, win.sections.unstaged.start_line)
        vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
      elseif section_type == "untracked" and win.sections.untracked and #win.sections.untracked.files > 0 then
        local new_line = math.min(current_line, win.sections.untracked.end_line)
        new_line = math.max(new_line, win.sections.untracked.start_line)
        vim.api.nvim_win_set_cursor(win.win, { new_line, 0 })
      else
        -- Original section is empty, move to appropriate section based on the operation
        if section_type == "staged" then
          -- Staged files were unstaged, go to unstaged section
          if win.sections.unstaged and #win.sections.unstaged.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
          elseif win.sections.untracked and #win.sections.untracked.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
          end
        elseif section_type == "unstaged" then
          -- Unstaged files were staged, go to untracked section first
          if win.sections.untracked and #win.sections.untracked.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
          elseif win.sections.staged and #win.sections.staged.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
          end
        elseif section_type == "untracked" then
          -- Untracked files were staged, go to staged section
          if win.sections.staged and #win.sections.staged.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
          elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
            vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
          end
        end
      end
    end
  end
end

-- Internal refresh implementation
local function do_refresh(win)
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local files_by_section = M.categorize_files(files)
  local content_data = M.create_content(files_by_section)

  -- Store current cursor position
  local cursor_line = vim.api.nvim_win_get_cursor(win.win)[1]

  -- Update buffer content efficiently
  vim.api.nvim_set_option_value("modifiable", true, { buf = win.buf })
  vim.api.nvim_set_option_value("readonly", false, { buf = win.buf })

  vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, content_data.lines)

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace("git_status_snacks")
  vim.api.nvim_buf_clear_namespace(win.buf, ns, 0, -1)
  for _, hl in ipairs(content_data.highlights) do
    vim.api.nvim_buf_add_highlight(win.buf, ns, hl.hl_group, hl.line, hl.col, hl.end_col)
  end

  vim.api.nvim_set_option_value("readonly", true, { buf = win.buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = win.buf })

  -- Update sections data
  win.sections = content_data.sections
  win.files_by_section = files_by_section
  win.file_lines = content_data.file_lines

  -- Only set cursor position if it's called from refresh() without a specific position request
  -- This will be overridden by handle_toggle when needed
end

-- Debounced refresh function
function M.refresh(win, immediate)
  if refresh_timer then
    vim.fn.timer_stop(refresh_timer)
    refresh_timer = nil
  end

  if immediate then
    do_refresh(win)
  else
    refresh_timer = vim.fn.timer_start(config.debounce_delay, function()
      refresh_timer = nil
      do_refresh(win)
    end)
  end
end

-- Visual mode toggle
function M.handle_toggle_visual(win, content_data)
  -- Get visual selection
  local vstart = vim.fn.getpos("v")
  local vend = vim.fn.getpos(".")
  local start_line = math.min(vstart[2], vend[2])
  local end_line = math.max(vstart[2], vend[2])

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  -- Determine which section the selection starts in
  local selection_section = nil
  local selection_section_info = nil

  if win.sections.staged and #win.sections.staged.files > 0 then
    if start_line >= win.sections.staged.start_line and start_line <= win.sections.staged.end_line then
      selection_section = "staged"
      selection_section_info = win.sections.staged
    end
  end

  if not selection_section and win.sections.unstaged and #win.sections.unstaged.files > 0 then
    if start_line >= win.sections.unstaged.start_line and start_line <= win.sections.unstaged.end_line then
      selection_section = "unstaged"
      selection_section_info = win.sections.unstaged
    end
  end

  if not selection_section and win.sections.untracked and #win.sections.untracked.files > 0 then
    if start_line >= win.sections.untracked.start_line and start_line <= win.sections.untracked.end_line then
      selection_section = "untracked"
      selection_section_info = win.sections.untracked
    end
  end

  if not selection_section then
    vim.notify("No valid files selected", vim.log.levels.WARN)
    return
  end

  -- Restrict selection to the same section
  local section_start = selection_section_info.start_line
  local section_end = selection_section_info.end_line
  local actual_start = math.max(start_line, section_start)
  local actual_end = math.min(end_line, section_end)

  if actual_start > actual_end then
    vim.notify("Selection spans across sections - not allowed", vim.log.levels.WARN)
    return
  end

  -- Count how many selectable files are in the restricted selection
  local selected_file_count = 0
  local first_file_line = nil

  -- Use win.file_lines instead of content_data.file_lines
  local file_lines = win.file_lines or content_data.file_lines

  for line = actual_start, actual_end do
    if file_lines and file_lines[line] then
      selected_file_count = selected_file_count + 1
      if not first_file_line then
        first_file_line = line
      end
    end
  end

  if selected_file_count == 0 then
    vim.notify("No valid files selected in section", vim.log.levels.WARN)
    return
  end

  -- Set cursor to the first selected file and simulate individual toggles
  vim.api.nvim_win_set_cursor(win.win, { first_file_line, 0 })

  -- Simulate each individual toggle operation
  for i = 1, selected_file_count do
    -- Call the individual handle function which will:
    -- 1. Toggle the file at current cursor position
    -- 2. Refresh the display
    -- 3. Move cursor to appropriate next position
    M.handle_toggle(win, content_data)

    -- After refresh, we need to get updated content_data
    local files, err = M.get_status()
    if files then
      local files_by_section = M.categorize_files(files)
      content_data = M.create_content(files_by_section)
      win.sections = content_data.sections
      win.files_by_section = files_by_section
      win.file_lines = content_data.file_lines
    end
  end
end

-- Visual mode delete
function M.handle_delete_visual(win, content_data)
  -- Get visual selection
  local vstart = vim.fn.getpos("v")
  local vend = vim.fn.getpos(".")
  local start_line = math.min(vstart[2], vend[2])
  local end_line = math.max(vstart[2], vend[2])

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  -- Determine which section the selection starts in
  local selection_section = nil
  local selection_section_info = nil

  if win.sections.staged and #win.sections.staged.files > 0 then
    if start_line >= win.sections.staged.start_line and start_line <= win.sections.staged.end_line then
      selection_section = "staged"
      selection_section_info = win.sections.staged
    end
  end

  if not selection_section and win.sections.unstaged and #win.sections.unstaged.files > 0 then
    if start_line >= win.sections.unstaged.start_line and start_line <= win.sections.unstaged.end_line then
      selection_section = "unstaged"
      selection_section_info = win.sections.unstaged
    end
  end

  if not selection_section and win.sections.untracked and #win.sections.untracked.files > 0 then
    if start_line >= win.sections.untracked.start_line and start_line <= win.sections.untracked.end_line then
      selection_section = "untracked"
      selection_section_info = win.sections.untracked
    end
  end

  if not selection_section then
    vim.notify("No valid files selected", vim.log.levels.WARN)
    return
  end

  -- Only allow delete for unstaged and untracked sections
  if selection_section == "staged" then
    vim.notify("Cannot delete staged files. Unstage them first.", vim.log.levels.WARN)
    return
  end

  -- Restrict selection to the same section
  local section_start = selection_section_info.start_line
  local section_end = selection_section_info.end_line
  local actual_start = math.max(start_line, section_start)
  local actual_end = math.min(end_line, section_end)

  if actual_start > actual_end then
    vim.notify("Selection spans across sections - not allowed", vim.log.levels.WARN)
    return
  end

  -- Count how many selectable files are in the restricted selection
  local selected_file_count = 0
  local first_file_line = nil
  local selected_files = {}

  -- Use win.file_lines instead of content_data.file_lines
  local file_lines = win.file_lines or content_data.file_lines

  for line = actual_start, actual_end do
    if file_lines and file_lines[line] then
      selected_file_count = selected_file_count + 1
      if not first_file_line then
        first_file_line = line
      end
      -- Store file info for confirmation dialog
      local file_info = M.get_file_at_line(win, line)
      if file_info then
        table.insert(selected_files, file_info)
      end
    end
  end

  if selected_file_count == 0 then
    vim.notify("No valid files selected in section", vim.log.levels.WARN)
    return
  end

  -- Show confirmation dialog
  local action_text = ""
  if selection_section == "untracked" then
    action_text = "Delete " .. selected_file_count .. " untracked file(s)"
  else
    action_text = "Discard changes for " .. selected_file_count .. " file(s)"
  end

  local choice = vim.fn.confirm(action_text .. "?", "&Yes\n&No", 2)
  if choice ~= 1 then
    return
  end

  -- Set cursor to the first selected file and simulate individual delete operations
  vim.api.nvim_win_set_cursor(win.win, { first_file_line, 0 })

  -- Simulate each individual delete operation
  local success_count = 0
  for i = 1, selected_file_count do
    -- Call the individual delete function (silent mode since we already confirmed)
    local file_info = M.get_current_file(win)
    if file_info then
      if M.delete_changes(file_info.file, file_info.status, true) then
        success_count = success_count + 1
        M.refresh(win, true) -- Use immediate refresh
        
        -- After refresh, we need to get updated content_data
        local files, err = M.get_status()
        if files then
          local files_by_section = M.categorize_files(files)
          content_data = M.create_content(files_by_section)
          win.sections = content_data.sections
          win.files_by_section = files_by_section
          win.file_lines = content_data.file_lines
        end
      end
    end
  end
  
  -- Show final result
  if success_count > 0 then
    if selection_section == "untracked" then
      vim.notify("Deleted " .. success_count .. " file(s)", vim.log.levels.INFO)
    else
      vim.notify("Discarded changes for " .. success_count .. " file(s)", vim.log.levels.INFO)
    end
  end
end

-- Helper function to find next selectable line
function M.find_next_selectable_line(win, current_line)
  local total_lines = vim.api.nvim_buf_line_count(win.buf)

  for line = current_line + 1, total_lines do
    if win.file_lines and win.file_lines[line] then
      return line
    end
  end

  -- Wrap around to beginning
  for line = 1, current_line - 1 do
    if win.file_lines and win.file_lines[line] then
      return line
    end
  end

  return current_line -- No selectable line found
end

-- Helper function to find previous selectable line
function M.find_prev_selectable_line(win, current_line)
  for line = current_line - 1, 1, -1 do
    if win.file_lines and win.file_lines[line] then
      return line
    end
  end

  -- Wrap around to end
  local total_lines = vim.api.nvim_buf_line_count(win.buf)
  for line = total_lines, current_line + 1, -1 do
    if win.file_lines and win.file_lines[line] then
      return line
    end
  end

  return current_line -- No selectable line found
end

-- Helper function to find first selectable line in a section
function M.find_next_selectable_line_in_section(win, section)
  if not section or #section.files == 0 then
    return nil
  end

  -- Search within the section's range for the first selectable line
  for line = section.start_line, section.end_line do
    if win.file_lines and win.file_lines[line] then
      return line
    end
  end

  return nil -- No selectable line found in section
end

-- Smart navigation functions
function M.smart_move_down(win, content_data)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
  local next_line = M.find_next_selectable_line(win, current_line)

  if next_line ~= current_line then
    vim.api.nvim_win_set_cursor(win.win, { next_line, 0 })
  end
end

function M.smart_move_up(win, content_data)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
  local prev_line = M.find_prev_selectable_line(win, current_line)

  if prev_line ~= current_line then
    vim.api.nvim_win_set_cursor(win.win, { prev_line, 0 })
  end
end

-- Visual mode navigation functions (restricted to current section)
function M.visual_move_down(win, content_data)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
  local section_type, section = M.get_current_section(win)

  if not section then
    return
  end

  -- Find next selectable line within the current section
  for line = current_line + 1, section.end_line do
    if win.file_lines and win.file_lines[line] then
      vim.api.nvim_win_set_cursor(win.win, { line, 0 })
      return
    end
  end
end

function M.visual_move_up(win, content_data)
  local current_line = vim.api.nvim_win_get_cursor(win.win)[1]
  local section_type, section = M.get_current_section(win)

  if not section then
    return
  end

  -- Find previous selectable line within the current section
  for line = current_line - 1, section.start_line, -1 do
    if win.file_lines and win.file_lines[line] then
      vim.api.nvim_win_set_cursor(win.win, { line, 0 })
      return
    end
  end
end

function M.visual_goto_first_file(win, content_data)
  local section_type, section = M.get_current_section(win)

  if section and #section.files > 0 then
    local first_line = M.find_next_selectable_line_in_section(win, section)
    if first_line then
      vim.api.nvim_win_set_cursor(win.win, { first_line, 0 })
    end
  end
end

function M.visual_goto_last_file(win, content_data)
  local section_type, section = M.get_current_section(win)

  if section and #section.files > 0 then
    -- Find last selectable line in the section
    for line = section.end_line, section.start_line, -1 do
      if win.file_lines and win.file_lines[line] then
        vim.api.nvim_win_set_cursor(win.win, { line, 0 })
        return
      end
    end
  end
end

-- Section navigation
function M.toggle_section(win, content_data)
  -- Disable in visual mode
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then -- visual, visual line, visual block
    return
  end

  local section_type, section = M.get_current_section(win)

  -- Cycle: staged -> unstaged -> untracked -> staged
  if section_type == "staged" then
    if win.sections.unstaged and #win.sections.unstaged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
    elseif win.sections.untracked and #win.sections.untracked.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
    end
  elseif section_type == "unstaged" then
    if win.sections.untracked and #win.sections.untracked.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
    elseif win.sections.staged and #win.sections.staged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
    end
  elseif section_type == "untracked" then
    if win.sections.staged and #win.sections.staged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
    elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
    end
  else
    -- Not in any section, jump to first available section
    if win.sections.staged and #win.sections.staged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
    elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
    elseif win.sections.untracked and #win.sections.untracked.files > 0 then
      vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
    end
  end
end

-- gg/G navigation
function M.goto_first_file(win, content_data)
  -- Check if in visual mode - restrict to current section
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then -- visual, visual line, visual block
    local section_type, section = M.get_current_section(win)
    if section_type and section then
      vim.api.nvim_win_set_cursor(win.win, { section.start_line, 0 })
    end
    return
  end

  if win.sections.staged and #win.sections.staged.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.start_line, 0 })
  elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.start_line, 0 })
  elseif win.sections.untracked and #win.sections.untracked.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.start_line, 0 })
  end
end

function M.goto_last_file(win, content_data)
  -- Check if in visual mode - restrict to current section
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then -- visual, visual line, visual block
    local section_type, section = M.get_current_section(win)
    if section_type and section then
      vim.api.nvim_win_set_cursor(win.win, { section.end_line, 0 })
    end
    return
  end

  if win.sections.untracked and #win.sections.untracked.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.untracked.end_line, 0 })
  elseif win.sections.unstaged and #win.sections.unstaged.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.unstaged.end_line, 0 })
  elseif win.sections.staged and #win.sections.staged.files > 0 then
    vim.api.nvim_win_set_cursor(win.win, { win.sections.staged.end_line, 0 })
  end
end

-- Bulk operations
function M.stage_all(win)
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  -- Only stage unstaged files (not untracked files)
  local staged_count = 0
  for _, file_info in ipairs(files) do
    local index = file_info.status:sub(1, 1)
    local worktree = file_info.status:sub(2, 2)
    if index == " " and worktree ~= "?" and worktree ~= " " then
      M.toggle_stage(file_info.file, file_info.status)
      staged_count = staged_count + 1
    end
  end

  M.refresh(win)

  -- Fixed destination: untracked, if empty then staged
  if staged_count > 0 then
    vim.schedule(function()
      if win.sections.untracked and #win.sections.untracked.files > 0 then
        local target_line = M.find_next_selectable_line_in_section(win, win.sections.untracked)
        if target_line then
          vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
        end
      elseif win.sections.staged and #win.sections.staged.files > 0 then
        local target_line = M.find_next_selectable_line_in_section(win, win.sections.staged)
        if target_line then
          vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
        end
      end
    end)
  end
end

function M.track_all(win)
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local added_count = 0
  for _, file_info in ipairs(files) do
    if file_info.status:sub(2, 2) == "?" then
      M.toggle_stage(file_info.file, file_info.status)
      added_count = added_count + 1
    end
  end

  M.refresh(win)

  -- Fixed destination: staged
  if added_count > 0 then
    vim.schedule(function()
      if win.sections.staged and #win.sections.staged.files > 0 then
        local target_line = M.find_next_selectable_line_in_section(win, win.sections.staged)
        if target_line then
          vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
        end
      end
    end)
  end
end

function M.unstage_all(win)
  local files, err = M.get_status()
  if not files then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local unstaged_count = 0
  for _, file_info in ipairs(files) do
    if file_info.status:sub(1, 1) ~= " " and file_info.status:sub(1, 1) ~= "?" then
      M.toggle_stage(file_info.file, file_info.status)
      unstaged_count = unstaged_count + 1
    end
  end

  M.refresh(win)

  -- Fixed destination: unstaged, if empty then untracked
  if unstaged_count > 0 then
    vim.schedule(function()
      if win.sections.unstaged and #win.sections.unstaged.files > 0 then
        local target_line = M.find_next_selectable_line_in_section(win, win.sections.unstaged)
        if target_line then
          vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
        end
      elseif win.sections.untracked and #win.sections.untracked.files > 0 then
        local target_line = M.find_next_selectable_line_in_section(win, win.sections.untracked)
        if target_line then
          vim.api.nvim_win_set_cursor(win.win, { target_line, 0 })
        end
      end
    end)
  end
end

-- Open commit window
function M.open_commit(win)
  -- Check if there are staged files
  if not win.sections.staged or #win.sections.staged.files == 0 then
    vim.notify("No files staged for commit", vim.log.levels.WARN)
    return
  end

  -- Close git status window
  win:close()

  -- Open commit window using the existing git_commit function from keymaps
  vim.cmd("normal \\<Space>gcc")
end

-- Show diff in a floating window
function M.show_diff_window(diff_content, title)
  local lines = vim.split(diff_content, "\n")
  
  -- Create buffer for diff
  local diff_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "diff", { buf = diff_buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = diff_buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = diff_buf })
  
  -- Create floating window
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(40, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local diff_win = vim.api.nvim_open_win(diff_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })
  
  -- Set window options
  vim.api.nvim_set_option_value("wrap", false, { win = diff_win })
  vim.api.nvim_set_option_value("cursorline", true, { win = diff_win })
  
  -- Set up keymaps to close diff window
  local close_diff = function()
    if vim.api.nvim_win_is_valid(diff_win) then
      vim.api.nvim_win_close(diff_win, true)
    end
    if vim.api.nvim_buf_is_valid(diff_buf) then
      vim.api.nvim_buf_delete(diff_buf, { force = true })
    end
  end
  
  -- Close on various keys
  local opts = { buffer = diff_buf, nowait = true }
  for _, key in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", key, close_diff, opts)
  end
end

-- Show help overlay
function M.show_help(win)
  -- Create a temporary buffer for help
  local help_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)

  -- Apply highlighting to help buffer
  local ns = vim.api.nvim_create_namespace("git_status_help")
  vim.api.nvim_buf_add_highlight(help_buf, ns, "Title", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(help_buf, ns, "Comment", 2, 0, -1)

  for i = 4, #help_lines - 3 do
    local line = help_lines[i]
    if line:match("^  %w+:$") then
      vim.api.nvim_buf_add_highlight(help_buf, ns, "Title", i - 1, 0, -1)
    elseif line:match("^    %S") then
      -- Highlight keys
      local key_end = line:find(" - ")
      if key_end then
        vim.api.nvim_buf_add_highlight(help_buf, ns, "Special", i - 1, 4, key_end - 1)
      end
    end
  end

  -- Highlight status icons
  vim.api.nvim_buf_add_highlight(help_buf, ns, "Special", 32, 4, -1)
  vim.api.nvim_buf_add_highlight(help_buf, ns, "Special", 33, 4, -1)

  -- Set buffer in current window
  local original_buf = win.buf
  vim.api.nvim_win_set_buf(win.win, help_buf)

  -- Set up autocommand to close help on any key press
  local close_help = function()
    vim.api.nvim_win_set_buf(win.win, original_buf)
    vim.api.nvim_buf_delete(help_buf, { force = true })
  end

  -- Set up keymaps for help buffer
  local opts = { buffer = help_buf, nowait = true }
  for _, key in ipairs({ "q", "<Esc>", "?", "<CR>", "<Space>" }) do
    vim.keymap.set("n", key, close_help, opts)
  end

  -- Also close on any other key
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = help_buf,
    once = true,
    callback = close_help,
  })
end

-- Setup function for configuration
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
