vim.lsp.enable({
    "gopls",
    "lua_ls",
		"nixd",
		"pyright",
		"rust_analyzer",
		"texlab",
		"ts_ls",
})

vim.diagnostic.config({
    virtual_lines = true,
    -- virtual_text = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})

  -- Set up cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('lua_ls', {
	capabilities = capabilities,
	settings = {
		Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
		},
	},
})


vim.lsp.config('nixd', {
	capabilities = capabilities,
})


vim.lsp.config('pyright', {
	capabilities = capabilities,
})


vim.lsp.config('rust_analyzer', {
	capabilities = capabilities,
})


vim.lsp.config('texlab', {
	capabilities = capabilities,
})


vim.lsp.config('ts_ls', {
	capabilities = capabilities,
})


vim.lsp.config('gopls', {
	capabilities = capabilities,
})


