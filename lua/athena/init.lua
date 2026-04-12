local commands = require('athena.commands')
local nav = require('athena.nav')
local render = require('athena.ui.render')
local highlights = require('athena.ui.highlights')
local winbar = require('athena.ui.winbar_util')

local M = {}

local default_opts = {
    ui = {
        max_timing_width = 80,
        kv_padding = 4,
    },
    keymaps = {
        confirm = '<CR>',
        back = '<Esc>',
        toggle_mode = '<Tab>',
    },
    symbols = {
        success = 'O',
        success_with_warnings = '*',
        error = 'X',
    },
}

function M.setup(opts)
    opts = vim.tbl_deep_extend('force', default_opts, opts or {})
    highlights.setup()
    render.setup(opts)
    nav.setup(opts)
    commands.setup(opts)
    winbar.setup(opts)
end

return M
