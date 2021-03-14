Controls = Class("Controls")

function Controls:init(filename, defaults)
    self.input = Input(true)
    self.listening = false
    self.actions = {}
    self.key_pressed = {}
    self.key_released = {}
    self.mouse_pressed = {}
    self.gamepad_pressed = {}
    self.inputs_pressed = {}
    self.limits = {}
    self.keys_bount = {}
    self.filename = filename or ("controls" .. EXT)
    self:bind('escape', "INPUT_ESCAPE")
    self:bind('delete', "INPUT_DELETE")
    self.defaults = defaults
    if love.filesystem.getInfo(self.filename, 'file') then
        self:load(self.filename)
    else
        self:restoreDefaults()
    end
end

function Controls:setActions(actions)
    -- Set actions that are available to bind
    self.actions = actions
end

function Controls:hasAction(action)
    -- Return whether an action has been bount
    return table.contains(self:getActions(), action)
end

function Controls:usingKey(key)
    for action, keys in pairs(self.input.binds) do
        if table.contains(keys, key) then
            return action
        end
    end
end

function Controls:getActions()
    local actions = {}
    for action, _ in pairs(self.input.binds) do
        table.insert(actions, action)
    end
    return actions
end

function Controls:restoreDefaults()
    -- Bind the default keys
    self:unbindAll()
    for action, keys in pairs(self.defaults) do
        self:bind(keys, action)
    end
end

function Controls:hookup()
    local functions = {
        'keypressed',
        'keyreleased',
        'mousepressed',
        'mousereleased',
        'gamepadpressed',
        'gamepadreleased',
        'gamepadaxis',
        'wheelmoved',
        'update'
    }

    for _, handler in ipairs(functions) do
        -- Modify each handler by also executing handler from Input
        local self_func = self[handler]
        self[handler] = function(...)
            self.input[handler](self, ...)
            if self_func then self_func(...) end
        end
    end
end

function Controls:_clear_inputs()
    self.key_pressed = {}
    self.key_released = {}
    self.mouse_pressed = {}
    self.gamepad_pressed = {}
    self.inputs_pressed = {}
end

function Controls:grab(action, callback, extra_callbacks)
    if table.contains(self.actions, action) then return end
    extra_callbacks = type(extra_callbacks) == 'table' and extra_callbacks or {extra_callbacks}
    if type(callback) == 'string' then callback = load(callback) end
    if not self.listening then
        -- Initialise variables to start listening
        self.listening = true
        self.listening_action = action
        self.listening_callback = callback or function() end
        self.on_already_bount_callback = type(extra_callbacks['on_already_bount']) == 'function' and extra_callbacks['on_already_bount']
        self.on_escape_callback = type(extra_callbacks['on_escape']) == 'function' and extra_callbacks['on_escape'] or function()end
        self.on_delete_callback = type(extra_callbacks['on_delete']) == 'function' and extra_callbacks['on_delete'] or function()end
        self:_clear_inputs()
    end
end

function Controls:unbindAction(action)
    if self.input.binds[action] then
        -- Remove all functions for action
        for i = 1, #self.input.binds[action] do
            if self.input.functions[self.input.binds[action][i]] then
                self.input.functions[self.input.binds[action][i]] = nil
            end
        end

        -- Clear bindings
        self.input.binds[action] = {}
    end
end

function Controls:update(dt)
    if self.listening and self.listening_action then
        local key
        local num_inputs = #self.inputs_pressed
        if self:isPressed("INPUT_DELETE") then
            -- If delete was pressed, unbind the action and stop listening
            self.listening = false
            self.on_delete_callback()
            self:_clear_inputs()
            self:unbindAction(self.listening_action)
        elseif self:isPressed("INPUT_ESCAPE") then
            self.listening = false
            self.on_escape_callback()
            self:_clear_inputs()
        elseif num_inputs > 0 then
            key = self.inputs_pressed[num_inputs]
            local already_bount
            if table.contains(self:getBindings("INPUT_DELETE"), key) then
                self:unbindAction(self.listening_action)
            else
                if self.on_already_bount_callback then
                    already_bount = self:usingKey(key)
                end
                if not already_bount then
                    -- Bind the key if not already bount to another action
                    self:unbindAction(self.listening_action)
                    self:bind(key, self.listening_action)
                    self.listening_callback(key)
                end
            end
            self.listening = false
            if already_bount then
                self.on_already_bount_callback(already_bount, key)
            end
            self:_clear_inputs()
        end
        local bindings = self:getBindings(self.listening_action)
        if bindings then
            if #bindings > 1 then
                -- Constrain the amount of keys to 1
                self.input.binds[self.listening_action] = {self.input.binds[1]}
                self:_clear_inputs()
            end
        end
    end
end

function Controls:wasPressed(key)
    if table.contains(self.key_pressed, key) then
        return true
    else
        return false
    end
end

function Controls:wasReleased(key)
    if table.contains(self.key_released, key) then
        return true
    else
        return false
    end
end

function Controls:keypressed(key)
    table.insert(self.key_pressed, key)
    table.insert(self.inputs_pressed, key)
end

function Controls:keyreleased(key)
    table.insert(self.key_released, key)
end

function Controls:mousepressed(x, y, button)
    local key = self.input.button_to_key[button]
    table.insert(self.mouse_pressed, key)
    -- table.insert(self.inputs_pressed, key) -- so it doesn't get grabbed
end

function Controls:gamepadpressed(joystick, button)
    local gamepad = self.input.button_to_gamepad[button]
    table.insert(self.gamepad_pressed, gamepad)
    table.insert(self.inputs_pressed, gamepad)
end

function Controls:gamepadaxis(joystick, axis, value)
    axis = self.input.button_to_axis[axis]
    table.insert(self.joystick_pressed, axis)
    table.insert(self.inputs_pressed, axis)
end

function Controls:bind(key, action)
    self.input:bind(key, action)
end

function Controls:unbind(key)
    if type(key) == 'table' then
        for _, key in ipairs(key) do
            self.input:unbind(key)
        end
    else
        self.input:unbind(key)
    end
end

function Controls:unbindAll()
    self.input:unbindAll()
    self:bind('escape', "INPUT_ESCAPE")
    self:bind('delete', "INPUT_DELETE")
end

function Controls:getBinding(action)
    return self.input.binds[action][1]
end

function Controls:getBindings()
    local bindings = {}
    for action, t in pairs(self.input.binds) do
        bindings[action] = t[1]
    end
    return bindings
end

function Controls:isDown(action, interval, delay)
    return self.input:down(action, interval, delay)
end

function Controls:isPressed(action)
    return self.input:pressed(action)
end

function Controls:isReleased(action)
    return self.input:released(action)
end

function Controls:isSequence(...)
    return self.input:sequence(...)
end

function Controls:save(filename)
    self.filename = filename or self.filename
    self:writeTo(self.filename)
end

function Controls:writeTo(filename)
    if filename then
        return love.filesystem.write(filename, self:encode())
    end
    return 1
end

function Controls:load(filename)
    local decoded_table = self:decode(love.filesystem.read(filename))
    local binds = self:decode(decoded_table[1])
    local functions = self:decode(decoded_table[2])
    self.input.binds = binds
    self.input.functions = functions
end

function Controls:encode()
    -- serialising the items in the table, then serialising the table
    return binser.serialize({binser.serialize(self.input.binds), binser.serialize(self.input.functions)})
end

function Controls:decode(str)
    return binser.deserialize(str)[1]
end