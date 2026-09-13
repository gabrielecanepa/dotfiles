local M = {}

function M.without_format(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local autoformat = vim.b[buf].autoformat
  vim.b[buf].autoformat = false
  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("silent update")
  end)
  vim.b[buf].autoformat = autoformat
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

return M
