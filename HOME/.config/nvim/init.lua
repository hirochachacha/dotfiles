require 'plugins'

-- colorscheme
vim.cmd('colorscheme solarized')
vim.cmd('highlight Normal ctermbg=none guibg=none')

-- editor config
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.iminsert = 0
vim.opt.imsearch = 0
vim.opt.tabpagemax = 30
vim.opt.number = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.autowrite = true
vim.opt.swapfile = false
vim.opt.foldenable = false
-- vim.opt.encoding = "utf-8"
vim.opt.fileencodings = "fileencodings=iso-2022-jp,euc-jp,sjis,utf-8"
-- vim.opt.fileformats = "unix,dos,mac"

-- emacs like key bindings
vim.keymap.set('i', '<C-f>', '<Right>', { silent = true })
vim.keymap.set('i', '<C-b>', '<Left>', { silent = true })
vim.keymap.set('i', '<C-a>', '<HOME>', { silent = true })
vim.keymap.set('i', '<C-e>', '<END>', { silent = true })

-- vimperator like key bindings
vim.keymap.set('n', '<Space>d', ':q!<CR>', { silent = true })
vim.keymap.set('n', '<Space>o', ':Explore<CR>', { silent = true })
vim.keymap.set('n', '<Space>t', ':Texplore<CR>', { silent = true })
vim.keymap.set('n', '<Space>r', ':edit!<CR>', { silent = true })
vim.keymap.set('n', '<Space>l', 'gt', { silent = true })
vim.keymap.set('n', '<Space>h', 'gT', { silent = true })
vim.keymap.set('n', '<Space>y', '"+y', { silent = true })
vim.keymap.set('n', '<Space>p', '"+p', { silent = true })
vim.keymap.set('v', '<Space>y', '"+y', { silent = true })
vim.keymap.set('v', '<Space>p', '"+p', { silent = true })
vim.keymap.set('n', '<C-l>', ':tabmove+1<CR>', { silent = true })
vim.keymap.set('n', '<C-h>', ':tabmove-1<CR>', { silent = true })

-- quickfix
vim.keymap.set('n', '<C-j>', ':Cnext<CR>', { silent = true })
vim.keymap.set('n', '<C-k>', ':Cprev<CR>', { silent = true })
vim.keymap.set('n', '<C-c>', ':cclose<CR>', { silent = true })

vim.cmd("command! Cnext try | cnext | catch | cfirst | catch | endtry")
vim.cmd("command! Cprev try | cprev | catch | clast | catch | endtry")

-- split and focus window
vim.keymap.set('n', '<C-w>v', '<C-w>v<C-w>l', { silent = true })
vim.keymap.set('n', '<C-w>s', '<C-w>s<C-w>j', { silent = true })

-- cleanup high light
vim.keymap.set('n', '<ESC><ESC>', ':nohlsearch<CR><ESC>', { silent = true })

vim.keymap.set('i', '"', '""<left>', { silent = true })
vim.keymap.set('i', "'", "''<left>", { silent = true })
vim.keymap.set('i', '(', '()<left>', { silent = true })
vim.keymap.set('i', '[', '[]<left>', { silent = true })
vim.keymap.set('i', '{', '{}<left>', { silent = true })
vim.keymap.set('i', '{<CR>', '{<CR>}<ESC>O', { silent = true })
vim.keymap.set('i', '{;<CR>', '{<CR>};<ESC>O', { silent = true })

-- nerdcommenter
vim.g.NERDCreateDefaultMappings = 0
vim.g.NERDSpaceDelims = 1

vim.g.user_emmet_leader_key = '<C-e>'

vim.keymap.set('n', '<C-/>', '<Plug>NERDCommenterToggle', { silent = true })
vim.keymap.set('v', '<C-/>', '<Plug>NERDCommenterToggle', { silent = true })

-- vim.keymap.set("n", "<C-i>", vim.lsp.buf.definition)
vim.keymap.set("n", ",d", vim.lsp.buf.definition)
vim.keymap.set("n", ",<", vim.lsp.buf.references)
vim.keymap.set("n", ",e", vim.lsp.buf.rename)

vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "g<", vim.lsp.buf.references)
vim.keymap.set("n", "ge", vim.lsp.buf.rename)

require("conform").setup({
  formatters_by_ft = {
    go = { "goimports" },
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
})

-- require("lsp-format").setup {}
--
-- local on_attach = function(client, bufnr)
--   require("lsp-format").on_attach(client)
--
--   vim.keymap.set("n", "<C-i>", vim.lsp.buf.definition)
--   vim.keymap.set("n", ",<", vim.lsp.buf.references)
--   vim.keymap.set("n", ",e", vim.lsp.buf.rename)
-- end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason").setup()
require("mason-lspconfig").setup()
-- require("mason-lspconfig").setup_handlers {
--   function(server_name) -- default handler (optional)
--     require("lspconfig")[server_name].setup {
--       on_attach = on_attach,
--       capabilities = capabilities,
--     }
--   end,
-- }

local lspkind = require 'lspkind'

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    { name = 'vsnip' },
    { name = "buffer" },
    { name = "path" },
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ['<C-l>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
  }),
  experimental = {
    ghost_text = false,
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol',
      maxwidth = 50,
      ellipsis_char = '...',
    })
  }
})

cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "path" },
  },
})
