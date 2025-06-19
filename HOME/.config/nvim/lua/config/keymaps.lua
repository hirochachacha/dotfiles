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
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs == 1 then
    return vim.cmd("q!")
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
