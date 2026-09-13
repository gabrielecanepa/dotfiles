local function color_left_side_as_removed(_, winid, ctx)
  if ctx.symbol ~= "a" then
    return
  end
  local winhl = vim.tbl_filter(function(entry)
    return not entry:match("^DiffChange:") and not entry:match("^DiffText:")
  end, vim.split(vim.wo[winid].winhl, ",", { trimempty = true }))
  vim.list_extend(winhl, { "DiffChange:DiffviewDiffChangeAsDelete", "DiffText:DiffviewDiffTextAsDelete" })
  vim.wo[winid].winhl = table.concat(winhl, ",")
end

local function toggle_changes()
  vim.cmd(require("diffview.lib").get_current_view() and "DiffviewClose" or "DiffviewOpen")
end

local close = { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } }

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gv", toggle_changes, desc = "Toggle Changes (diffview)" },
    { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (diffview)" },
  },
  opts = {
    enhanced_diff_hl = true,
    file_panel = { listing_style = "list" },
    hooks = { diff_buf_win_enter = color_left_side_as_removed },
    keymaps = {
      view = { close },
      file_panel = { close },
      file_history_panel = { close },
    },
  },
}
