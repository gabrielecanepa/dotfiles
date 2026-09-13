local palette = require("config.palette")

local function groups(p)
  local rainbow = {}
  for i, color in ipairs(p.brackets) do
    rainbow["RainbowDelimiter" .. i] = { fg = color } -- editorBracketHighlight.foreground1-6
  end

  return vim.tbl_extend("error", rainbow, {
    StatusLine = { fg = p.text, bg = p.canvas },
    StatusLineNC = { fg = p.muted, bg = p.canvas },
    TabLine = { fg = p.muted, bg = p.canvas },
    TabLineFill = { bg = p.canvas },
    TabLineSel = { fg = p.text, bg = p.tab_accent },
    WinBar = { fg = p.muted, bg = p.canvas },
    WinBarNC = { fg = p.muted, bg = p.canvas },
    WinSeparator = { fg = p.border },
    NormalFloat = { fg = p.text, bg = p.widget },
    FloatBorder = { fg = p.border, bg = p.widget },
    FloatTitle = { fg = p.text, bg = p.widget },
    Pmenu = { fg = p.text, bg = p.widget },
    PmenuSel = { bg = p.list_active },
    PmenuSbar = { bg = p.widget },
    PmenuThumb = { bg = p.scrollbar },
    CursorLine = { bg = p.line_highlight },
    CursorLineNr = { fg = p.text },
    LineNr = { fg = p.line_number },
    Visual = { bg = p.selection },
    Search = { bg = p.find_highlight },
    IncSearch = { fg = p.text, bg = p.find_match },
    CurSearch = { link = "IncSearch" },
    MatchParen = { bg = p.bracket_match },
    Whitespace = { fg = p.whitespace },
    NonText = { fg = p.whitespace },
    LspReferenceText = { bg = p.word_highlight },
    LspReferenceRead = { bg = p.word_highlight },
    LspReferenceWrite = { bg = p.word_highlight },
    Comment = { fg = p.comment },
    Function = { fg = p.func },
    ["@function.call"] = { fg = p.func },
    ["@function.method"] = { fg = p.func },
    ["@function.method.call"] = { fg = p.func },
    GitSignsAdd = { fg = p.gutter_added },
    GitSignsChange = { fg = p.gutter_modified },
    GitSignsDelete = { fg = p.gutter_deleted },
    GitSignsAddInline = { bg = p.diff_add_text },
    GitSignsChangeInline = { bg = p.diff_add_text },
    GitSignsDeleteInline = { bg = p.diff_del_text },
    GitSignsCurrentLineBlame = { fg = p.blame },
    DiffAdd = { bg = p.diff_add_line },
    DiffDelete = { fg = p.whitespace, bg = p.diff_del_line },
    DiffText = { bg = p.diff_add_text },
    DiffChange = { bg = p.diff_add_line },
    DiffviewDiffChangeAsDelete = { bg = p.diff_del_line },
    DiffviewDiffTextAsDelete = { bg = p.diff_del_text },
    SnacksIndent = { fg = p.indent_guide },
    SnacksIndentScope = { fg = p.indent_active },
    SnacksIndentChunk = { fg = p.indent_active },
    SnacksPickerList = { fg = p.text, bg = p.canvas },
    SnacksPickerBorder = { fg = p.border },
    SnacksPickerTitle = { fg = p.text },
    SnacksPickerListCursorLine = { bg = p.list_active },
    SnacksPickerTree = { fg = p.guide },
    SnacksPickerDir = { fg = p.muted },
    SnacksPickerFile = { fg = p.text },
    SnacksPickerDirectory = { fg = p.text },
    SnacksPickerPathHidden = { fg = p.text },
    SnacksPickerPathIgnored = { fg = p.git_ignored },
    SnacksPickerGitStatus = { fg = p.muted },
    SnacksPickerGitStatusAdded = { fg = p.git_added },
    SnacksPickerGitStatusStaged = { fg = p.git_added },
    SnacksPickerGitStatusUntracked = { fg = p.git_added },
    SnacksPickerGitStatusModified = { fg = p.git_modified },
    SnacksPickerGitStatusRenamed = { fg = p.git_modified },
    SnacksPickerGitStatusCopied = { fg = p.git_modified },
    SnacksPickerGitStatusDeleted = { fg = p.git_deleted },
    SnacksPickerGitStatusIgnored = { fg = p.git_ignored },
    SnacksPickerGitStatusUnmerged = { fg = p.git_conflict },
  })
end

local function apply()
  vim.cmd.colorscheme(palette.colorschemes[vim.o.background] or palette.colorschemes.dark)
  vim.cmd.redrawstatus({ bang = true })
end

return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    main = "github-theme",
    opts = {
      options = {
        terminal_colors = false, -- `:terminal` keeps Ghostty's palette
        darken = { floats = false, sidebars = { enable = false } },
      },
      palettes = {
        github_light = { canvas = { default = palette.github_light.canvas } },
        github_dark_default = { canvas = { default = palette.github_dark_default.canvas } },
      },
      groups = {
        github_light = groups(palette.github_light),
        github_dark_default = groups(palette.github_dark_default),
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local group = vim.api.nvim_create_augroup("ghostty_colorscheme", { clear = true })
        local loaded

        vim.api.nvim_create_autocmd("ColorScheme", {
          group = group,
          callback = function(args)
            loaded = args.match
          end,
        })

        vim.api.nvim_create_autocmd("OptionSet", {
          group = group,
          pattern = "background",
          callback = function()
            if loaded == palette.colorschemes.light or loaded == palette.colorschemes.dark then
              vim.schedule(apply)
            end
          end,
        })

        apply()
      end,
    },
  },
}
