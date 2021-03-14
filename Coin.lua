Coin = Class("Coin")

function Coin:init(x, y)
    self.x = x
    self.y = y
    self.width = 1
    self.height = 1
    self.show = false
    self.image = love.graphics.newImage("graphics/coin.png")
end

function Coin:render()
    if self.show then
        love.graphics.draw(self.image, self.x, self.y, 0.025, 0.025)
    end
end