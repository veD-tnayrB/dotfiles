-- Global Neovim Options
vim.opt.clipboard = "unnamedplus"
vim.opt.relativenumber = true
vim.keymap.set("n", "<C-u>", "<C-u>zz");
vim.keymap.set("n", "<C-d>", "<C-d>zz");
vim.g.mapleader = " ";
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Set highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

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

-- 2. Install Plugins with lazy.nvim
require("lazy").setup({
  -- Colorschemes
    {"eliseshaffer/darklight.nvim"}, -- Plugin for theme switching
  {"xero/miasma.nvim"}, -- ADDED: Miasma colorscheme

  -- File Browser / Tree
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("file_browser")
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          side = "right",
          width = 30,
          preserve_window_proportions = true,
        },
		git = {
		  ignore = false, -- Set to false to show Git-ignored files
		},
	filters= {
		dotfiles = false,
	},
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
        renderer = {
          highlight_git = true,
          root_folder_modifier = ":~",
        },
        actions = {
          open_file = {
            quit_on_open = false,
          },
        },
      })

      -- Keymaps inside nvim-tree buffer
      local api = require("nvim-tree.api")
      vim.keymap.set("n", "<C-Space>", api.tree.collapse_all, { buffer = true, desc = "Collapse all folders in nvim-tree" })
    end,
  },

  -- LSP Core Plugins (Mason, Mason-LSPConfig, LSP-Zero should load early)
  {
    "williamboman/mason.nvim",
    lazy = false, -- Make sure Mason loads immediately
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false, -- Make sure Mason-LSPConfig loads immediately
    dependencies = { "williamboman/mason.nvim" }, -- Ensure Mason is loaded before Mason-LSPConfig
    -- NOTE: We will NOT call mason-lspconfig.setup() here directly.
    -- lsp-zero will call it internally.
  },
  {
    "VonHeikemen/lsp-zero.nvim",
    lazy = false, -- Make sure lsp-zero loads immediately to setup LSP
    dependencies = {
        "neovim/nvim-lspconfig",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp", -- For completion capabilities
        "L3MON4D3/LuaSnip", -- These are also CMP related, group them for clarity
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
    },
    config = function()
        local lsp = require("lsp-zero")

        -- 1. Configure on_attach
        lsp.on_attach(function(client, bufnr)
            local opts = { noremap = true, silent = true, buffer = bufnr }
            local bufmap = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end

            -- Enable completion for the current buffer
            vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

            bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
            bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
            bufmap("n", "gr", vim.lsp.buf.references, "Go to References")
            bufmap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
            bufmap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
            bufmap("n", "gt", vim.lsp.buf.type_definition, "Go to Type Definition")
            bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
            bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
            bufmap("n", "<leader>f", function() vim.lsp.buf.format { async = true } end, "Format Buffer")
            bufmap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
            bufmap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
            bufmap("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, "List Workspace Folders")

            -- Diagnostics keymaps
            bufmap("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
            bufmap("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
            bufmap("n", "<leader>e", vim.diagnostic.open_float, "Open Diagnostics Float")
            bufmap("n", "<leader>q", vim.diagnostic.setloclist, "Set Diagnostics Loclist")

            if client.name == "gopls" then
                -- Specific gopls settings if needed
            end
        end)

        -- 2. Configure LSP servers
        lsp.setup_servers({
            "gopls",
            "ts_ls", -- This is the correct nvim-lspconfig name
            "html",
            "emmet_ls",
            "jsonls",
            "cssls",
            "yamlls",
        })

        -- 3. Configure nvim-cmp
        lsp.setup_nvim_cmp({
            mapping = require("cmp").mapping.preset.insert({
              ["<C-Space>"] = require("cmp").mapping.complete(),
              ["<CR>"] = require("cmp").mapping.confirm({ select = true }),
              ["<C-j>"] = require("cmp").mapping.select_next_item(),
              ["<C-k>"] = require("cmp").mapping.select_prev_item(),
              ["<C-e>"] = require("cmp").mapping.abort(),
            }),
            snippet = {
              expand = function(args)
                require("luasnip").lsp_expand(args.body)
              end,
            },
            sources = require("cmp").config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
            }),
            completion = {
              completeopt = "menu,menuone,noinsert",
            },
            window = {
              documentation = {
                border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
              },
            },
        })

        -- 4. Finally, call lsp.setup() to apply all configurations
        lsp.setup()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp", -- Still needed for cmp-nvim-lsp capabilities
    },
    -- Removed the config function here as lsp-zero is managing lspconfig setup.
  },

  -- The nvim-cmp plugin entry is now purely for dependencies, as lsp-zero sets it up.
  -- You can even remove this entire block if you prefer, as its dependencies are listed under lsp-zero.
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    -- Removed: config = function() ... end,
  },

  -- Formatting and Linting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
        typescript = { "prettierd", "eslint_d" },
        javascript = { "prettierd", "eslint_d" },
        html = { "prettierd" },
        css = { "prettierd" },
        json = { "prettierd" },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
        lua = { "stylua" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },

  -- Telescope
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
          layout_config = {
            width = 0.8,
            height = 0.8,
            prompt_position = "bottom",
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
              ["i"] = {},
              ["n"] = {
                ["<C-n>"] = require("telescope._extensions.file_browser.actions").create,
                ["<C-,>"] = function(prompt_bufnr)
                  local fb_actions = require("telescope._extensions.file_browser.actions")
                  vim.ui.input({ prompt = "New folder name: " }, function(input)
                    if not input or input == "" then return end
                    local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
                    local current_path = current_picker.cwd
                    local new_folder_path = current_path .. "/" .. input
                    vim.fn.mkdir(new_folder_path, "p")
                    fb_actions.refresh(prompt_bufnr)
                  end)
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

  -- Icons
  {"nvim-tree/nvim-web-devicons"},

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup {
        signs = {
          add            = { text = '+' },
          change         = { text = '~' },
          delete         = { text = '_' },
          topdelete      = { text = '‾' },
          changedelete   = { text = '~' },
          untracked      = { text = '┆' },
        },
        signcolumn = true,
        numhl = false,
        word_diff = false,
        on_attach = function(bufnr)
          local gs = require('gitsigns')
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, 'Next Hunk')

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, 'Prev Hunk')

          map({'n', 'x'}, '<leader>hs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
          map({'n', 'x'}, '<leader>hr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
          map('n', '<leader>hS', gs.stage_buffer, 'Stage Buffer')
          map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo Stage Hunk')
          map('n', '<leader>hR', gs.reset_buffer, 'Reset Buffer')
          map('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
          map('n', '<leader>hb', function() gs.blame_line{full=true} end, 'Blame Line')
          map('n', '<leader>hd', gs.diffthis, 'Diff This')
          map('n', '<leader>hD', function() gs.diffthis('~') end, 'Diff This (~)')
          map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'Select Hunk')
        end,
      }
    end,
  },
}, {})


