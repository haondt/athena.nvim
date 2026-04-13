local fs            = require('athena.fs')
local previewers    = require("telescope.previewers")
local action_state  = require("telescope.actions.state")
local actions       = require('telescope.actions')
local sorters       = require("telescope.sorters")
local hl            = require('athena.ui.hl_util')
local render        = require('athena.ui.render')
local pickers       = require("telescope.pickers")
local finders       = require("telescope.finders")
local entry_display = require("telescope.pickers.entry_display")
local util          = require('athena.ui.util')
local conf          = require("telescope.config").values



local M = {}

local function extract_host(url)
    return url:match("^[^:]+://([^/]+)")
        or url:match("^([^/]+)")
        or ''
end


local trace_previewer = previewers.new_buffer_previewer({
    title = 'Trace',
    dyn_title = function(_, e)
        if e.trace_idx == nil then
            return e.value.module_name
        else
            return e.value.athena_traces[e.trace_idx].name
        end
    end,
    define_preview = function(self, entry, _)
        local lines = {}
        local highlights = {}

        if entry.trace_idx == nil then
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(self.state.bufnr) then return end
                render.layer1(entry.value, self.state.bufnr)
                vim.wo[self.state.winid].wrap = true
                vim.wo[self.state.winid].linebreak = true
            end)
        else
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(self.state.bufnr) then return end
                render.layer2(entry.value, entry.trace_idx, self.state.bufnr)
                vim.wo[self.state.winid].wrap = true
                vim.wo[self.state.winid].linebreak = true
            end)
        end
    end,
})

function M.history(file, on_select)
    local history_file = fs.find_history()
    if not history_file then
        return {}
    end
    local lines = vim.fn.readfile(history_file)
    if #lines == 0 then
        return {}
    end

    local entries = {}
    for _, line in ipairs(lines) do
        local ok, entry = pcall(vim.json.decode, line)
        if not ok then
            vim.notify('athena: failed to parse history entry', vim.log.levels.ERROR)
            return {}
        end

        for i, _ in ipairs(entry.athena_traces) do
            table.insert(entries, {
                trace_idx = i,
                parent = entry,
            })
        end

        if #entry.athena_traces == 0 then
            table.insert(entries, {
                trace_idx = nil,
                parent = entry,
            })
        end
    end

    local displayer = entry_display.create({
        separator = " ",
        items     = {
            { width = 7 },
            { remaining = true },
            { width = 3 },
            { width = 10 },
        },
    })



    local picker = pickers.new({}, {
        prompt_title    = "Athena History",
        finder          = finders.new_table({
            results     = entries,
            entry_maker = function(e)
                if e.trace_idx == nil then
                    local item = { e.parent.filename }
                    if not e.parent.success then
                        item = { e.parent.filename, "AthenaError" }
                    end
                    return {
                        trace_idx = nil,
                        value     = e.parent,
                        ordinal   = e.parent.filename,
                        display   = function(et)
                            return displayer({
                                '',
                                item
                            })
                        end,
                    }
                end

                local trace = e.parent.athena_traces[e.trace_idx]

                local sc = trace.response.status_code
                local sc_str = tostring(sc)
                local reason = trace.response.reason
                local method = trace.request.method
                local url = trace.request.url
                local host = extract_host(url)

                return {
                    trace_idx = e.trace_idx,
                    value     = e.parent,
                    ordinal   = method
                        .. ' ' .. host
                        .. ' ' .. sc_str
                        .. ' ' .. reason,
                    display   = function(et)
                        return displayer({
                            { method, "AthenaMethod" },
                            { host,   "AthenaUrl" },
                            { sc_str, hl.status(sc) },
                            { reason, hl.status(sc) }
                        })
                    end,
                }
            end,
        }),
        sorter          = sorters.get_fzy_sorter({}),
        previewer       = trace_previewer,
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local sel = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if sel then
                    on_select(sel.value)
                end
            end)
            return true
        end,
    })

    picker:find()
end

return M
