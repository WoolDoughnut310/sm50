ControlsDisplay = Class("ControlsDisplay")

function ControlsDisplay:init(game, menu)
    self.game = game
    self.menu = menu
    self.listening = false
    self.tab_width = 80
    self.tab_height = 80
    self.button_size = 90
    self.keys = {'jump', 'left', 'right', 'crouch', 'shoot'}
    self.currentTab = 1
    self.tabs = {'P1', 'P2', 'P3', 'P4'}
    self.dress = self.menu.dress
    self:initialise()
    self.default_colour = self.dress.theme.color
    self.faded_colour = self:getDarkerColour()
end

function ControlsDisplay:initialise(tx, ty)
    if (tx == self.tx) and (ty == self.ty) then return end

    self.tx = tx
    self.ty = ty

    self.min_width = (WINDOW_WIDTH - self.tx) / 2.5
    self.tab_tx = self.tx + (WINDOW_WIDTH - self.tx) / 2 - self.min_width / 2

    
    self.tab_columns = {
        min_width = self.min_width,
        pos = {self.tab_tx, self.ty},
        padding = {10, nil},
        {'fill', self.tab_height},
        {'fill'},
        {'fill'},
        {'fill'}
    }
    
    self.tab_column_definition = self.dress.layout:cols(self.tab_columns)
    
    for i, cell in ipairs(self.tab_column_definition) do
        local destination = {[2] = cell[2]} -- save cell y position
        cell[2] = -cell[4] -- move cell just outside of the screen
        
        -- let the cells fall into the screen one after another
        Timer.after(i / 10, function()
            Timer.tween(0.7, cell, destination, 'bounce')
        end)
    end

    self.min_height = (WINDOW_HEIGHT - self.ty) / 3
    self.button_row_width = (WINDOW_WIDTH - self.tx) / 1.75
    self.button_ty = self.ty + (WINDOW_HEIGHT - self.ty) / 2 - self.min_height
    
    self.button_rows = {
        min_height = self.min_height,
        pos = {self.tx, self.button_ty},
        padding = {nil, 30},
        {self.button_row_width, 'fill'},
        {nil, 'fill'},
        {nil, 'fill'},
    }
    
    --[[ TODO: Make 3 rows of 3 columns (9 cells) by iterating
        through each row and then each column and filling the
        space with a circle button (radius = width / 2) and
        making a rectangular button if on cell no. 5
    ]]

    self.button_columns = {
        min_width = self.tab_width * 1.5,
    }
end

function ControlsDisplay:getDarkerColour()
    local colour = {normal = {bg = {}, fg = {}}, hovered = {bg = {}, fg = {}}, active = {bg = {}, fg = {}}}
    for i1, t in pairs(self.default_colour) do
        for i2, f in pairs(t) do
            for i3, v in ipairs(f) do
                colour[i1][i2][i3] = math.max(0, v - (40 / 255))
            end
        end
    end
    return colour
end

function ControlsDisplay:display(tx, ty, w, h, by, ey)
    self.tab_width = w
    self.tab_height = h
    by = by or self.tab_width

    local binding
    local labels = {}
    local player = self.game.players[self.currentTab]

    for i, key in ipairs(self.keys) do
        binding = player.controls:getBinding(key)
        table.insert(labels, binding)
    end

    applyFont(coolFont)

    local colour
    local tab_buttons = {}

    self:initialise(tx, ty)

    for i, x, y, width, height in self.tab_column_definition() do
        if i ~= self.currentTab then
            colour = self.faded_colour
        else
            colour = self.default_colour
        end
        table.insert(tab_buttons, self.dress:Button(self.tabs[i], {color = colour}, x, y, width, height))
    end

    for i, button in ipairs(tab_buttons) do
        if button.hit then
            self.currentTab = i
        end
    end
    
    removeFont()

    applyFont(largeFont)

    self.dress.layout:reset(tx, ty, 30, 40)

    self.dress.layout:right(self.button_size, self.button_size)
    self.dress:Button("", {cornerRadius = self.button_size / 2}, self.dress.layout:col())
    self.dress.layout:down()
    self.dress.layout:left()
    self.dress.layout:left()
    self.dress:Button("", {cornerRadius = self.button_size / 2}, self.dress.layout:col())
    self.dress:Button("", {cornerRadius = self.button_size / 2}, self.dress.layout:col())
    self.dress:Button("", {cornerRadius = self.button_size / 2}, self.dress.layout:col())
    self.dress.layout:down()
    self.dress.layout:left()
    self.dress.layout:left()
    self.dress:Button("", {cornerRadius = self.button_size / 2}, self.dress.layout:col())

    -- local buttons = self.menu:create_buttons{
    --     x = tx,
    --     y = ty,
    --     params = self.keys,
    --     width = self.tab_width,
    --     height = self.tab_height,
    --     ey = ey or self.control.menu.menuTY
    -- }
    removeFont()
    return buttons
end

function ControlsDisplay:update(dt) end
function ControlsDisplay:render() end