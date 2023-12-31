local uc_content = [[
    -- controller generated by gin
    local UsersController = {}
    local Users = require 'app.models.users'

    -- login and verify token
    local jwt = require("resty.jwt")
    local Gin = require 'gin.core.gin'
    local secret = Gin.settings.jwt_secret

    --- get user info from jwt token.
    ---@param auth_header string
    ---@return table
    local function get_userinfo(auth_header)
        local token
        _, _, token = string.find(auth_header, "Bearer%s+(.+)")
        local jwt_obj = jwt:load_jwt(token)
        return jwt_obj.payload
    end
    -- list the items.
    function UsersController:list()
        local attr = self.request.uri_params or {}
        attr['is_deleted'] = 0 -- default filter
        local options = {}
        if attr.limit then
            options.limit = attr.limit
            attr.limit = nil
        end
        if attr.offset then
            options.offset = attr.offset
            attr.offset = nil
        end
        if attr.order then
            options.order = attr.order
            attr.order = nil
        end
        local users = Users.where(attr, options)
        -- TODO: add pagination
        -- local total = Users.count(attr)
        -- filter
        local items = {}
        for _, item in ipairs(users) do
            table.insert(items, item:filter())
        end
        return 200, { code = 0, msg = "success", data = items }
    end

    -- get the item by id
    function UsersController:read()
        local id = self.params.id
        if id == nil then
            return 200, { code = 1, msg = "id is empty." }
        elseif id == 'me' then
            -- get current user from authorization bearer code.
            local info = get_userinfo(self.request.headers['Authorization'])
            local user = self:accepted_params({
                "id", "username", "email", "avatar", "projects", "roles" }, info)
            return 200, { code = 0, msg = "success", data = user }
        end
        id = string.match(id, "(%d+)")
        if id == nil then
            return 200, { code = 1, msg = "id is invalid." }
        else
            id = tonumber(id)
        end
        local user = Users.find_by({ id = id, is_deleted = 0 })
        if user == nil then
            return 200, { code = 1, msg = "object not found" }
        end
        return 200, { code = 0, msg = "success", data = user:filter() }
    end

    -- update the item by id
    function UsersController:update()
        local user = Users.find_by({ id = self.params.id, is_deleted = 0 })
        if user == nil then
            return 200, { code = 1, msg = "object not found" }
        end
        local params = self.request.body
        params = self:accepted_params({ "username", "password", "email", "projects","roles" }, self.request.body)
        for k, v in pairs(params) do
            if k == 'password' then
                v = ngx.md5(v)
            end
            user[k] = v
        end
        user:save()
        return 200, { code = 0, msg = "success", data = user:filter() }
    end

    -- delete the item by id, just set is_deleted to 1, not really delete the item from database
    function UsersController:delete()
        local user = Users.find_by({ id = self.params.id, is_deleted = 0 })
        if user == nil then
            return 200, { code = 1, msg = "object not found" }
        end
        user.is_deleted = 1
        user:save()
        return 200, { code = 0, msg = "success" }
    end

    -- registered
    function UsersController:create()
        local params = self.request.body
        if params == nil or params.username == nil or params.password == nil then
            return 200, { code = 1, msg = "username or password is empty." }
        end
        params = self:accepted_params({ "username", "password", "email", "projects" }, self.request.body)
        params.password = ngx.md5(params.password)
        local new_user = Users.create(params)
        return 200, { code = 0, msg = "success", data = new_user:filter() }
    end

    -- login and return the jwt token
    function UsersController:login()
        local params = self.request.body
        if params == nil or params.username == nil or params.password == nil then
            return 200, { code = 1, msg = "username or password is empty." }
        end
        params = self:accepted_params({ "username", "password" }, self.request.body)

        local user = Users.find_by({ username = params.username, is_deleted = 0 })
        if user == nil then
            return 200, { code = 1, msg = "user not found." }
        end
        if user.password ~= ngx.md5(params.password) then
            return 200, { code = 1, msg = "password is not correct." }
        end
        -- generate jwt token
        local jwt_token = jwt:sign(
            secret,
            {
                header = { typ = "JWT", alg = "HS256" },
                payload = {
                    id = user.id,
                    username = user.username,
                    email = user.email,
                    projects = user.projects,
                    roles = user.roles,
                    avatar = user.avatar,
                    created = ngx.time(),
                    exp = ngx.time() + 3600
                }
            }
        )
        return 200, { code = 0, msg = "success", data = { token = jwt_token } }
    end

    function UsersController:logout()
        -- todo: remove token from redis/or add blacklist
        return 200, { code = 0, msg = "success" }
    end
    
    function UsersController:schemas()
        local schemas = require 'db.schemas.schemas'
        return 200, { code = 0, msg = "success", data = schemas.users }
    end
    
    return UsersController

]]

return uc_content
