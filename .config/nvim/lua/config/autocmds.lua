local autosave = vim.api.nvim_create_augroup("autosave", { clear = true })
local timers = {}

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "TextChangedI", "TextChangedP" }, {
  group = autosave,
  callback = function(args)
    local buf = args.buf
    if timers[buf] then
      vim.fn.timer_stop(timers[buf])
    end
    timers[buf] = vim.fn.timer_start(1000, function()
      timers[buf] = nil
      if
        vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].modified
        and vim.bo[buf].modifiable
        and vim.bo[buf].buftype == ""
        and vim.api.nvim_buf_get_name(buf) ~= ""
      then
        require("config.save").without_format(buf)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = autosave,
  callback = function(args)
    if timers[args.buf] then
      vim.fn.timer_stop(timers[args.buf])
      timers[args.buf] = nil
    end
  end,
})

vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("diagnostic_hover", { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end
    vim.diagnostic.open_float(nil, { scope = "line", focusable = false })
  end,
})
