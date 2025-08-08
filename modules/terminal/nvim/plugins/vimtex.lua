-- require("vimtex").setup()
-- Viewer settings
vim.g.vimtex_view_method = 'sioyek'            -- Sioyek PDF viewer for academic documents
-- vim.g.vimtex_context_pdf_viewer = 'zathura'     -- External PDF viewer for the Vimtex menu

-- Formatting settings
-- vim.g.vimtex_format_enabled = true             -- Enable formatting with latexindent
-- vim.g.vimtex_format_program = 'latexindent'

-- Indentation settings
-- vim.g.vimtex_indent_enabled = false            -- Disable auto-indent from Vimtex
-- vim.g.tex_indent_items = false                 -- Disable indent for enumerate
-- vim.g.tex_indent_brace = false                 -- Disable brace indent

-- Suppression settings
-- vim.g.vimtex_quickfix_mode = 0                 -- Suppress quickfix on save/build
-- vim.g.vimtex_log_ignore = {                    -- Suppress specific log messages
-- 	'Underfull',
-- 	'Overfull',
-- 	'specifier changed to',
-- 	'Token not allowed in a PDF string',
-- }

-- Other settings
-- vim.g.vimtex_mappings_enabled = false          -- Disable default mappings
-- vim.g.tex_flavor = 'latex'                     -- Set file type for TeX fileui

vim.g.vimtex_compiler_latexmk = {
    build_dir = '',
    callback = 1,
    continuous = 1,
    executable = 'latexmk',
    options = {
        '-xelatex',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
    },
}

vim.g.vimtex_grammar_textidote = {
    jar = 'textidote',
    args = '--check en',
}

vim.g.vimtex_grammar_enabled = 1


