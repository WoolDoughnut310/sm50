Blast = Class("Blast")
local SPEED = 200

function Blast:init(map, source, size, damage)
    self.source = source
    self.size = size
    self.map = map
    self.x = source.x
    self.y = source.y
    self.width = self.size
    self.height = self.size
    self.show = false
end

function Blast:align()
    self.x = self.source.x
    self.y = self.source.y
    self.dx = (self.source.direction == 'left') and -SPEED or SPEED
    self.dy = 0
end

local wait = 0

function Blast:update(dt)
    self:checkCollision()
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    wait = wait + dt
    if wait > 10 then
        wait = wait - 10
        self:reset()
    end
end

function Blast:checkCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        local cTile
        cTile = self.map:tileAt(self.x - 1, self.y)
        if not self.map:collides(cTile) then
            cTile = self.map:tileAt(self.x - 1, self.y + self.height - 1)
        end
        if self.map:collides(cTile) then            
            -- if so, reset velocity and position and change state
            self:reset()
            self.source.sounds['explosion']:play()
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    elseif self.dx > 0 then
        -- check if there's a tile directly beneath us
        local cTile
        cTile = self.map:tileAt(self.x + self.width, self.y)
        if not self.map:collides(cTile) then
            cTile = self.map:tileAt(self.x + self.width, self.y + self.height - 1)
        end
        if self.map:collides(cTile) then            
            -- if so, reset velocity and position and change state
            self:reset()
            self.source.sounds['explosion']:play()
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
    if self.x == 0 then
        self:reset()
    end
end

function Blast:reset()
    self.show = false
    self.dx = 0
    self:align()
    self.source.shooting = false
end

function Blast:render()
    if self.show then
        love.graphics.setColor(self.source.colour)
        love.graphics.circle("fill", self.x + self.source.width, self.y + (self.source.height / 2), self.size)
        love.graphics.setColor(1, 1, 1, 1)
    end
end
