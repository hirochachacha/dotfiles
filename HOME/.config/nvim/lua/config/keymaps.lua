-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- emacs like key bindings
vim.keymap.set("i", "<C-f>", "<Right>", { silent = true })
vim.keymap.set("i", "<C-b>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-a>", "<HOME>", { silent = true })
vim.keymap.set("i", "<C-e>", "<END>", { silent = true })

-- vimperator like key bindings
vim.keymap.set("n", "<Space>q", ":q!<CR>", { silent = true })
vim.keymap.set("n", "<Space>d", function()
  local win_count = #vim.api.nvim_list_wins()

  if win_count > 1 then
    vim.cmd("close")
    return
  end

  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs == 1 then
    vim.cmd("q!")
    return
  end

  local cur = vim.api.nvim_get_current_buf()
  for i, b in ipairs(bufs) do
    if b.bufnr == cur then
      local target = bufs[i + 1] or bufs[i - 1]
      if target then
        vim.api.nvim_set_current_buf(target.bufnr)
      end
      break
    end
  end

  vim.cmd("bd! " .. cur)
end, { desc = "Smart buffer close (or quit)" })
vim.keymap.set("n", "<Space>e", ":Explore<CR>", { silent = true })
vim.keymap.set("n", "<Space>r", ":edit!<CR>", { silent = true })
vim.keymap.set("n", "<Space>l", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<Space>h", ":bprev<CR>", { silent = true })
vim.keymap.set("n", "<Space>y", '"+y', { silent = true })
vim.keymap.set("n", "<Space>p", '"+p', { silent = true })
vim.keymap.set("v", "<Space>y", '"+y', { silent = true })
vim.keymap.set("v", "<Space>p", '"+p', { silent = true })
vim.keymap.set("n", "<Space>t", "<Space>ft", { remap = true, silent = true })
vim.keymap.set("n", "<Space>gg", ":Neogit <CR>", { silent = true })
vim.keymap.set("n", "<Space>gG", ":Neogit cwd=%:p:h<CR>", { silent = true })

local function git_commit(commit_message)
  return require("snacks").scratch({
    name = "commit-message",
    ft = "gitcommit",
    autowrite = false,
    win = {
      keys = {
        ["commit"] = {
          "<cr>",
          function(self)
            local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
            local message_lines = {}

            for _, line in ipairs(lines) do
              if not line:match("^#") then
                table.insert(message_lines, line)
              end
            end

            local final_message = vim.trim(table.concat(message_lines, "\n"))

            if final_message ~= "" then
              vim.fn.system("git commit -m " .. vim.fn.shellescape(final_message))
              vim.notify("Committed: " .. lines[1], vim.log.levels.INFO)
              self:close()
            end
          end,
          desc = "commit",
          mode = { "n", "x" },
        },
      },
    },
    template = commit_message .. "\n\n# Edit your commit message above\n# Lines starting with # are ignored",
  })
end

local function git_commit_with_ai()
  vim.notify("Generating AI commit message...", vim.log.levels.INFO)

  local commit_message = nil
  local done = false

  local prompt = "Generate conventional commit message based on the context given."

  require("CopilotChat").ask(prompt, {
    headless = true,
    context = "#git:staged",
    callback = function(response, source)
      commit_message = response
      done = true

      return response
    end,
  })

  vim.wait(10000, function()
    return done
  end)

  if commit_message then
    git_commit(commit_message)
  else
    vim.notify("Failed to generate AI commit message", vim.log.levels.ERROR)
  end
end

vim.keymap.set("n", "<Space>gcc", function()
  git_commit("")
end, { desc = "git commit" })

vim.keymap.set("n", "<Space>gca", function()
  git_commit_with_ai()
end, { desc = "git commit with Copilot" })

-- quickfix
vim.keymap.set("n", "<C-n>", "]e", { remap = true, silent = true })
vim.keymap.set("n", "<C-p>", "[e", { remap = true, silent = true })

vim.cmd("command! Cnext try | cnext | catch | cfirst | catch | endtry")
vim.cmd("command! Cprev try | cprev | catch | clast | catch | endtry")

-- split and focus window
vim.keymap.set("n", "<C-w>v", "<C-w>v<C-w>l", { silent = true })
vim.keymap.set("n", "<C-w>s", "<C-w>s<C-w>j", { silent = true })

-- commenting
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, silent = true })

-- additional keymaps for LSP
vim.keymap.set("n", "ge", vim.lsp.buf.rename)
