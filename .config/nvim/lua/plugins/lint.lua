local function selene_config(source)
  local root = vim.fs.root(source, "selene.toml")
  return root and root .. "/selene.toml"
end

return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = { lua = { "selene" }, markdown = {} },
    linters = {
      selene = {
        condition = function(ctx)
          return selene_config(ctx.filename) ~= nil
        end,
        args = {
          "--config",
          function()
            return selene_config(0)
          end,
          "--display-style",
          "json",
          "-",
        },
      },
    },
  },
}
