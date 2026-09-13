return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft.markdown = { "oxfmt" }
    for _, formatters in pairs(opts.formatters_by_ft) do
      if vim.tbl_contains(formatters, "biome-check") and vim.tbl_contains(formatters, "oxfmt") then
        formatters.stop_after_first = true
      end
    end
  end,
}
