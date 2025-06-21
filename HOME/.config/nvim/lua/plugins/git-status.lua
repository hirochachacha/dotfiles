return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gs",
        function()
          require("git-status-lib").open()
        end,
        desc = "Git Status (tig-like)",
      },
    },
    config = function()
      -- Create user command
      vim.api.nvim_create_user_command("GitStatus", function()
        require("git-status-lib").open()
      end, {})
    end,
  },
}