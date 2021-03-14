Hearts = Class("Hearts")

local constant = 10

function Hearts:init(source)
    self.source = source
    self.colour = self.source.colour
    self.alpha = 1
    self.show = false
    self.image = love.graphics.newImage('graphics/heart.png')
end

function Hearts:update(dt)
    self.colour = self.source.colur
end

function Hearts:render()
    local xpos = self.source.x - (self.source.lives / 2 * constant) + (self.source.width / 2)
    local y = self.source.y - (self.source.height * 0.8)
    if self.show then
        for x = 0, self.source.lives - 1 do
            love.graphics.setColor(self.colour, self.alpha)
            love.graphics.draw(self.image, xpos + (x * constant), y, 0, 0.3, 0.3)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end