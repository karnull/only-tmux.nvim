-- only-tmux.nvim
-- Plugin to take TMUX panes into account with :only like functionality

--# INITIALISE #----------------------------------------------------------------

local M = {}

local default_config = {
    new_window_name = "moved", -- default name for new windows created by `move`
}

M.config = vim.deepcopy(default_config)


--# HELPER FUNCTIONS #----------------------------------------------------------

-- check whether nvim is running inside a tmux session
local function in_tmux()
    return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

-- run a tmux command silently and return its trimmed stdout, or nil on error
local function tmux(args)
    local cmd = vim.list_extend({ "tmux" }, args)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify(
            "only-tmux: tmux " .. table.concat(args, " ") .. " failed",
            vim.log.levels.ERROR
        )
        return nil
    end
    return vim.trim(result)
end

-- close every nvim window except the current one without disturbing buffers
local function nvim_only()
    pcall(vim.cmd.only)
end


--# CALL FUNCTIONS #------------------------------------------------------------

-- close all other tmux panes except the current one
function M.close()
    nvim_only()
    if in_tmux() then
        tmux({ "kill-pane", "-a" })
    end
end

-- move all other tmux panes to a new window
function M.move()
    nvim_only()
    if not in_tmux() then
        return
    end

    local window_num = tmux({ "display-message", "-p", "#I" })
    if not window_num then
        return
    end

    if tmux({ "break-pane" }) == nil then
        return
    end
    tmux({ "rename-window", "-t", window_num, M.config.new_window_name })
    tmux({ "swap-window", "-d", "-t", window_num })
end

-- focus the current pane: :only in nvim and zoom the tmux pane to fill the window
function M.zoom()
    nvim_only()
    if not in_tmux() then
        return
    end

    local flag = tmux({ "display-message", "-p", "#{window_zoomed_flag}" })
    if flag == "0" then
        tmux({ "resize-pane", "-Z" })
    end
end


--# SETUP #---------------------------------------------------------------------

-- apply user configuration
function M.setup(config)
    M.config = vim.tbl_extend("force", default_config, config or {})
end


--# NVIM DISPATCH #-------------------------------------------------------------

local actions = {
    close = M.close,
    move = M.move,
    zoom = M.zoom,
}

-- call the appropriate function based on the option
function M.dispatch(option)
    local fn = actions[option]
    if not fn then
        vim.notify(
            "only-tmux: invalid option '"
                .. tostring(option)
                .. "'. Use one of: close, move, zoom",
            vim.log.levels.ERROR
        )
        return
    end
    fn()
end

-- invoke the dispatch function
vim.api.nvim_create_user_command("TMUXonly", function(args)
    M.dispatch(args.args)
end, {
    nargs = 1,
    desc = "Apply :only-style focus across nvim and tmux panes",
    complete = function()
        return vim.tbl_keys(actions)
    end,
})

return M
