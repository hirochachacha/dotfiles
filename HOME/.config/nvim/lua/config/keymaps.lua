-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- emacs like key bindings
vim.keymap.set("i", "<C-f>", "<Right>", { silent = true })
vim.keymap.set("i", "<C-b>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-a>", "<HOME>", { silent = true })
vim.keymap.set("i", "<C-e>", "<END>", { silent = true })

-- vimperator like key bindings
vim.keymap.set("n", "<Space>d", ":q!<CR>", { silent = true })
vim.keymap.set("n", "<Space>o", ":Explore<CR>", { silent = true })
vim.keymap.set("n", "<Space>t", ":Texplore<CR>", { silent = true })
vim.keymap.set("n", "<Space>r", ":edit!<CR>", { silent = true })
vim.keymap.set("n", "<Space>l", "gt", { silent = true })
vim.keymap.set("n", "<Space>h", "gT", { silent = true })
vim.keymap.set("n", "<Space>y", '"+y', { silent = true })
vim.keymap.set("n", "<Space>p", '"+p', { silent = true })
vim.keymap.set("v", "<Space>y", '"+y', { silent = true })
vim.keymap.set("v", "<Space>p", '"+p', { silent = true })
vim.keymap.set("n", "<C-l>", ":tabmove+1<CR>", { silent = true })
vim.keymap.set("n", "<C-h>", ":tabmove-1<CR>", { silent = true })

-- quickfix
vim.keymap.set("n", "<C-j>", ":Cnext<CR>", { silent = true })
vim.keymap.set("n", "<C-k>", ":Cprev<CR>", { silent = true })
vim.keymap.set("n", "<C-c>", ":cclose<CR>", { silent = true })

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
