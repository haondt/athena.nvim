local render = require('athena.ui.render')

local M = {}

local state = {
    buf = nil,
    win = nil
}

local hover_ns = vim.api.nvim_create_namespace('athena_hover')

local function buf_is_valid()
    return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

function M.clear_hover()
    if buf_is_valid() then
        vim.api.nvim_buf_clear_namespace(state.buf, hover_ns, 0, -1)
    end
end

function M.apply_hover(rows)
    M.clear_hover()
    for _, row in ipairs(rows) do
        vim.api.nvim_buf_set_extmark(state.buf, hover_ns, row - 1, 0, {
            end_row = row,
            hl_group = 'AthenaTraceHover',
            hl_eol = true,
        })
    end
end

function M.open(on_create, on_destroy, on_cursor_moved)
    if buf_is_valid() then return end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].modifiable = false

    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)
    if win_width > win_height * 2 then
        vim.cmd('rightbelow vsplit')
    else
        vim.cmd('rightbelow split')
    end

    state.win = vim.api.nvim_get_current_win()
    state.buf = buf
    vim.api.nvim_win_set_buf(state.win, buf)

    vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = buf,
        callback = function()
            local current_win = vim.api.nvim_get_current_win()
            if current_win ~= state.win then return end
            on_cursor_moved(state.win)
        end,
    })

    vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
        buffer = buf,
        once = true,
        callback = function()
            if on_destroy then
                on_destroy(buf)
            end
            state.buf = nil
            state.win = nil
        end,
    })

    if on_create then
        on_create(buf)
    end
end

function M.get_buf()
    return state.buf
end

function M.get_win()
    return state.win
end

function M.is_open()
    return buf_is_valid()
end

return M
