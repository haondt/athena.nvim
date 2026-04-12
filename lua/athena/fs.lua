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

return M
