vim.opt.clipboard = "unnamedplus"
vim.opt.relativenumber = true
vim.keymap.set("n", "<C-u>", "<C-u>zz");
vim.keymap.set("n", "<C-d>", "<C-d>zz");
vim.g.mapleader = " "  -- sets leader to space

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

{
  "nvim-telescope/telescope-file-browser.nvim",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").load_extension("file_browser")
  end,
},
{"owickstrom/vim-colors-paramount"},
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
 {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP source for cmp
      "hrsh7th/cmp-buffer",    -- Buffer completions
      "hrsh7th/cmp-path",      -- Path completions
      "L3MON4D3/LuaSnip",      -- Snippet engine
      "saadparwaiz1/cmp_luasnip", -- Snippet completions
      "rafamadriz/friendly-snippets", -- Snippet collection
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          -- ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-e>"] = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(client, bufnr)
        local bufmap = function(mode, lhs, rhs)
          local opts = { noremap=true, silent=true, buffer=bufnr }
          vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- Keymaps for LSP features:
        bufmap("n", "gd", vim.lsp.buf.definition)       -- Go to definition
        bufmap("n", "K", vim.lsp.buf.hover)             -- Hover docs
        bufmap("n", "gr", vim.lsp.buf.references)       -- References
        bufmap("n", "<leader>e", vim.diagnostic.open_float) -- Show error under cursor
        bufmap("n", "[d", vim.diagnostic.goto_prev)     -- Previous diagnostic
        bufmap("n", "]d", vim.diagnostic.goto_next)     -- Next diagnostic
        bufmap("n", "<leader>q", vim.diagnostic.setloclist) -- Set location list with diagnostics
      end

      -- Setup your LSP servers with capabilities and on_attach
      lspconfig.gopls.setup({ on_attach = on_attach, capabilities = capabilities })
      lspconfig.ts_ls.setup({ on_attach = on_attach, capabilities = capabilities })
      lspconfig.html.setup({ on_attach = on_attach, capabilities = capabilities })
      lspconfig.emmet_ls.setup({ on_attach = on_attach, capabilities = capabilities })
    end,
  },
 {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<esc>"] = actions.close,
            },
          },
          -- layout_strategy = "horizontal",
          layout_config = {
            -- preview_width = 0.6,
	   width = 0.8,       -- optional: controls overall width
	      height = 0.8,      -- optional: controls overall height
          },
          path_display = { "truncate" },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
          },
        },
        extensions = {
          file_browser = {
            theme = "dropdown",
            hijack_netrw = true,
            mappings = {
              ["i"] = {
                -- Insert mode mappings can be added here if needed
              },
              ["n"] = {
                ["<C-n>"] = require("telescope._extensions.file_browser.actions").create,
                ["<C-,>"] = function(prompt_bufnr)
                  local fb_actions = require("telescope._extensions.file_browser.actions")
                  -- Custom function to create folder
                  local function create_folder()
                    vim.ui.input({ prompt = "New folder name: " }, function(input)
                      if not input or input == "" then return end
                      local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
                      local current_path = current_picker.cwd
                      local new_folder_path = current_path .. "/" .. input
                      vim.fn.mkdir(new_folder_path, "p")
                      -- Refresh telescope file browser
                      fb_actions.refresh(prompt_bufnr)
                    end)
                  end
                  create_folder()
                end,
              },
            },
          },
        },
      })

      telescope.load_extension("file_browser")
    end,
  },

  -- Optional: telescope-fzf-native for better sorting (requires make)
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = vim.fn.executable("make") == 1,
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },

  {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({
      view = {
        side = "right",        -- open tree on the right side
        width = 30,
        preserve_window_proportions = true,
      },
      update_focused_file = {
        enable = true,          -- focus tree on current file
        update_cwd = true,
      },
      renderer = {
        highlight_git = true,
        root_folder_modifier = ":~",
      },
      actions = {
        open_file = {
          quit_on_open = false, -- keep tree open when opening files
        },
      },
    })

    -- Keymaps inside nvim-tree buffer
    local api = require("nvim-tree.api")
    vim.keymap.set("n", "<C-Space>", api.tree.collapse_all, { buffer = true, desc = "Collapse all folders in nvim-tree" })
  end,

-- New keymap: Ctrl+n to create a new file/folder
  vim.keymap.set("n", "<C-n>", function()
    -- Get the current node under cursor in nvim-tree
    local node = api.tree.get_node_under_cursor()
    if not node then
      print("No node under cursor")
      return
    end

    -- Determine the directory to create the file in
    local dir_path
    if node.nodes then
      -- It's a directory
      dir_path = node.absolute_path
    else
      -- It's a file, so use its parent directory
      dir_path = vim.fn.fnamemodify(node.absolute_path, ":h")
    end

    -- Prompt user for file/folder name
    vim.ui.input({ prompt = "New file/folder name (end with / for folder): " }, function(input)
      if input == nil or input == "" then
        print("Cancelled")
        return
      end

      -- Construct full path
      local new_path = dir_path .. "/" .. input

      -- Use nvim-tree API to create the file/folder
      api.fs.create(new_path)

      -- Refresh the tree to show the new file/folder
      api.tree.reload()

      -- Optionally, find and focus the new file in the tree
      api.tree.find_file(new_path)
    end)
  end, { buffer = true, desc = "Create new file/folder in nvim-tree" })
},
  }


  )

-- 3. Set Gruvbox as the colorscheme
vim.o.background = "dark"
-- vim.cmd("colorscheme gruvbox")
-- vim.cmd.colorscheme "kanso"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Find files in current project (Ctrl+p)
map("n", "<C-p>", function()
  require("telescope.builtin").find_files({ previewer = true })
end, opts)

-- Find words in current file (Ctrl+f)
map("n", "<C-f>", function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end, opts)

-- Open last closed file (Ctrl+Shift+t)
map("n", "<C-S-t>", function()
  require("telescope.builtin").oldfiles()
end, opts)

-- Close current buffer (Ctrl+w)
map("n", "<C-w>", "<cmd>bdelete<CR>", opts)

-- Open file browser/tree on the right side (leader + e for example)
map("n", "<leader>e", function()
  require("telescope").extensions.file_browser.file_browser({
    path = "%:p:h",
    cwd = vim.loop.cwd(),
    respect_gitignore = false,
    hidden = true,
    grouped = true,
    previewer = true,
    layout_config = { width = 0.4, height = 0.8, prompt_position = "top" },
  })
end, opts)

local api = require("nvim-tree.api")
local opts = { noremap = true, silent = true }

-- Toggle nvim-tree with Ctrl+o
vim.keymap.set("n", "<C-o>", ':NvimTreeToggle<CR>', {noremap = true, silent = true})

-- format on save golang
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    vim.lsp.buf.format({ async = false })
    vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
  end,
})
