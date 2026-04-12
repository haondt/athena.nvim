local M = {}

local ns = vim.api.nvim_create_namespace('athena')

function M.apply_highlights(buf, highlights)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, h in ipairs(highlights) do
        vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], {
            end_col = h[3],
            hl_group = h[4],
        })
    end
end

function M.status(status_code)
    if status_code < 300 then
        return 'AthenaSuccess'
    elseif status_code < 400 then
        return 'AthenaWarning'
    else
        return 'AthenaError'
    end
end

function M.nav(lines, highlights)
    local row = #lines - 1
    local line = lines[#lines]
    local arrow_start = line:find('->') - 1
    table.insert(highlights, { row, arrow_start, arrow_start + 2, 'AthenaNav' })
end

function M.timing(lines, highlights)
    local row = #lines - 1
    local line = lines[#lines]
    local s = line:find('·')
    if s then
        local e = line:find('[^·]', s) or #line + 1
        table.insert(highlights, { row, s - 1, e - 1, 'AthenaTiming' })
    end
end

return M
