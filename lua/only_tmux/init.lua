-- only-tmux.nvim
-- Plugin to take TMUX panes into account with :only like functionality

--# INITIALISE #----------------------------------------------------------------

local M = {}

local default_config = {
    new_window_name = "moved", -- default name for new windows
}

local user_config = {}

--# HELPER FUNCTIONS #----------------------------------------------------------

-- up user configuration
function M.setup(config)
    user_config = vim.tbl_extend("force", default_config, config or {})
end

--# CALL FUNCTIONS #------------------------------------------------------------

-- close all other tmux panes except the current one
function M.tmuxCloseAll()
    if os.getenv("TMUX") then
        vim.cmd("silent !tmux killp -a")
        vim.cmd("silent only")
    else
        vim.cmd("silent only")
    end
end

-- move all other tmux panes to a new window
function M.tmuxMoveOthers()
    if os.getenv("TMUX") then
        local new_window = user_config.new_window_name
        local window_num = vim.fn.system('tmux display-message -p "#I"')
        window_num = string.gsub(window_num, "\n", "")

        vim.cmd("silent !tmux breakp")
        vim.cmd("silent !tmux renamew -t " .. window_num .. " " .. new_window)
        vim.cmd("silent !tmux swapw -d -t " .. window_num)

        vim.cmd("silent only")
    end
end

--# NVIM DISPATCH #-------------------------------------------------------------

-- call the appropriate function based on the option
function M.dispatch(option)
    if option == "move" then
        M.tmuxMoveOthers()
    elseif option == "close" then
        M.tmuxCloseAll()
    else
        print("Invalid option. Please use one of: move, close")
    end
end

-- invoke the dispatch function
vim.api.nvim_create_user_command("TMUXonly", function(args)
    M.dispatch(args.args)
end, {
    nargs = 1,
    complete = function(arglead, cmdline, cursorpos)
        return { "move", "close" }
    end,
})

return M
