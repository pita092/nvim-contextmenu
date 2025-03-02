local api = vim.api
local buffer = nil
local window = nil

local M = {}
local function set_highlight_groups()
	vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#fabd2f", bold = true })
	vim.api.nvim_set_hl(0, "DashboardOption", { fg = "#fbf1c7" })
	vim.api.nvim_set_hl(0, "DashboardShortcut", { fg = "#fe8019", bold = true })
end

function M.close_dashboard_and_clean_up()
	if window and api.nvim_win_is_valid(window) then
		api.nvim_win_close(window, true)
	end
	if buffer and api.nvim_buf_is_valid(buffer) then
		api.nvim_buf_delete(buffer, { force = true })
	end
	window = nil

	buffer = nil
	vim.api.nvim_del_augroup_by_name("DashboardAutoClose")
end

function M.setup_auto_close()
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CmdlineEnter", "CmdwinEnter" }, {
		group = vim.api.nvim_create_augroup("DashboardAutoClose", { clear = true }),
		callback = close_dashboard_and_clean_up,
	})
end

vim.api.nvim_create_autocmd({
	"WinEnter",
	"FileType",
	"BufWinEnter",
	"CmdlineEnter",
	"CmdwinEnter",
	"FocusGained",
	"VimResized",
	"TabEnter",
	"TermOpen",
}, {
	group = vim.api.nvim_create_augroup("DashboardAutoClose", { clear = true }),
	callback = function(ev)
		-- Don't close if we're still in the dashboard buffer
		if ev.buf ~= buffer then
			close_dashboard_and_clean_up()
		end
	end,
})

function M.handle_mouse_click()
	if buffer and api.nvim_get_current_buf() ~= buffer then
		close_dashboard_and_clean_up()
	end
end

vim.on_key(function(key)
	if key == vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true) then
		vim.schedule(handle_mouse_click)
	end
end)
function M.close_dashboard()
	if window and api.nvim_win_is_valid(window) then
		api.nvim_win_close(window, true)
	end
	if buffer and api.nvim_buf_is_valid(buffer) then
		api.nvim_buf_delete(buffer, { force = true })
	end
	window = nil
	buffer = nil
end

function M.create_dashboard()
	buffer = api.nvim_create_buf(false, true)

	local content = {
		"Context Menu",
		"",
		"[e] New file",
		"[f] Find file",
		"[r] Recent files",
		"[s] Settings",
		"",
	}
	api.nvim_buf_set_lines(buffer, 0, -1, false, content)

	local ns_id = api.nvim_create_namespace("dashboard")
	api.nvim_buf_add_highlight(buffer, ns_id, "DashboardHeader", 0, 0, -1)
	for i = 2, #content - 1 do
		api.nvim_buf_add_highlight(buffer, ns_id, "DashboardOption", i, 3, -1)
		api.nvim_buf_add_highlight(buffer, ns_id, "DashboardShortcut", i, 0, 3)
	end
	-- Calculate dimensions
	local width = #content[1] + 4 -- Add some padding
	local height = #content + 2 -- Add some padding

	-- Get editor dimensions
	local editor_width = api.nvim_get_option("columns")
	local editor_height = api.nvim_get_option("lines")

	-- Calculate position (centered)
	local row = math.ceil((editor_height - height) / 2 - 1)
	local col = math.ceil((editor_width - width) / 2)

	-- Set window options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "single",
	}

	-- Create window
	window = api.nvim_open_win(buffer, true, opts)

	-- Set buffer options
	api.nvim_buf_set_option(buffer, "modifiable", false)
	api.nvim_buf_set_option(buffer, "buftype", "nofile")
	api.nvim_buf_set_option(buffer, "filetype", "dashboard")

	-- Set keymaps
	function M.set_keymap(key, action)
		api.nvim_buf_set_keymap(buffer, "n", key, action, { silent = true, noremap = true })
	end

	set_keymap("e", ':lua require("pita.dashboard").new_file()<CR>')
	set_keymap("f", ':lua require("pita.dashboard").telescope_findfiles()<CR>')
	set_keymap("r", ':lua require("pita.dashboard").telescope_oldfiles_in_new_tab()<CR>')
	set_keymap("s", ":tabnew lua/pita/init.lua <CR>")
end

function M.telescope_oldfiles_in_new_tab()
	close_dashboard() -- Close the dashboard before opening the new tab
	vim.cmd("tabnew") -- Open a new tab
	require("telescope.builtin").oldfiles() -- O
end

function M.telescope_findfiles()
	close_dashboard()
	vim.cmd("tabnew")
	require("telescope.builtin").find_files()
end

function M.toggle_dashboard()
	set_highlight_groups()
	if window and api.nvim_win_is_valid(window) then
		close_dashboard()
		return false -- Dashboard was closed
	else
		create_dashboard()
		setup_auto_close()
		return true -- Dashboard was opened
	end
end

function M.new_file()
	close_dashboard()
	vim.cmd("enew")
end

function M.CloseDashboard()
	close_dashboard()
end

vim.api.nvim_create_user_command("Dashboard", M.toggle_dashboard, {})
vim.api.nvim_create_user_command("CloseDashboard", M.CloseDashboard, {})

return M
