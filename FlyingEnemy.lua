FlyingEnemy = Class("FlyingEnemy")

local FLYING_SPEED = 80
local JUMP_VELOCITY = 250

function FlyingEnemy:init(game, map, x, targets)
    self.game = game
    self.map = map
    self.targets = targets
    self.x = 0
    self.y = 0
    self.width = 16
    self.height = 16
    self.alive = true

    self.hurt = love.audio.newSource('sounds/kill2.wav', 'static')

    -- offset from top left to center to support sprite flipping
    self.xOffset = self.width / 2
    self.yOffset = self.height / 2

    -- reference to map for checking tiles
    self.texture = love.graphics.newImage('graphics/enemy2.png')

    -- determines sprite flipping
    self.direction = 'left'

    -- x and y velocity
    self.dx = FLYING_SPEED
    self.dy = 0

    -- position on top of map tiles
    self.y = self.map.tileHeight * ((self.map.mapHeight - 2) / 2) - self.height
    self.x = self.map.tileWidth * x

    while self.map:tileAt(self.x / self.map.tileWidth, self.y / self.map.tileHeight - 1) == TILE_EMPTY do
        self.x = math.random(self.mapWidth) * self.map.tileWidth
    end
end

wait = 0

function FlyingEnemy:update(dt)
    if self.y > 300 then
        return
    end

    -- apply map's gravity before y velocity
    self.dy = self.dy + self.map.gravity

    -- check for collisions moving left and right
    self:checkCollision()
    self:checkLanding()
    self.direction = (self.dx > 0) and "right" or "left"
    -- make random jumps
    if math.random(10) == 1 then
        self.dy = -JUMP_VELOCITY
    end

    -- avoid going past the left
    self.x = math.max(0, self.x + self.dx * dt)

    self:calculateJumps()

    -- apply velocity
    self.y = self.y + self.dy * dt

    for _, target in ipairs(self.targets) do
        if isColliding(target, self) and (self.game.state == 'playing') then
            wait = wait + dt
            if wait > 0.1 then
                wait = wait - 0.1
                self.dx = -self.dx
                target.x = (target.x > self.x) and target.x + 10 or target.x - 10
                target.y = target.y - 10
                target:checkCollision()
                target:checkLanding()
                target:checkDrop()
                self.x = (target.x > self.x) and self.x - 10 or self.x + 10
                target.sounds['hurt']:play()
                target.lives = target.lives - 1
            end
        end
        if isColliding(target.blast, self) and target.shooting then
            self.hurt:play()
            table.insert(target.defeated, self)
            target.blast:reset()
            self.alive = false
        end
    end
end

function FlyingEnemy:calculateJumps()
    -- if we have negative y velocity (jumping), check if we collide
    -- with any blocks above us
    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then
            -- reset y velocity
            self.dy = 0
        end
    end
end

-- checks two tiles to either side to see if a collision occurred
function FlyingEnemy:checkCollision()
    local cTile
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        cTile = self.map:tileAt(self.x + self.width, self.y)
        if not self.map:collides(cTile) then
            cTile = self.map:tileAt(self.x + self.width, self.y + self.height - 1)
        end
        if self.map:collides(cTile) then            
            -- if so, reset velocity and position and change state
            self.dx = -self.dx
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    elseif self.dx < 0 then
        -- check if there's a tile directly beneath us
        cTile = self.map:tileAt(self.x - 1, self.y)
        if not self.map:collides(cTile) then
            cTile = self.map:tileAt(self.x - 1, self.y + self.height - 1)
        end
        if self.map:collides(cTile) then            
            -- if so, go the other way
            self.dx = -self.dx
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
    if self.x == 0 then
        self.dx = -self.dx
    end
    if self.x == (self.map.mapWidth * self.map.tileWidth) then
        self.dx = -self.dx
    end
end

function FlyingEnemy:checkLanding()
    -- check if there's a tile directly beneath us
    local cTile
    cTile = self.map:tileAt(self.x, self.y + self.height)
    if not self.map:collides(cTile) then
        cTile = self.map:tileAt(self.x + self.width - 1, self.y + self.height)
    end
    if self.map:collides(cTile) then            
        -- if so, reset velocity and position and change state
        self.dy = 0
        self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
    end
end

function FlyingEnemy:render()
    local scaleX

    -- set negative x scale factor if facing left, which will flip the sprite
    -- when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- draw sprite with scale factor and offsets
    love.graphics.draw(self.texture, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, scaleX, 1, self.xOffset, self.yOffset)
    love.graphics.setColor(1, 1, 1, 1)
end