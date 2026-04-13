# athena.nvim

A Neovim plugin for [athena](https://github.com/haondt/athena).

### Requirements

- [jq](https://github.com/jqlang/jq)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

### Usage

Lazy installation

```lua
{
    "haondt/athena.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    opts = {
    },
    keys = {
        {
            "<leader>ah",
            "<CMD>AthenaHistory<CR>",
            desc = "[a]thena [h]istory"
        },
        {
            "<leader>at",
            "<CMD>AthenaToggle<CR>",
            desc = "[a]thena [t]oggle"
        },
        {
            "<leader>ar",
            "<CMD>AthenaResponse<CR>",
            desc = "[a]thena [r]esponse"
        },
        {
            "<leader>ad",
            "<CMD>Athena<CR>",
            desc = "[a]thena [d]efault"
        },
    }
}
```
