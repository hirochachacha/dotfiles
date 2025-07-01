return {
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   -- priority = 1000,
  --   opts = {
  --     transparent_background = true,
  --   },
  -- },
  -- {
  --   "folke/tokyonight.nvim",
  --   -- lazy = false,
  --   -- priority = 1000,
  --   opts = {
  --     -- transparent_background = true,
  --   },
  -- },
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      vim.o.background = "dark"
      require("solarized").setup(opts)
      vim.cmd.colorscheme("solarized")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight-strom",
    },
  },
}
