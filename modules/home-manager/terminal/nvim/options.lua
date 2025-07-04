-- general
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- indentation
vim.o.tabstop = 2
vim.o.shiftwidth = 2

-- line numbers
vim.o.number = true;
vim.o.relativenumber = true;

-- silence depreciation messages
vim.deprecate = function()
    -- Do nothing, effectively silencing the deprecation message
end

-- Vim Keybinds
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

