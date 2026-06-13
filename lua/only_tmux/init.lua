-- only-tmux.nvim
-- Plugin to take TMUX panes into account with :only like functionality

--# INITIALISE #----------------------------------------------------------------

---@class OnlyTmux
local M = {}

---@class OnlyTmuxOpts
---@field new_window_name? string Default name for new windows
local default_config = {
    new_window_name = "moved",
}

local user_config = {} ---@type OnlyTmuxOpts

--# HELPER FUNCTIONS #----------------------------------------------------------

-- up user configuration
---@param config? OnlyTmuxOpts
function M.setup(config)
    user_config = vim.tbl_deep_extend("force", default_config, config or {})
end

--# CALL FUNCTIONS #------------------------------------------------------------

-- close all other tmux panes except the current one
function M.tmuxCloseAll()
    if os.getenv("TMUX") then
        vim.cmd("silent! !tmux killp -a")
    end
    vim.cmd.only()
end

-- move all other tmux panes to a new window
function M.tmuxMoveOthers()
    if not os.getenv("TMUX") then
        return
    end

    local new_window = user_config.new_window_name
    local window_num = vim.fn.system('tmux display-message -p "#I"'):gsub("\n", "")

    vim.cmd("silent! !tmux breakp")
    vim.cmd("silent! !tmux renamew -t " .. window_num .. " " .. new_window)
    vim.cmd("silent! !tmux swapw -d -t " .. window_num)

    vim.cmd.only()
end

--# NVIM DISPATCH #-------------------------------------------------------------

-- call the appropriate function based on the option
---@param option "move"|"close"
function M.dispatch(option)
    if not vim.list_contains({ "move", "close" }, option) then
        vim.notify("Invalid option. Please use one of: move, close", vim.log.levels.ERROR)
        return
    end

    if option == "move" then
        M.tmuxMoveOthers()
    elseif option == "close" then
        M.tmuxCloseAll()
    end
end

-- invoke the dispatch function
vim.api.nvim_create_user_command("TMUXonly", function(args)
    M.dispatch(args.args)
end, {
    nargs = 1,
    ---@param cmdline string
    ---@return string[] entries
    complete = function(_, cmdline)
        local entries = {} ---@type string[]
        local args = vim.split(cmdline, "%s+", { trimempty = false })
        if #args == 2 then
            for _, entry in ipairs({ "move", "close" }) do
                if vim.startswith(entry, args[2]) then
                    table.insert(entries, entry)
                end
            end
        end
        return entries
    end,
})

return M
