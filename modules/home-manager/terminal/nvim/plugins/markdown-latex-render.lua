-- ex in ftplugin/markdown.lua
vim.api.nvim_buf_set_keymap(0, "n", "<leader>lr", require("markdown-latex-render.render").rerender_buf, { noremap = true, silent = true })

require('markdown-latex-render').setup({
	opts = {
		-- directory where the temporary generated images will be stored
		img_dir = "/tmp/markdown-latex-render",
		-- level for the logger, log file generated in vim log stdpath
		log_level = "WARN",
		render = {
			appearance = {
				-- will pick your normal fg text color can be any hex string color though
				fg = "default",
				bg = nil,
				transparent = true,
				-- a bit janky but I need some way of getting the width of the window in some real unit not just columns (image generated with this width)
				columns_per_inch = 18,
			},
			-- when first opening the buffer if the latex should get rendered automatically
			on_open = true,
			-- if you want to trigger some render functionality on write you can supply 'render' or 'rerender' here
			on_write = nil,
		},
	},
})
