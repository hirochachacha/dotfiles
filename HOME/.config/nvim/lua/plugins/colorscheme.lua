return {
  "altercation/vim-colors-solarized",
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "solarized",
    },
  },
  -- add fake package to ensure that highlight command works after setting colorscheme
  {
    "ellisonleao/gruvbox.nvim",
    config = function()
      vim.cmd([[highlight Normal ctermbg=none guibg=none]])
    end,
  },
}
