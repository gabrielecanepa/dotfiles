return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_a = { { "mode", separator = { left = "" } } }
    opts.sections.lualine_y = { { "progress", padding = { left = 1, right = 1 } } }
    opts.sections.lualine_z = { { "location", separator = { right = "" } } }
  end,
}
