local M = {}

local state = {
    opts = nil,
}

function M.setup(opts)
    state.opts = opts
end

local function entry_symbol(entry)
    if not entry.success then
        return state.opts.symbols.error, 'AthenaError'
    elseif entry.error and entry.error ~= vim.NIL then
        return state.opts.symbols.success_with_warnings, 'AthenaWarning'
    else
        return state.opts.symbols.success, 'AthenaSuccess'
    end
end



function M.module(entry)
    local sym, hl = entry_symbol(entry)
    return '%#' .. hl .. '# ' .. sym
        .. ' %#AthenaSectionHeader#' .. (entry.module_name or '')
        .. '%#AthenaDimmed#[' .. (entry.environment or '') .. ']'
end

function M.sep()
    return '%#AthenaNav# / '
end

function M.crumb(text, hl)
    if not hl then
        hl = 'AthenaKey'
    end
    return '%#' .. hl .. '#' .. text
end

function M.trace(trace)
    return '%#AthenaMethod# ' .. trace.request.method
        .. ' %#AthenaUrl#' .. trace.request.url
end

function M.trace_idx(trace_idx)
    return '%#AthenaDimmed#[' .. trace_idx .. ']'
end
function M.ft(ft)
    if ft then
        return '%#AthenaDimmed#[' .. ft .. ']'
    else
        return ''
    end
end

function M.set(win, text)
    vim.wo[win].winbar = text
end

return M
