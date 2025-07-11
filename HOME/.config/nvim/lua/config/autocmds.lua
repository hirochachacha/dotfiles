-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Handle deno:/* URLs

vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "deno:/*",
  callback = function(ev)
    local bufnr = ev.buf
    local uri = vim.api.nvim_buf_get_name(bufnr)
    local client = vim.lsp.get_active_clients({ name = "denols" })[1]

    if client then
      client.request("deno/virtualTextDocument", { textDocument = { uri = uri } }, function(err, result)
        if not err and result then
          local lines = vim.split(result, "\n")
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.api.nvim_set_option_value("filetype", "typescript", { buf = bufnr })
          vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
          vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
          vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
        end
      end)
    end
  end,
})
