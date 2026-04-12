local M = {}

function M.elapsed_ms(trace)
    local s = trace['end'] - trace.start
    return math.floor(s * 1000) .. 'ms'
end

function M.content_type_to_ft(ct)
    if not ct or ct == vim.NIL then return 'text' end
    if ct:match('json') then return 'json' end
    if ct:match('html') then return 'html' end
    if ct:match('xml') then return 'xml' end
    return 'text'
end

function M.content_type_to_description(ct)
    if not ct or ct == vim.NIL then return nil end
    if ct:match('json') then return 'json' end
    if ct:match('html') then return 'html' end
    if ct:match('xml') then return 'xml' end
    if ct:match('form') then return 'form' end
    return 'text'
end

function M.format_bytes(n)
    if n < 1024 then
        return n .. 'B'
    elseif n < 1024 * 1024 then
        return string.format('%.1fKB', n / 1024)
    else
        return string.format('%.1fMB', n / (1024 * 1024))
    end
end

function M.render_timings(traces, buf, max_width)
    local win = vim.fn.bufwinid(buf)
    local win_width = win ~= -1 and vim.api.nvim_win_get_width(win) or 80
    local width = math.min(win_width, max_width)

    if #traces == 0 then return {} end

    local t_start = traces[1].start
    local t_end = traces[#traces]['end']
    local duration = t_end - t_start
    if duration == 0 then duration = 1 end

    local lines = {}
    for _, trace in ipairs(traces) do
        local s = math.floor(((trace.start - t_start) / duration) * width)
        local e = math.floor(((trace['end'] - t_start) / duration) * width)
        local line = string.rep(' ', s) .. string.rep('·', math.max(1, e - s))
        table.insert(lines, line)
    end
    return lines
end

function M.pretty_json(text)
    local result = vim.fn.system('jq --indent 4 .', text)
    if vim.v.shell_error == 0 then
        return result
    end
    return text
end

return M
