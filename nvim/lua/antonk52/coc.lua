local function has_eslint()
    for _,name in pairs({'.eslintrc.js', '.eslintrc.json', '.eslintrc'}) do
        if vim.fn.globpath('.', name) ~= '' then
            return true
        end
    end
end

-- lookup local flow executable
-- and turn on flow for coc is executable exists
local function setup_flow()
    local has_flowconfig = vim.fn.filereadable('.flowconfig')
    if has_flowconfig == 0 then
        return false
    end
    local flow_path = 'node_modules/.bin/flow'
    local has_flow = vim.fn.filereadable(flow_path)
    if has_flow == 0 then
        return false
    end
    local flow_bin = vim.fn.getcwd() .. '/' .. flow_path
    local flow_config = {
        ['command'] = flow_bin,
        ['args'] = { 'lsp' },
        ['filetypes'] = { 'javascript', 'javascriptreact' },
        ['initializationOptions'] = {},
        ['requireRootPattern'] = 1,
        ['settings'] = {},
        ['rootPatterns'] = { '.flowconfig' }
    }
    vim.fn['coc#config']('languageserver.flow', flow_config)
    return true
end


local function setup()
    vim.g.coc_global_extensions = {
        'coc-css',
        'coc-cssmodules',
        'coc-eslint',
        'coc-json',
        'coc-prettier',
        'coc-rust-analyzer',
        'coc-stylelintplus',
        'coc-tsserver',
    }

    vim.g.coc_filetype_map = {
        ['javascript.jest'] = 'javascript',
        ['javascript.jsx.jest'] = 'javascript.jsx',
        ['typescript.jest'] = 'typescript',
        ['typescript.tsx.jest'] = 'typescript.tsx',
    }

    -- let coc use a newer nodejs version
    -- since I have to continuously switch between older ones
    local local_latest_node = '/usr/local/n/versions/node/16.3.0/bin/node'
    if vim.fn.filereadable(local_latest_node) then
        vim.g.coc_node_path = local_latest_node
    end

    vim.api.nvim_set_keymap(
        'n',
        '<leader>t',
        ':lua require("antonk52.coc").show_documentation()<cr>:echo<cr>',
        {noremap = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        'J',
        'coc#float#has_float() == 1 ? coc#float#scroll(1) : "J"',
        {noremap = true, expr = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        'K',
        ':lua require("antonk52.coc").show_documentation()<cr>:echo<cr>',
        {noremap = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        '<leader>R',
        ':silent CocRestart<CR>',
        {noremap = true}
    )

    local has_flow_config = setup_flow()
    local has_eslint_config = has_eslint()
    -- turn off eslint when cannot find eslintrc
    vim.fn['coc#config']('eslint.enable', has_eslint_config)
    vim.fn['coc#config']('eslint.autoFixOnSave', has_eslint_config)
    -- essentially avoid turning on typescript in a flow project
    vim.fn['coc#config']('tsserver.enableJavascript', not has_flow_config)
    -- lazy coc settings require restarting coc to pickup newer configuration
    vim.fn['coc#client#restart_all']()

    vim.cmd([[
        redraw!
        autocmd CursorHold * silent call CocActionAsync('highlight')
        command! Prettier call CocAction('runCommand', 'prettier.formatFile')
        " useful in untyped utilitarian corners in flow projects, sigh
        command! CocTsserverForceEnable call coc#config('tsserver.enableJavascript', 1)
        command! CocTsserverForceDisable call coc#config('tsserver.enableJavascript', 0)
    ]])

    local mappings = {
        ['gd'] = 'definition',
        ['gy'] = 'type-definition',
        ['gi'] = 'implementation',
        ['gr'] = 'references',
        ['<leader>['] = 'diagnostic-prev',
        ['<leader>]'] = 'diagnostic-next',
        ['<leader>r'] = 'rename'
    }
    for mapping,action in pairs(mappings) do
        vim.api.nvim_set_keymap(
            'n',
            mapping,
            '<Plug>(coc-'..action..')',
            {silent = true}
        )
    end
end

local function lazy_setup()
    vim.defer_fn(setup, 2000)
end

local function show_documentation()
    if vim.fn["coc#float#has_float"]() == 1 then
        vim.fn["coc#float#scroll"](0)
        return nil
    end
    if vim.o.filetype == 'vim' or vim.o.filetype == 'help' then
        vim.cmd('h '..vim.fn.expand('<cword>'))
    else
        vim.cmd('call CocAction("doHover")')
    end
end

return {
    setup = setup,
    lazy_setup = lazy_setup,
    show_documentation = show_documentation,
}
