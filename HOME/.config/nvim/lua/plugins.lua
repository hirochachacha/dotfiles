vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'altercation/vim-colors-solarized'
  use 'itchyny/lightline.vim'

  use 'thesis/vim-solidity'

  -- use 'rstacruz/vim-closer'
  use 'tpope/vim-surround'
  use 'tpope/vim-abolish'

  use 'scrooloose/nerdcommenter'

  -- use {'neoclide/coc.nvim', branch = 'release'}
  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  }

  use {
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/vim-vsnip',
    'hrsh7th/cmp-vsnip',
    'onsails/lspkind.nvim',
  }

  use 'stevearc/conform.nvim'

  -- use 'lukas-reineke/lsp-format.nvim'

  use 'mattn/vim-goaddtags'

  use 'mattn/emmet-vim'

  use 'github/copilot.vim'

  -- use 'lbrayner/vim-rzip'


  -- use 'nvim-treesitter/nvim-treesitter'
  -- use 'RRethy/nvim-treesitter-endwise'

  -- use {
  -- 	"windwp/nvim-autopairs",
  --     config = function() require("nvim-autopairs").setup {} end
  -- }
end)
