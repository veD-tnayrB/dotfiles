vim.opt.clipboard = "unnamedplus"
vim.opt.relativenumber = true
vim.keymap.set("n", "<C-b>", "<C-u>");

-- 1. Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Install Gruvbox with lazy.nvim
require("lazy").setup({
  { "ellisonleao/gruvbox.nvim", priority = 1000 }
})

-- 3. Set Gruvbox as the colorscheme
vim.o.background = "dark"
vim.cmd("colorscheme gruvbox")

