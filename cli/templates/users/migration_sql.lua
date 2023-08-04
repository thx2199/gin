local sql_str = [===[
-- generated by gin
local SqlMigration = {}
-- specify the database used in this migration (needed by the Gin migration engine)
SqlMigration.db = require 'db.mysql'
function SqlMigration.up()
    -- Run your migration
    SqlMigration.db:execute([[
        CREATE TABLE `users`(
            `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
            `username` varchar(255) NOT NULL UNIQUE COMMENT '账号',
            `password` varchar(255) NOT NULL COMMENT '密码',
            `email` varchar(255) DEFAULT NULL COMMENT '邮箱',
            `projects` varchar(255) DEFAULT NULL COMMENT '项目',
            `roles` varchar(64) DEFAULT 'USER' COMMENT '角色',
            `avatar` varchar(255) DEFAULT NULL COMMENT '头像',
            `is_deleted` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
            `CreatedTime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `UpdatedTime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`) );
        ]])
end
function SqlMigration.down()
    -- Run your rollback
    SqlMigration.db:execute([[
        DROP TABLE `users`;
        ]])
end
return SqlMigration
]===]

return sql_str