--- Colorscheme and Global Keymaps

-- 3. Set Colorscheme and Dark/Light Toggle with darklight.nvim
-- Initial setup of darklight.nvim
require('darklight').setup({
  mode = 'colorscheme',
  -- Miasma is a dark theme, so it fits here.
  -- You can choose between 'paramount' and 'miasma' as your default dark theme.
  -- Let's set miasma as the primary dark one for this example.
  dark_mode_colorscheme = 'miasma',
  initial_mode = 'dark', -- Start with the dark theme (Miasma)
})

-- Now, instead of setting colorscheme manually, darklight will handle it
-- vim.o.background = "dark"
vim.cmd.colorscheme "miasma"

-- 4. Global Keymaps
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Map a key to toggle the theme (e.g., <leader>t for "toggle theme")
map("n", "<leader>t", ":DarkLightSwitch<CR>", { desc = "Toggle Dark/Light Theme" })

-- Find files in current project (Ctrl+p)
map("n", "<C-p>", function()
  require("telescope.builtin").find_files({ previewer = true })
end, opts)

-- Find words in current file (Ctrl+f)
map("n", "<C-f>", function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end, opts)

-- Find words in all the files
vim.keymap.set("n", "<leader>fs", function() require('telescope.builtin').live_grep() end, { noremap = true, desc = "Live Grep" })

-- Open last closed file (Ctrl+Shift+t)
map("n", "<C-S-t>", function()
  require("telescope.builtin").oldfiles()
end, opts)

-- Close current buffer (Ctrl+w)
-- map("n", "<C-w>", "<cmd>bdelete<CR>", opts) // fuck this line, i want to move between splitted screens

-- Open file browser/tree on the right side (leader + e)
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

-- Toggle nvim-tree with Ctrl+o
vim.keymap.set("n", "<C-o>", ':NvimTreeToggle<CR>', {noremap = true, silent = true})

-- Global Keymap for creating new file/folder with nvim-tree's API
vim.keymap.set("n", "<C-n>", function()
  local api = require("nvim-tree.api")
  if not api then
    print("nvim-tree not loaded. Cannot create file/folder.")
    return
  end

  local dir_path
  local node = api.tree.get_node_under_cursor()

  if node and node.absolute_path then
    if node.nodes then
      dir_path = node.absolute_path
    else
      dir_path = vim.fn.fnamemodify(node.absolute_path, ":h")
    end
  else
    dir_path = vim.loop.cwd()
  end

  vim.ui.input({ prompt = "New file/folder name (end with / for folder): " }, function(input)
    if input == nil or input == "" then
      print("Cancelled")
      return
    end

    local new_path = dir_path .. "/" .. input

    api.fs.create(new_path)
    api.tree.reload()
  end)
end, opts)


--- Auto-commands and Diagnostics

-- Auto-commands
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0, name = "gopls" })
    if #clients > 0 then
      vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
    end
  end,
})

-- Diagnostic configuration (visuals)
vim.diagnostic.config({
  virtual_text = {
    -- prefix = '●',
    -- source = "always",
    -- severity = { min = vim.diagnostic.severity.WARN },
    -- spacing = 4,
    -- underline = true,
  },
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = "single",
    source = "always",
    header = false,
    prefix = "",
  },
})

-- Set up diagnostic signs (colors can be customized in your colorscheme)
vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticError", numhl = "DiagnosticError" })
vim.fn.sign_define("DiagnosticSignWarn",  { text = "", texthl = "DiagnosticWarn",  numhl = "DiagnosticWarn"  })
vim.fn.sign_define("DiagnosticSignInfo",  { text = "", texthl = "DiagnosticInfo",  numhl = "DiagnosticInfo"  })
vim.fn.sign_define("DiagnosticSignHint",  { text = "", texthl = "DiagnosticHint",  numhl = "DiagnosticHint"  })
