local ui = require('athena.ui')
local render = require('athena.ui.render')

local M = {}

local state = {
    opts = nil,
    layer = 1,
    entry = nil,
    trace_idx = nil,
    cursor_stack = {},
    navigable = {},
}

local function save_cursor()
    local win = ui.get_win()
    if win ~= -1 then
        table.insert(state.cursor_stack, vim.api.nvim_win_get_cursor(win))
    end
end

local function restore_cursor()
    if #state.cursor_stack > 0 then
        local pos = table.remove(state.cursor_stack)
        local win = ui.get_win()
        if win ~= -1 then
            vim.api.nvim_win_set_cursor(win, pos)
        end
    end
end

local function set_cursor_top()
    local win = ui.get_win()
    if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end
end

function M.get_action(row)
    return state.navigable[row]
end

function M.navigate_in()
    local win = ui.get_win()
    if win == -1 then return end
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local action = state.navigable[row]
    if not action then return end

    save_cursor()

    if action.kind == 'trace' then
        state.layer = 2
        state.trace_idx = action.idx
        state.navigable = render.layer2(state.entry, state.trace_idx, ui.get_buf(), ui.get_win())
        set_cursor_top()
    elseif action.kind == 'body' then
        state.layer = 3
        state.navigable = render.layer3(state.entry, state.trace_idx, action.source, ui.get_buf(), ui.get_win())
        set_cursor_top()
    end
end

function M.navigate_out()
    if state.layer == 1 then return end
    state.layer = state.layer - 1
    if state.layer == 1 then
        state.trace_idx = nil
        state.navigable = render.layer1(state.entry, ui.get_buf(), ui.get_win())
    elseif state.layer == 2 then
        state.navigable = render.layer2(state.entry, state.trace_idx, ui.get_buf(), ui.get_win())
    end
    restore_cursor()
end

function M.load_entry(entry)
    state.entry = entry
    state.layer = 1
    state.trace_idx = nil
    state.cursor_stack = {}
    state.navigable = render.layer1(state.entry, ui.get_buf(), ui.get_win())
    set_cursor_top()
end

function M.set_keymaps(buf)
    vim.keymap.set('n', state.opts.keymaps.confirm, M.navigate_in,
        { noremap = true, silent = true, buffer = buf })
    vim.keymap.set('n', state.opts.keymaps.back, M.navigate_out,
        { noremap = true, silent = true, buffer = buf })
end

function M.setup(opts)
    state.opts = opts
end

return M
