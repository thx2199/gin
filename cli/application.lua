-- dep
local ansicolors = require 'ansicolors'

-- gin
local Gin = require 'gin.core.gin'
local helpers = require 'gin.helpers.common'


local gitignore = require 'gin.cli.templates.gitignore'
local errors = require 'gin.cli.templates.errors'
local routes = require 'gin.cli.templates.routes'

local application = require 'gin.cli.templates.application'
local mysql = require 'gin.cli.templates.mysql'
local nginx_config = require 'gin.cli.templates.nginx_config'
local settings = require 'gin.cli.templates.settings'
local access = require 'gin.cli.templates.access'


-- local spec_helper = [[
-- require 'gin.spec.runner'
-- ]]


local GinApplication = {}

-- hello examples
local hello_controller = [[
-- generated by gin
local HelloController = {}
function HelloController:root()
    return 200, { code = 0, message = "Hello world from Gin!" }
end
return HelloController
]]
local hello_route = [[
-- generated by gin
local routes_table = {
    {method='GET',pattern="/api/hello",route_info={ controller = "hello", action = "root" }},
}
return routes_table
]]

GinApplication.files = {
    ['.gitignore'] = gitignore,
    ['app/controllers/1/hello_controller.lua'] = hello_controller,
    ['app/routes/hello_routes.lua'] = hello_route,
    ['app/models/.gitkeep'] = "",
    ['config/errors.lua'] = errors,
    ['config/application.lua'] = "",
    ['config/nginx.conf'] = nginx_config,
    ['config/routes.lua'] = routes,
    ['config/settings.lua'] = settings,
    ['config/access.lua'] = access,
    ['db/migrations/.gitkeep'] = "",
    ['db/schemas/.gitkeep'] = "",
    ['db/mysql.lua'] = "",
    ['lib/.gitkeep'] = "",
    ['lib/api/.gitkeep '] = "",
    ['lib/api/internal/.gitkeep'] = "",
    ['init/init.lua'] = [[
-- generated by gin
if 0 == ngx.worker.id() then
   -- do something
end
    ]]
}

function GinApplication.new(name, dbuser, dbpass, dbname)
    print(ansicolors("Creating app %{cyan}" .. name .. "%{reset}..."))

    GinApplication.files['config/application.lua'] = string.gsub(application, "{{APP_NAME}}", name)
    dbname = dbname or name
    dbuser = dbuser or name
    dbpass = dbpass or ""
    GinApplication.files['db/mysql.lua'] = mysql:gsub(
        "{{DBNAME}}", dbname):gsub(
        "{{DBUSER}}", dbuser):gsub(
        "{{DBPASS}}", dbpass)
    GinApplication.create_files(name)
end

function GinApplication.create_files(parent)
    for file_path, file_content in pairs(GinApplication.files) do
        -- ensure containing directory exists
        local full_file_path = parent .. "/" .. file_path
        helpers.mkdirs(full_file_path)

        -- create file
        local fw = io.open(full_file_path, "w")
        fw:write(file_content)
        fw:close()
        print(ansicolors("  %{green}created file%{reset} " .. full_file_path))
    end
    -- 创建cli文件
    local bashes = require 'gin.cli.bashes'
    for k, v in pairs(bashes) do
        local full_file_path = parent .. "/cli/" .. k .. ".sh"
        helpers.mkdirs(full_file_path)
        local fw = io.open(full_file_path, "w")
        fw:write(v)
        fw:close()
        print(ansicolors("  %{green}created file%{reset} " .. full_file_path))
    end
end

return GinApplication