-- dep
local dbi = require 'DBI'

-- gin
local Gin = require 'gin.core.gin'
local helpers = require 'gin.helpers.common'

-- perf
local assert = assert
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable
local smatch = string.match
local tonumber = tonumber
local function tappend(t, v) t[#t+1] = v end
local function dappend(dict,k,v)
   dict[k] = v
end
local MySql = {}
MySql.default_database = 'mysql'

local function mysql_connect(options)
    local db = assert(dbi.Connect("MySQL", options.database, options.user, options.password, options.host, options.port))
    db:autocommit(true)

    return db
end

local function mysql_close(db)
    db:close()
end

-- quote
function MySql.quote(options, str)
    local db = mysql_connect(options)
    local quoted_str = "'" .. db:quote(str) .. "'"
    mysql_close(db)
    return quoted_str
end

-- return list of tables
function MySql.tables(options)
    local res = MySql.execute(options, "SHOW TABLES IN " .. options.database .. ";")

    local tables = {}

    for _, v in pairs(res) do
        for _, table_name in pairs(v) do
            tappend(tables, table_name)
        end
    end

    return tables
end

-- return schema as a table
function MySql.schema(options)
    local Migration = require 'gin.db.migrations'
    local schema = {}

    local tables = MySql.tables(options)
    for i, table_name in ipairs(tables) do
        if table_name ~= Migration.migrations_table_name then
            local columns_info = MySql.execute(options, "SHOW FULL COLUMNS IN " .. table_name .. ";")
            local columns = {}
            for _, column_info in ipairs(columns_info) do
                columns[column_info.Field] = {
                    type = column_info.Type,
                    default = column_info.Default,
                    null = column_info.Null == 'YES',
                    key = column_info.Key,
                    extra = column_info.Extra,
                    comment = column_info.Comment
                }
            end
            dappend(schema, table_name ,columns)
        end
    end
    return schema
end

-- execute query on db
local function db_execute(db, sql)
    -- execute
    local sth = assert(db:prepare(sql))
    local ok, err = sth:execute()
    if ok == false then error(err) end
    -- get first returned row (if any)
    local ok, row = pcall(function() return sth:fetch(true) end)
    if ok == false then row = nil end
    return sth, row
end

-- execute a query
function MySql.execute(options, sql)
    -- connect
    local db = mysql_connect(options)
    -- execute
    local sth, row = db_execute(db, sql)
    if row == nil then return {} end
    -- build res
    local res = {}
    while row do
        local irow = helpers.shallowcopy(row)
        tappend(res, irow)
        row = sth:fetch(true)
    end
    -- close
    sth:close()
    mysql_close(db)
    -- return
    return res
end


-- execute a query and return the last ID
function MySql.execute_and_return_last_id(options, sql, id_col)
    -- connect
    local db = mysql_connect(options)
    -- execute sql
    local sth, row 
    sth, row = db_execute(db, sql)
    sth:close()
    -- get last id
    sth, row = db_execute(db, "SELECT BINARY LAST_INSERT_ID() AS " .. id_col .. ";")
    local id = row and row[id_col] or nil
    -- close
    sth:close()
    mysql_close(db)
    -- return
    return tonumber(id)
end

return MySql
