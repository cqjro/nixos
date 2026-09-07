local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local extras = require("luasnip.extras")
local rep = extras.rep -- repetition node (like editing text in begin/end of latex env)
local fmt = require("luasnip.extras.fmt").fmt -- format node (less verbose)
local c = ls.choice_node -- insert mode which allows you to cycle through multiple snippets
-- TODO: add choice node keybind
local f = ls.function_node -- allows you to pass a lua function into the snippet (returns string)
local d = ls.dynamic_node -- like a function mode node but returns a snippet instead of a string
local sn = ls.snippet_node

vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})

vim.keymap.set({"i", "s"}, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, {silent = true})

ls.add_snippets("lua", {
	s("hello", {
		t('print("hello world")'),
		i(1),
		t(' world")')
	})
})
