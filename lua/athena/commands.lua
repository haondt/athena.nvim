local ui = require('athena.ui')
local nav = require('athena.nav')
local fs = require('athena.fs')

local M = {}

local function get_last_entry()
    local history_file = fs.find_history()
    if not history_file then
        vim.notify('athena: no .athena project found', vim.log.levels.ERROR)
        return nil
    end

    local lines = vim.fn.readfile(history_file)
    if #lines == 0 then
        vim.notify('athena: history is empty', vim.log.levels.ERROR)
        return nil
    end

    local last_line = lines[#lines]
    local ok, entry = pcall(vim.json.decode, last_line)
    if not ok then
        vim.notify('athena: failed to parse history entry', vim.log.levels.ERROR)
        return nil
    end

    return entry
end

local function open_and_load(entry)
    ui.open(function(buf)
            nav.set_keymaps(buf)
        end,
        function(win)
            local row = vim.api.nvim_win_get_cursor(win)[1]
            local action = nav.get_action(row)
            if action and (action.kind == 'trace' or action.kind == 'body') then
                ui.apply_hover({ row, action.peer })
            else
                ui.clear_hover()
            end
        end)
    nav.load_entry(entry)
end

function M.setup(opts)
    vim.api.nvim_create_user_command('Athena', function(cmd_opts)
        local args = cmd_opts.fargs

        if #args == 0 then
            local entry = get_last_entry()
            if entry then
                open_and_load(entry)
            end
        elseif args[1] == 'run' then
            local rest = vim.list_slice(args, 2)
            local cmd = vim.list_extend({ 'athena', 'run', '--plain' }, rest)
            vim.fn.jobstart(cmd, {
                on_exit = function()
                    local entry = get_last_entry()
                    if entry then
                        open_and_load(entry)
                    end
                end
            })
        else
            vim.notify('athena: unknown subcommand: ' .. args[1], vim.log.levels.ERROR)
        end
    end, { nargs = '*' })
end

return M
