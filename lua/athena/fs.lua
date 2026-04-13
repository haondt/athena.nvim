local M = {}

function M.find_root(root)
    local cwd = root or vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. '/.athena') == 1 then
        return cwd
    end
    return nil
end

function M.find_history(root)
    local root = M.find_root(root)
    if root == nil then
        return nil
    end
    return root .. '/.history'
end

function M.watch(file, callback)
    local handle = vim.uv.new_fs_event()
    vim.uv.fs_event_start(handle, file, {}, function(err, filename, events)
        if err then
            vim.notify("Watch error: " .. err, vim.log.levels.ERROR)
            return
        end

        callback(filename, events)
    end)

    local disposed = false
    return function()
        if disposed then
            return
        end
        vim.uv.fs_event_stop(handle)
        disposed = true
    end
end

return M
