local model_content = [[
-- generated by gin
local MySql = require 'db.mysql'
local SqlOrm = require 'gin.db.sql.orm'
    
-- define
return SqlOrm.define_model(MySql, '{{MNAME}}', {'is_deleted','CreatedTime','UpdatedTime'})
]]
return model_content