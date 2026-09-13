local M = {}

local function channel(hex, i)
  return tonumber(hex:sub(i, i + 1), 16)
end

local function blend(fg, alpha, bg)
  local out = {}
  for _, i in ipairs({ 2, 4, 6 }) do
    out[#out + 1] = math.floor(channel(bg, i) + (channel(fg, i) - channel(bg, i)) * alpha + 0.5)
  end
  return string.format("#%02x%02x%02x", out[1], out[2], out[3])
end

local function resolve(theme)
  local palette = {}
  for key, value in pairs(theme) do
    if type(value) == "table" and value.alpha then
      palette[key] = blend(value[1], value.alpha, value.over == "widget" and theme.widget or theme.canvas)
    else
      palette[key] = value
    end
  end
  return palette
end

M.github_light = resolve({
  canvas = "#fafafa",
  text = "#1f2328",
  muted = "#656d76",
  line_number = "#8c959f",
  border = "#d0d7de",
  guide = "#d8dee4",
  widget = "#ffffff",
  accent = "#0969da",
  status_bg = "#0969da",
  status_fg = "#ffffff",
  tab_accent = "#159739",
  blame = "#b1b1b1",
  selection = "#add6ff",
  find_match = "#bf8700",
  whitespace = "#afb8c1",
  comment = "#6e7781",
  func = "#8250df",
  success = "#1f883d",
  done = "#8250df",
  danger = "#cf222e",
  attention = "#9a6700",
  git_added = "#1a7f37",
  git_modified = "#9a6700",
  git_deleted = "#cf222e",
  git_ignored = "#6e7781",
  git_conflict = "#bc4c00",
  brackets = { "#0969da", "#1a7f37", "#9a6700", "#cf222e", "#bf3989", "#8250df" },
  line_highlight = { "#eaeef2", alpha = 0.5 },
  word_highlight = { "#eaeef2", alpha = 0.5 },
  find_highlight = { "#fae17d", alpha = 0.5 },
  bracket_match = { "#4ac26b", alpha = 0.25 },
  indent_guide = { "#1f2328", alpha = 0.12 },
  indent_active = { "#1f2328", alpha = 0.24 },
  list_active = { "#afb8c1", alpha = 0.2, over = "widget" },
  scrollbar = { "#8c959f", alpha = 0.2, over = "widget" },
  gutter_added = { "#4ac26b", alpha = 0.4 },
  gutter_modified = { "#d4a72c", alpha = 0.4 },
  gutter_deleted = { "#ff8182", alpha = 0.4 },
  diff_add_line = { "#aceebb", alpha = 0.3 },
  diff_del_line = { "#ffcecb", alpha = 0.3 },
  diff_add_text = { "#6fdd8b", alpha = 0.5 },
  diff_del_text = { "#ff8182", alpha = 0.4 },
})

M.github_dark_default = resolve({
  canvas = "#171b23",
  text = "#e6edf3",
  muted = "#7d8590",
  line_number = "#6e7681",
  border = "#30363d",
  guide = "#21262d",
  widget = "#161b22",
  accent = "#2f81f7",
  status_bg = "#090c10",
  status_fg = "#ffffff",
  tab_accent = "#2f81f7",
  blame = "#4f545f",
  selection = "#264f78",
  find_match = "#9e6a03",
  whitespace = "#484f58",
  comment = "#8b949e",
  func = "#d2a8ff",
  success = "#238636",
  done = "#8957e5",
  danger = "#da3633",
  attention = "#9e6a03",
  git_added = "#3fb950",
  git_modified = "#d29922",
  git_deleted = "#f85149",
  git_ignored = "#6e7681",
  git_conflict = "#db6d28",
  brackets = { "#79c0ff", "#56d364", "#e3b341", "#ffa198", "#ff9bce", "#d2a8ff" },
  line_highlight = { "#6e7681", alpha = 0.1 },
  word_highlight = { "#6e7681", alpha = 0.5 },
  find_highlight = { "#f2cc60", alpha = 0.5 },
  bracket_match = { "#3fb950", alpha = 0.25 },
  indent_guide = { "#e6edf3", alpha = 0.12 },
  indent_active = { "#e6edf3", alpha = 0.24 },
  list_active = { "#6e7681", alpha = 0.4, over = "widget" },
  scrollbar = { "#8b949e", alpha = 0.2, over = "widget" },
  gutter_added = { "#2ea043", alpha = 0.4 },
  gutter_modified = { "#bb8009", alpha = 0.4 },
  gutter_deleted = { "#f85149", alpha = 0.4 },
  diff_add_line = { "#238636", alpha = 0.15 },
  diff_del_line = { "#da3633", alpha = 0.15 },
  diff_add_text = { "#3fb950", alpha = 0.3 },
  diff_del_text = { "#ff7b72", alpha = 0.3 },
})

M.colorschemes = { light = "github_light", dark = "github_dark_default" }

function M.lualine(name)
  local p = M[name]
  local function mode(bg)
    return { a = { fg = p.status_fg, bg = bg }, b = { fg = p.text, bg = p.canvas }, c = { fg = p.muted, bg = p.canvas } }
  end
  return {
    normal = mode(p.status_bg),
    insert = mode(p.success),
    visual = mode(p.done),
    replace = mode(p.danger),
    command = mode(p.attention),
    terminal = mode(p.accent),
    inactive = {
      a = { fg = p.muted, bg = p.canvas },
      b = { fg = p.muted, bg = p.canvas },
      c = { fg = p.muted, bg = p.canvas },
    },
  }
end

return M
