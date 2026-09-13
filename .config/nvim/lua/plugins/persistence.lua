return {
  "folke/persistence.nvim",
  init = function()
    local group = vim.api.nvim_create_augroup("restore_session", { clear = true })
    local from_stdin = false

    vim.api.nvim_create_autocmd("StdinReadPre", {
      group = group,
      callback = function()
        from_stdin = true
      end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true,
      callback = function()
        if from_stdin or vim.fn.argc() > 0 then
          return
        end
        require("persistence").load()
      end,
    })
  end,
}
