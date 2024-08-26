vim.api.nvim_create_user_command('Dashboard', function()
    require('dashboard').toggle_dashboard()
end, {})

vim.api.nvim_create_user_command('CloseDashboard', function()
    require('dashboard').CloseDashboard()
end, {})

