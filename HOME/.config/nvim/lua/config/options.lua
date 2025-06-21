-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = {
  "ucs-bom",
  "utf-8",
  "euc-jp",
  "cp932",
  "iso-2022-jp",
  "sjis",
}
vim.opt.encoding = "utf-8"

vim.opt.clipboard = ""

-- Buffer tab-like behavior
vim.opt.hidden = true -- Allow switching buffers without saving
vim.opt.confirm = true -- Ask for confirmation before discarding changes
vim.opt.autowrite = false -- Don't auto-save when switching buffers (like tabs)
vim.opt.swapfile = false -- Disable swap files for cleaner tab-like experience
