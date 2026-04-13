local ui = require('athena.ui')
local nav = require('athena.nav')
local fs = require('athena.fs')

local M = {}

local function get_history_file()
    local history_file = fs.find_history()
    if not history_file then
        vim.notify('athena: no .athena project found', vim.log.levels.ERROR)
        return nil
    end
    return history_file
end

local function get_last_entry(history_file)
    if not history_file then
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

local function open()
    local history_file = get_history_file()
    if not history_file then
        return nil
    end

    local handle = {
        dispose = nil
    }

    return ui.open(
        function(buf)
            nav.set_keymaps(buf)
            local function refresh()
                local entry = get_last_entry(history_file)
                if entry then
                    nav.load_entry(entry)
                end
            end

            handle.dispose = fs.watch(history_file, function()
                vim.schedule(refresh)
            end)
            refresh()
        end,
        function()
            if handle.dispose then
                handle.dispose()
            end
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
end

function M.setup(opts)
    vim.api.nvim_create_user_command('Athena', function(cmd_opts)
        local args = cmd_opts.fargs

        if #args == 0 then
            nav.set_mode('default')
            open()
        else
            vim.notify('athena: unknown subcommand: ' .. args[1], vim.log.levels.ERROR)
        end
    end, { nargs = '*' })

    vim.api.nvim_create_user_command('AthenaResponse', function(cmd_opts)
        nav.set_mode('response')
        open()
    end, {})
end

return M
