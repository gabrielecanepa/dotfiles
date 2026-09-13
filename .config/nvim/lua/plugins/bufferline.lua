return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    local preset = require("bufferline").style_preset
    local separator = { fg = { highlight = "WinSeparator", attribute = "fg" } }
    local inactive = { fg = { highlight = "TabLine", attribute = "fg" } }
    local active = { fg = { highlight = "Normal", attribute = "fg" } }

    for _, offset in ipairs(opts.options.offsets or {}) do
      if offset.filetype == "snacks_layout_box" then
        offset.highlight = "SnacksPickerList"
      end
    end

    opts.options.always_show_bufferline = true
    opts.options.indicator = { style = "underline" }
    opts.options.separator_style = "thin"
    opts.options.style_preset = { preset.minimal, preset.no_italic, preset.no_bold }
    opts.highlights = {
      separator = separator,
      separator_visible = separator,
      separator_selected = separator,
      background = inactive,
      buffer_visible = inactive,
      modified = inactive,
      modified_visible = inactive,
      modified_selected = active,
      close_button = inactive,
      close_button_visible = inactive,
      close_button_selected = active,
    }
  end,
}
