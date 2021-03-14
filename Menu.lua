Menu = Class("Menu")

function Menu:init()
    self.state = 'home'
    self.music = love.audio.newSource("music/menu.wav", "stream")
    self.music:setLooping(true)

    self.dress = suit.new()
    self.dress.theme.color = {
        normal = {bg = rgb{54, 194, 244}, fg = rgb{255, 255, 255}},
        hovered = {bg = rgb{64, 204, 254}, fg = rgb{255, 255, 255}},
        active = {bg = rgb{89, 225, 270}, fg = rgb{233, 247, 252}}
    }

    self.dress.theme.cornerRadius = 10

    self.width = 386
    self.height = 100

    -- y positioning of credits for animation
    self.creditsY = WINDOW_HEIGHT
    self.creditsTween = tween.new(10, self, {creditsY=-500})

    self.menuX = WINDOW_WIDTH / 2 - 80
    self.menuTY = WINDOW_HEIGHT / 4

    self.vsync_checkbox = {checked = appdata.vsync == 1 and true or false}
end

function Menu:resize(w, h)
    self.creditsY = h

    self.menuX = w / 2 - 80
    self.menuTY = h / 4
end

function Menu:setPrevious(func)
    self.toPrevious = func
end

function Menu:getChildPath()
    local segments = split(self.state, '/')
    if #segments <= 1 then
        return 'home'
    else
        table.remove(segments, #segments)
        return table.concat(segments, '/')
    end
end

function Menu:gotoPrevious()
    if self.toPrevious then
        self.toPrevious()
    else
        self.state = self:getChildPath()
    end
end

function Menu:isState(state, type)
    type = type or 'home'
    local segments = split(state, '/')
    if segments[1] ~= type then
        table.insert(segments, 1, type)
    end
    local path = table.concat(segments, '/')
    return path == self.state
end

function Menu:pushState(child)
    self.state = self.state .. '/' .. child
end

function Menu:popState()
    self:gotoPrevious()
end

function Menu:create_widgets(options, widget, dress)
    -- lots of stuff in here
    dress = dress or self.dress
    options = options or {}
    options.tx = options.tx or options.x or 0
    options.ty = options.ty or options.y or 0
    options.width = options.width or self.width
    options.height = options.height or self.height
    options.params = options.params or options.labels or {''}
    options.options = options.options or {}
    options.ex = options.ex or WINDOW_WIDTH
    options.ey = options.ey or WINDOW_HEIGHT
    
    -- distancing the widgets between each other for padding
    options.px = options.px or (options.ex - options.tx) / #options.params
    options.py = options.py or (options.ey - options.ty) / #options.params

    -- offset distance for widgets if specified
    options.ox = options.ox or options.xOffset or 0
    options.oy = options.oy or options.yOffset or 0

    local widgets = {}

    options.align = options.align or options.alignment

    local align = split(options.align, ' ')

    local haligns = {'left', 'center', 'right'}
    local valigns = {'top', 'center', 'bottom'}

    if table.find(haligns, align[1]) then
        options.halign = align[1]
        if table.find(valigns, align[2]) then
            options.valign = align[2]
        end
    elseif table.find(haligns, align[2]) then
        options.halign = align[2]
        if table.find(valigns, align[1]) then
            options.valign = align[1]
        end
    end

    options.halign = options.halign or align[1]
    options.valign = options.valign or align[2]
    
    if options.align == "center" then
        options.valign = "center"
    end

    -- alignment on x and y axes
    if options.halign == "center" then
        options.tx = options.ex / 2 - options.width / 2 + options.px
    elseif options.halign == "left" then
        options.tx = 0
    elseif options.halign == "right" then
        options.tx = options.ex - ((options.width + options.px / 2) * #options.params) + options.px / 2
    end
    
    if options.valign == "center" then
        options.ty = options.ey / 2 - ((options.height + options.py / 2) * #options.params) / 2 + options.py
    elseif options.valign == "top" then
        options.ty = 0
    elseif options.valign == "bottom" then
        options.ty = options.ey - ((options.height + options.py / 2) * #options.params) + options.py / 2
    end

    options.tx = math.min(options.tx, options.ex)
    options.ty = math.min(options.ty, options.ey)

    -- reset layout with values
    dress.layout:reset(options.tx, options.ty, options.px / 2, options.py / 2)

    local row = 0
    local x, y, w, h

    --local maxHorizontal = #options.params // ((options.height + options.py) * #options.params)
    if type(widget) == "string" then
        if string.lower(widget) == "button" then
            widget = dress.Button
        elseif string.lower(widget) == "label" then
            widget = dress.Label
        end
    elseif type(widget) == "table" then
        if getmetatable(widget) then
            widget = widget
        end
    end
    if not widget then
        error("Invalid widget: " .. widget)
        return
    end

    for i, v in ipairs(options.params) do
        x, y, w, h = dress.layout:row(options.width, options.height)
        
        if y >= options.ey then
            row = 1
        else
            row = row + 1
        end
        
        widgets[v] = widget(dress, v, table.copy(options.options), x + options.ox * i, y + options.oy * i, w, h)
    end
    return widgets
end

function Menu:create_buttons(options, dress)
    dress = dress or self.dress
    return self:create_widgets(options, dress.Button)
end

function Menu:create_labels(options, dress)
    dress = dress or self.dress
    return self:create_widgets(options, dress.Label)
end

function Menu:display_credits()
    if (self.creditsTween == nil) and self:isState('credits') then
        self.creditsTween = tween.new(10, self, {creditsY=-500})
    end
    applyFont(mediumFont)
    local scale = 1.25
    love.graphics.printf(CREDITS, self.menuX, self.creditsY, WINDOW_WIDTH - self.menuX, "center", 0, scale, scale)
    removeFont()
end

function Menu:display(dt)
    applyFont(coolFont)
    self.music:setVolume(appdata.MASTER_VOLUME * appdata.MENU_VOLUME)
    if self:isState('home') then
        buttons = self:create_buttons{
            x = self.menuX,
            y = self.menuTY,
            params = {
                "Play",
                "Options",
                "Credits",
                "Quit"
            },
            width = self.width,
            height = self.height,
            align='center',
            py = 50
        }

        if buttons["Play"].hit then
            self:pushState('play')
        end
        if buttons["Options"].hit then
            self:pushState('options')
        end
        if buttons["Credits"].hit then
            self:pushState('credits')
        end
        if buttons["Quit"].hit then
            love.event.quit()
        end
    elseif self:isState('home/credits') then
        -- updates the credits tween and resets when done
        if self.creditsTween then
            if self.creditsTween:update(dt) then
                self.creditsTween = nil
                self.creditsY = WINDOW_HEIGHT
            end
        end

        local text = "Back"
        local x = self.menuX + (WINDOW_WIDTH - self.menuX) / 2 - (coolFont:getWidth(text) / 2)
        local back_button = self.dress:Button(text, x, self.menuTY + 450, 300, 75)

        if back_button.hit then
            self:popState()
        end
    elseif self:isState('home/options') then
        buttons = self:create_buttons{
            x = self.menuX,
            y = self.menuTY,
            params = {
                "Audio",
                "Video",
                "Controls",
                "Back"
            },
            width = self.width,
            height = self.height,
            align='center',
            py = 50
        }
        if buttons["Audio"].hit then
            self:pushState('audio')
        end
        if buttons["Video"].hit then
            self:pushState('video')
        end
        if buttons["Controls"].hit then
            self:pushState('controls')
        end
        if buttons["Back"].hit then
            self:popState()
        end
    elseif self:isState('home/options/audio') then
        local px, py, tx, ty
        local ex = WINDOW_WIDTH
        local ey = WINDOW_HEIGHT

        px = (ex - self.menuX) / 8
        py = (ey - self.menuTY) / 5

        tx = ex / 2 - self.width / 2 + px * 2
        ty = ey / 2 - ((self.height + py / 2) * 6) / 2 + py * 2

        tx = math.min(tx, ex)
        ty = math.min(ty, ey)
        
        
        -- audio settigns
        self.dress.layout:reset(tx, ty, px / 4, py / 8)

        -- label with slider beneath for master volume
        print("the appdata mv is", appdata.MASTER_VOLUME)
        master_label = self.dress:Label("Master", self.dress.layout:row(self.width, 30))
        master_slider = {min=0, max=1, step=0.1, value=appdata.MASTER_VOLUME}
        self.dress:Slider(master_slider, self.dress.layout:row())
        appdata.MASTER_VOLUME = round(master_slider.value, 1)

        -- adding a new blank row
        self.dress.layout:down()

        -- new label and slider for menu volume on a new row
        menu_label = self.dress:Label("Menu", self.dress.layout:row())
        menu_slider = {min=0, max=1, step=0.1, value=appdata.MENU_VOLUME}
        self.dress:Slider(menu_slider, self.dress.layout:row())
        appdata.MENU_VOLUME = round(menu_slider.value, 1)

        -- another blank row
        self.dress.layout:down()

        -- another label and slider for game volume on the next row
        game_label = self.dress:Label("Game", self.dress.layout:row())
        game_slider = {min=0, max=1, step=0.1, value=appdata.GAME_VOLUME}
        self.dress:Slider(game_slider, self.dress.layout:row())
        appdata.GAME_VOLUME = round(game_slider.value, 1)

        -- ANOTHER blank row
        self.dress.layout:down()

        back_button = self.dress:Button("Back", self.dress.layout:row(self.width, self.height))

        -- back button that goes to previous menu state
        if back_button.hit then
            self:popState()
        end
    elseif self:isState('home/options/video') then
        local px, py, tx, ty
        local ex = WINDOW_WIDTH
        local ey = WINDOW_HEIGHT

        px = (ex - self.menuX) / 10
        py = (ey - self.menuTY) / 5

        tx = ex / 2 - self.width / 2 + px * 2
        ty = ey / 2 - ((self.height + py / 2) * 6) / 2 + py * 2

        tx = math.min(tx, ex)
        ty = math.min(ty, ey)
        
        
        -- audio settigns
        -- video settings
        
        self.dress.layout:reset(self.menuX + 50, self.menuTY)
        self.dress.layout:reset(tx, ty, px / 4, py / 8)

        -- vsync
        self.dress:Label("Enable Vsync", self.dress.layout:row(250, 50))
        self.dress:Checkbox(self.vsync_checkbox, self.dress.layout:col())

        -- set the window vsync to the value of the checkbox
        appdata.vsync = self.vsync_checkbox.checked and 1 or 0

        self.dress.layout:left()

        -- Window mode
        self.dress:Label("Window Mode", self.dress.layout:row())
        local windowmode_label = self.dress:Button(appdata.windowmode, {font=largeFont, valign="top"}, self.dress.layout:col(225, string.len(appdata.windowmode) > 10 and 90 or 40))
        local wm = table.find(windowmodes, appdata.windowmode, true) -- search case-insensitively

        --[[ in the event of the window mode not being found,
        set it to the first window mode]]

        if not wm then
            wm = 1
        end

        if windowmode_label.hit then
            -- if hit then increase the window mode index
            wm = wm + 1

            --[[if it has reached past the amount of windowmodes
            then it needs to cycle back]]
                if wm > #windowmodes then
                    wm = 1
                elseif wm < 1 then
                wm = #windowmodes
            end

            appdata.windowmode = windowmodes[wm]
        end

        local apply_button = self.dress:Button("Apply", tx + 250, self.menuTY + 400, 100, 35)

        if apply_button.hit then
            love.window.setVSync(appdata.vsync)
            update_window()
        end

        -- and another back button
        local back_button = self.dress:Button("Back", tx + 75, self.menuTY + 450, 300, 75)
        if back_button.hit then
            self:popState()
        end
    elseif self:isState('home/options/controls') then
        controls_display:display(
            self.menuX,
            self.menuTY,
            175, 40, 150,
            self.menuTY + 420
        )
    end
    removeFont()
end

function Menu:render()
    if self:isState('credits') then
        self:display_credits()
    end
    self.dress:draw()

    local x = WINDOW_WIDTH / 2 - 140
    love.graphics.setColor(rgb{213, 217, 222, 112})
    love.graphics.line(x, 0, x, WINDOW_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(self.menuX - 10, self.menuTY, self.menuX + 10, self.menuTY)
    love.graphics.line(self.menuX, self.menuTY - 10, self.menuX, self.menuTY + 10)
    love.graphics.print("(x, ty)", self.menuX - 52, self.menuTY - 32, 0, 2, 2)

end

function Menu:update(dt)
    self:display(dt)
end