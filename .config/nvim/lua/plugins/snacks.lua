local quick_open = { layout = { preset = "vscode" } }

local git_kinds = {
  A = "Added",
  C = "Copied",
  D = "Deleted",
  M = "Modified",
  R = "Renamed",
  T = "Modified",
  ["?"] = "Untracked",
  ["!"] = "Ignored",
}

local function git_status_hl(xy)
  if require("snacks.picker.source.git").git_status(xy).unmerged then
    return "SnacksPickerGitStatusUnmerged"
  end
  local kind = git_kinds[xy:sub(2, 2)] or git_kinds[xy:sub(1, 1)]
  return kind and "SnacksPickerGitStatus" .. kind or "SnacksPickerGitStatus"
end

local function file_colored_like_vscode(item, picker)
  if item.status then
    item.filename_hl = git_status_hl(item.status)
  end
  return Snacks.picker.format.file(item, picker)
end

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      sections = {
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    notifier = { top_down = false },
    picker = {
      icons = {
        git = {
          staged = "",
          added = "",
          deleted = "",
          ignored = "",
          modified = "",
          renamed = "",
          unmerged = "",
        },
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          exclude = { ".DS_Store", ".localized" },
          format = file_colored_like_vscode,
          formatters = { file = { git_status_hl = false } },
          layout = { preset = "sidebar", preview = false, auto_hide = { "input" } },
          win = {
            list = {
              keys = { ["<C-\\>"] = "explorer_close_all" },
            },
          },
        },
        files = quick_open,
        buffers = quick_open,
        recent = quick_open,
        smart = quick_open,
        projects = quick_open,
      },
    },
  },
}
