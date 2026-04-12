local M = {}

local function set_default_hl(name, val)
    local existing = vim.api.nvim_get_hl(0, { name = name })
    if vim.tbl_isempty(existing) then
        vim.api.nvim_set_hl(0, name, val)
    end
end

function M.setup()
    set_default_hl('AthenaKey', { link = 'Identifier' })
    set_default_hl('AthenaNav', { link = 'Special' })
    set_default_hl('AthenaDimmed', { link = 'Comment' })
    set_default_hl('AthenaTiming', { link = 'NonText' })
    set_default_hl('AthenaSuccess', { link = 'DiagnosticOk' })
    set_default_hl('AthenaWarning', { link = 'DiagnosticWarn' })
    set_default_hl('AthenaError', { link = 'DiagnosticError' })
    set_default_hl('AthenaSectionHeader', { link = 'Title' })
    set_default_hl('AthenaStatusCode', { link = 'DiagnosticOk' })
    set_default_hl('AthenaStatusReason', { link = 'Comment' })
    set_default_hl('AthenaMethod', { link = 'Constant' })
    set_default_hl('AthenaUrl', { link = 'Identifier' })
    set_default_hl('AthenaTraceHover', { link = 'CursorLine' })
end

return M
