local preferences = {
  importModuleSpecifier = "non-relative",
  importModuleSpecifierEnding = "minimal",
  includePackageJsonAutoImports = "on",
}

return {
  "neovim/nvim-lspconfig",
  opts = {
    diagnostics = { virtual_text = false },
    inlay_hints = { enabled = false },
    servers = {
      vtsls = {
        settings = {
          typescript = { preferences = preferences },
          javascript = { preferences = preferences },
        },
      },
    },
  },
}
