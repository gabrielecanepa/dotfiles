-- Editor
vim.opt.relativenumber = false
vim.opt.conceallevel = 0
vim.opt.guicursor = {
  "n-v-c-sm:block",
  "i-ci-ve:ver25-blinkwait0-blinkon400-blinkoff250",
  "r-cr-o:hor20",
  "t:hor20-blinkwait0-blinkon400-blinkoff250-TermCursor",
}
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "key"
vim.opt.selection = "exclusive"
vim.g.ai_cmp = false

-- Ghostty
local ghostty_vimfiles = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles"
if vim.uv.fs_stat(ghostty_vimfiles) then
  vim.opt.rtp:append(ghostty_vimfiles)
end

-- File associations
local git_hooks = {
  "applypatch-msg",
  "commit-msg",
  "fsmonitor-watchman",
  "p4-changelist",
  "p4-post-changelist",
  "p4-pre-submit",
  "p4-prepare-changelist",
  "post-applypatch",
  "post-checkout",
  "post-commit",
  "post-index-change",
  "post-merge",
  "post-receive",
  "post-rewrite",
  "post-update",
  "pre-applypatch",
  "pre-auto-gc",
  "pre-commit",
  "pre-merge-commit",
  "pre-push",
  "pre-rebase",
  "pre-receive",
  "prepare-commit-msg",
  "proc-receive",
  "push-to-checkout",
  "reference-transaction",
  "sendemail-validate",
}
local filenames = { ignore = "gitignore", NOTES = "markdown", TODO = "markdown" }
for _, hook in ipairs(git_hooks) do
  filenames[hook] = "sh"
end
vim.filetype.add({
  filename = filenames,
  extension = { todo = "markdown" },
  pattern = {
    [".*%.json%.lock"] = "json",
    [".*/ghostty/config"] = "ghostty",
    [".*/ghostty/themes/[^/]+"] = "ghostty",
  },
})
