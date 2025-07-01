-- general
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- indentation
vim.o.tabstop = 2
vim.o.shiftwidth = 2

-- line numbers
vim.o.number = true;
vim.o.relativenumber = true;

-- keymaps
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- silence depreciation messages
vim.deprecate = function()
    -- Do nothing, effectively silencing the deprecation message
end


vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		vim.api.nvim_set_hl(0, "NormalFloat", {fg="#b8b0c6", bg="#191324" })
	end,
})

