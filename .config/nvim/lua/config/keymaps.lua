-- Save without formatting
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", function()
  require("config.save").without_format()
end, { desc = "Save without formatting" })

-- Sort line ascending
vim.keymap.set("x", "<F9>", ":sort<CR>", { desc = "Sort lines ascending" })

-- Motion and selection
local motions = {
  ["<M-Left>"] = { "<C-Left>", "Word left" },
  ["<M-S-Left>"] = { "<C-S-Left>", "Select word left" },
  ["<D-Left>"] = { "<Home>", "Line start" },
  ["<D-Right>"] = { "<End>", "Line end" },
  ["<D-S-Left>"] = { "<S-Home>", "Select to line start" },
  ["<D-S-Right>"] = { "<S-End>", "Select to line end" },
  ["<D-Up>"] = { "<C-Home>", "File start" },
  ["<D-Down>"] = { "<C-End>", "File end" },
  ["<D-S-Up>"] = { "<C-S-Home>", "Select to file start" },
  ["<D-S-Down>"] = { "<C-S-End>", "Select to file end" },
}

for lhs, rhs in pairs(motions) do
  vim.keymap.set({ "i", "s", "v", "n" }, lhs, rhs[1], { desc = rhs[2] })
end

local word_end = "<Cmd>call search('\\>', 'cW')<CR>"
vim.keymap.set({ "i", "s", "v", "n" }, "<M-Right>", "<Right>" .. word_end, { desc = "Word right" })
vim.keymap.set({ "i", "s", "n" }, "<M-S-Right>", "<S-Right>" .. word_end .. "<C-g>", { desc = "Select word right" })
vim.keymap.set("v", "<M-S-Right>", "<S-Right>" .. word_end, { desc = "Select word right" })

-- Move lines
vim.keymap.set({ "n", "i", "v" }, "<M-Up>", "<A-k>", { remap = true, desc = "Move Up" })
vim.keymap.set({ "n", "i", "v" }, "<M-Down>", "<A-j>", { remap = true, desc = "Move Down" })

-- Copy lines
local function copy_lines(address)
  return function()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    vim.cmd("copy " .. address)
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col })
  end
end

vim.keymap.set({ "n", "i" }, "<M-S-Up>", copy_lines(".-1"), { desc = "Copy Up" })
vim.keymap.set({ "n", "i" }, "<M-S-Down>", copy_lines("."), { desc = "Copy Down" })
vim.keymap.set("v", "<M-S-Up>", ":copy '<-1<CR>gv", { desc = "Copy Up" })
vim.keymap.set("v", "<M-S-Down>", ":copy '><CR>gv", { desc = "Copy Down" })
