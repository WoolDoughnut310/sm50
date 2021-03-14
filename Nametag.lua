Nametag = Class("Nametag")

function Nametag:init(source, name, alpha)
    self.source = source
    self.colour = self.source.colour
    self.name = name
    self.alpha = alpha or 1
    self.show = true
    self.x = self.source.x - (self.source.width * 12.2)
    self.y = self.source.y
end

function Nametag:update(dt)
    self.colour = self.source.colour
    self.x = self.source.x - (self.source.width * 12.2)
    self.y = self.source.y
end

function Nametag:render()
    if self.show then
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(self.colour, self.alpha)
        love.graphics.printf(self.name, self.x, self.y, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end
end