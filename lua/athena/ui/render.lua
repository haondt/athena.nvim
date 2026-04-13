local util = require('athena.ui.util')
local hl = require('athena.ui.hl_util')
local winbar = require('athena.ui.winbar_util')

local M = {}

local state = {
    opts = nil,
}

function M.setup(opts)
    state.opts = opts
end

local function set_lines(buf, lines, modifiable)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if modifiable == nil then
        vim.bo[buf].modifiable = false
    else
        vim.bo[buf].modifiable = modifiable
    end
end


local function set_ft(buf, ft)
    local clients = vim.lsp.get_clients({ bufnr = buf })
    for _, client in ipairs(clients) do
        vim.lsp.buf_detach_client(0, client.id)
    end

    -- at the time of writing, vim.lsp does not attach automatically on nofile buffers
    -- so we engage in a bit of trickery
    -- https://github.com/neovim/neovim/issues/36599
    -- https://github.com/neovim/neovim/issues/36775
    if vim.bo[buf].buftype == 'nofile' then
        vim.bo[buf].buftype = ''
        vim.bo[buf].filetype = ft
        vim.bo[buf].buftype = 'nofile'
    else
        vim.bo[buf].filetype = ft
    end
end


local function push_kv(lines, highlights, pairs)
    local max_len = 0
    for _, pair in ipairs(pairs) do
        if #pair[1] > max_len then max_len = #pair[1] end
    end
    for _, pair in ipairs(pairs) do
        local key = pair[1]
        local value = tostring(pair[2] ~= nil and pair[2] or '')
        local hl = pair[3]
        local line = key .. string.rep(' ', max_len - #key + state.opts.ui.kv_padding) .. value
        table.insert(lines, line)
        local row = #lines - 1
        local val_start = max_len + state.opts.ui.kv_padding
        table.insert(highlights, { row, 0, #key, 'AthenaKey' })
        if hl then
            table.insert(highlights, { row, val_start, val_start + #value, hl })
        end
    end
end

local function push_section(lines, highlights, title)
    table.insert(lines, title)
    local row = #lines - 1
    table.insert(highlights, { row, 0, #title, 'AthenaSectionHeader' })
end

local function push_multiline(lines, str, highlights, hl_group)
    for _, l in ipairs(vim.split(tostring(str), '\n', { plain = true })) do
        table.insert(lines, l)
        if highlights and hl_group then
            table.insert(highlights, { #lines - 1, 0, #l, hl_group })
        end
    end
end


function M.layer1(entry, buf, win)
    local lines = {}
    local highlights = {}
    local navigable = {}

    local function push(line)
        table.insert(lines, line)
    end

    -- warnings (omit if no warnings)
    local warnings = {}
    for i, trace in ipairs(entry.athena_traces) do
        if trace.warnings then
            for _, v in ipairs(trace.warnings) do
                table.insert(warnings, { i, v })
            end
        end
    end
    if #warnings > 0 then
        push_section(lines, highlights, 'warnings')
        for _, w in ipairs(warnings) do
            local idx = w[1]
            local text = tostring(w[2])
            local prefix = '[' .. idx .. '] '
            local text_lines = vim.split(text, '\n', { plain = true })
            for j, l in ipairs(text_lines) do
                local line = j == 1 and (prefix .. l) or l
                table.insert(lines, line)
                local row = #lines - 1
                table.insert(highlights, { row, 0, #(j == 1 and prefix or ''), 'AthenaDimmed' })
                table.insert(highlights, { row, #(j == 1 and prefix or ''), #lines[#lines], 'AthenaWarning' })
            end
        end
        push('')
    end

    -- error (omit if nil)
    if not entry.success then
        push_section(lines, highlights, 'error')
        if entry.error and entry.error ~= vim.NIL then
            local start_row = #lines
            push_multiline(lines, tostring(entry.error), highlights, 'AthenaError')
        end
        push('')
    end

    -- result (omit if nil)
    if entry.result and entry.result ~= vim.NIL then
        push_section(lines, highlights, 'result')
        push(tostring(entry.result))
        push('')
    end

    -- traces
    push_section(lines, highlights, 'traces')
    for _, l in ipairs(util.render_timings(entry.athena_traces, buf, state.opts.ui.max_timing_width)) do
        push(l)
        hl.timing(lines, highlights)
    end
    for i, trace in ipairs(entry.athena_traces) do
        local method = trace.request.method
        local url = trace.request.url
        local sc = trace.response.status_code
        local reason = trace.response.reason
        local ms = util.elapsed_ms(trace)
        local size = util.format_bytes(#(trace.response.text or ''))

        local line1 = method .. ' ' .. url
        push(line1)
        local row1 = #lines - 1
        table.insert(highlights, { row1, 0, #method, 'AthenaMethod' })
        table.insert(highlights, { row1, #method + 1, #line1, 'AthenaUrl' })

        local sc_str = tostring(sc)
        local line2 = sc_str .. ' ' .. reason .. ' ' .. ms .. ' ' .. size
        push(line2)
        local row2 = #lines - 1
        table.insert(highlights, { row2, 0, #sc_str, hl.status(sc) })
        table.insert(highlights, { row2, #sc_str + 1, #sc_str + 1 + #reason, hl.status(sc) })

        -- both rows map to same action, each knows about the other
        navigable[row1 + 1] = { kind = 'trace', idx = i, peer = row2 + 1 }
        navigable[row2 + 1] = { kind = 'trace', idx = i, peer = row1 + 1 }
    end

    set_lines(buf, lines)
    hl.apply_highlights(buf, highlights)
    set_ft(buf, '')
    if win ~= nil then
        winbar.set(win, winbar.module(entry))
    end
    return navigable
end

function M.layer2(entry, trace_idx, buf, win)
    local trace = entry.athena_traces[trace_idx]
    local lines = {}
    local highlights = {}
    local navigable = {}

    local function push(line)
        table.insert(lines, line)
    end

    push_kv(lines, highlights, {
        { 'name',    trace.name },
        { 'elapsed', util.elapsed_ms(trace) },
    })
    push('')

    if #trace.warnings > 0 then
        push_section(lines, highlights, 'warnings')
        for _, w in ipairs(trace.warnings) do
            push_multiline(lines, w, highlights, 'AthenaWarning')
        end
        push('')
    end


    push_section(lines, highlights, 'request')
    local content_type_kv = { 'content_type', trace.request.content_type }
    if trace.request.content_type == vim.NIL then
        content_type_kv = { 'content_type', '(none)', 'AthenaDimmed' }
    end
    push_kv(lines, highlights, {
        { 'method', trace.request.method, 'AthenaMethod' },
        { 'url',    trace.request.url,    'AthenaUrl' },
        content_type_kv
    })
    push('')
    push_section(lines, highlights, 'headers')
    push_kv(lines, highlights, trace.request.headers)
    push('')
    local req_ft = util.content_type_to_description(trace.request.content_type)
    if req_ft then
        push('body [' .. req_ft .. '] ->')
    else
        push('body ->')
    end

    navigable[#lines] = { kind = 'body', source = 'request' }
    hl.nav(lines, highlights)
    push('')

    push_section(lines, highlights, 'response')
    local sc = trace.response.status_code
    local sc_str = tostring(sc) .. ' ' .. trace.response.reason
    push_kv(lines, highlights, {
        { 'status',       sc_str,                     hl.status(sc) },
        { 'url',          trace.response.url,         'AthenaUrl' },
        { 'content_type', trace.response.content_type },
    })
    push('')
    push_section(lines, highlights, 'headers')
    push_kv(lines, highlights, trace.response.headers)
    push('')
    local res_ft = util.content_type_to_description(trace.response.content_type)
    if res_ft then
        push('body [' .. res_ft .. '] ->')
    else
        push('body ->')
    end
    navigable[#lines] = { kind = 'body', source = 'response' }
    hl.nav(lines, highlights)

    for i, line in ipairs(lines) do
        if line:find('\n') then
            vim.notify('newline in line ' .. i .. ': ' .. vim.inspect(line), vim.log.levels.ERROR)
        end
    end
    set_lines(buf, lines)

    set_lines(buf, lines)
    hl.apply_highlights(buf, highlights)
    set_ft(buf, '')
    if win ~= nil then
        winbar.set(win,
            winbar.module(entry)
            .. winbar.sep()
            .. winbar.crumb('traces')
            .. winbar.trace_idx(trace_idx))
    end
    return navigable
end

function M.layer3(entry, trace_idx, source, buf, win)
    local trace = entry.athena_traces[trace_idx]
    local obj = source == 'request' and trace.request or trace.response
    local text = obj.text or ''
    local ft = util.content_type_to_ft(obj.content_type)

    if ft == 'json' then
        text = util.pretty_json(text)
    end

    local lines = vim.split(text, '\n', { plain = true })
    if lines[#lines] == '' then
        table.remove(lines)
    end

    set_lines(buf, lines, true)
    hl.apply_highlights(buf, {})
    set_ft(buf, ft)
    local ft_desc = util.content_type_to_description(obj.content_type)
    winbar.set(win,
        winbar.module(entry)
        .. winbar.sep()
        .. winbar.crumb('traces')
        .. winbar.trace_idx(trace_idx)
        .. winbar.sep()
        .. winbar.crumb(source)
        .. winbar.sep()
        .. winbar.crumb('body')
        .. winbar.ft(ft_desc))

    return {}
end

function M.response(entry, trace_idx, buf, win)
    if trace_idx == nil then
        set_lines(buf, {}, false)
        hl.apply_highlights(buf, {})
        set_ft(buf, '')

        winbar.set(win,
            winbar.crumb('No trace available'))
        return {}
    end
    local trace = entry.athena_traces[trace_idx]

    local text = trace.response.text or ''
    local ft = util.content_type_to_ft(trace.response.content_type)

    if ft == 'json' then
        text = util.pretty_json(text)
    end

    local lines = vim.split(text, '\n', { plain = true })
    if lines[#lines] == '' then
        table.remove(lines)
    end

    set_lines(buf, lines, true)
    hl.apply_highlights(buf, {})
    set_ft(buf, ft)
    local ft_desc = util.content_type_to_description(trace.response.content_type)

    local sc = trace.response.status_code
    local reason = trace.response.reason
    local ms = util.elapsed_ms(trace)
    local size = util.format_bytes(#(trace.response.text or ''))

    local sc_str = tostring(sc)

    local line2 = sc_str .. ' ' .. reason .. ' ' .. ms .. ' ' .. size

    winbar.set(win,
        winbar.crumb(sc_str, hl.status(sc))
        .. winbar.crumb(' ')
        .. winbar.crumb(reason, hl.status(sc))
        .. winbar.crumb(' ')
        .. winbar.crumb(ms)
        .. winbar.crumb(' ')
        .. winbar.crumb(size))

    return {}
end

return M
