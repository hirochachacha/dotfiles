-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")


vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "javascript" },
  callback = function()
    local deno_config = vim.fn.findfile("deno.json", ".;") ~= "" or vim.fn.findfile("deno.jsonc", ".;") ~= ""

    if deno_config then
      vim.lsp.start({
        name = "denols",
        cmd = { "deno", "lsp" },
        root_dir = vim.fn.getcwd(),
        init_options = {
          lint = true,
          unstable = true,
          suggest = {
            imports = {
              hosts = {
                ["https://deno.land"] = true,
                ["https://jsr.io"] = true,
                ["https://esm.sh"] = true,
              },
            },
          },
        },
      })
    end
  end,
})
