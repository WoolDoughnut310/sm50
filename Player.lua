--[[
    Represents our player in the game, with its own sprite.
]]

Player = Class("Player")

require 'Hearts'
require 'Blast'

local WALKING_SPEED = 140
local JUMP_VELOCITY = 350

function Player:init(game, index, controls, colour)
    self.index = index
    self.colour = colour or {1, 1, 1}
    self.x = 0
    self.y = 0
    self.width = 16
    self.height = 20
    self.alpha = 1
    self.cleared = false
    self.defeated = {}
    self.name = "P" .. tostring(self.index)
    self.nametag = Nametag(self, self.name, self.alpha)
    self.controls = controls
    
    self.shooting = false
    self.coinsCollected = 0
    self.lives = 5
    self.damage_taken = 0
    self.alive = true
    self.hearts = Hearts(self)
    self.hearts.show = true

    -- offset from top left to center to support sprite flipping
    self.xOffset = self.width / 2
    self.yOffset = self.height / 2

    -- reference to map for checking tiles
    self.game = game
    self.map = self.game.map
    self.texture = love.graphics.newImage('graphics/blue_alien.png')

    self.blast = Blast(self.map, self, 4)
    self.blast:align()

    -- sound effects
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
        ['coin'] = love.audio.newSource('sounds/coin.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['explosion'] = love.audio.newSource('sounds/explosion.wav', 'static'),
        ['death'] = love.audio.newSource('sounds/death.wav', 'static')
    }

    -- animation frames
    self.frames = {}

    -- current animation frame
    self.currentFrame = nil

    -- used to determine behavior and animations
    self.state = 'idle'

    -- determines sprite flipping
    self.direction = 'left'

    -- x and y velocity
    self.dx = 0
    self.dy = 0

    -- controls

    self.grid = anim8.newGrid(self.width, self.height, self.texture:getWidth(), self.texture:getHeight())

    self.frames = {
        ['idle'] = self.grid(1, 1),
        ['walking'] = self.grid('9-11', 1, 10, 1),
        ['jumping'] = self.grid(3, 1),
        ['crouching'] = self.grid(4, 1),
    }

    self.animations = {
        ['idle'] = anim8.newAnimation(self.frames['idle'], 0.05),
        ['walking'] = anim8.newAnimation(self.frames['walking'], 0.15),
        ['jumping'] = anim8.newAnimation(self.frames['jumping'], 0.05),
        ['crouching'] = anim8.newAnimation(self.frames['crouching'], 0.05),
    }

    -- initialize animation and current frame we should render
    self.animation = self.animations['idle']
    self.currentFrame = self.animation.position

    self.timer = Time()
end

local wait = 0
function Player:update(dt)
    if self.lives <= 0 then
        self.sounds['death']:play()
        self.timer:stop()
        table.insert(self.map.cleared_players, self)
        self.cleared = true
        self.alive = false
    end
    self.behaviors[self.state](dt)
    self.nametag:update(dt)
    self.animation:update(dt)
    if love.keyboard.isDown(CONFIGURATIONS[self.index].shoot) then
        self.shooting = true
    end

    if self.shooting then
        self.blast.show = true
        self.blast:update(dt)
    else
        self.blast:reset()
    end
    self.currentFrame = self.animation.position

    -- avoid going past the left
    self.x = math.max(0, self.x + self.dx * dt)

    self:calculateJumps()

    -- apply velocity
    self.y = self.y + self.dy * dt

    if self.y > (self.map.mapHeight / 2) * self.map.tileHeight and not self.cleared then
        wait = wait + dt
        if wait > 1 then
            wait = wait - 1
            self.sounds['hurt']:play()
            self.y = (self.map.mapHeight / 2) * self.map.tileHeight - self.height - 10
            self.x = (self.direction == 'left') and self.x + 20 or self.x - 20
            while not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) do
                self.x = (self.direction == 'left') and self.x + 20 or self.x - 20
            end
            self.lives = self.lives - 1
        end
    end
end

function Player:attach(map)
    self:init()
    self.map = map
    self:attachBehaviors()
end

function Player:attachBehaviors()
    -- behavior map we can call based on player state
    self.behaviors = {
        ['idle'] = function(dt)
            if self.controls:wasPressed('jump') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            end
            if self.controls:isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:gotoFrame(1)
                self.animation = self.animations['walking']
            elseif self.controls:isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:gotoFrame(1)
                self.animation = self.animations['walking']
            elseif self.controls:isDown('crouch') then
                self.state = 'crouching'
                self.animations['crouching']:gotoFrame(1)
                self.animation = self.animations['crouching']
            else
                self.dx = 0
            end
        end,
        ['walking'] = function(dt)
            -- keep track of input to switch movement while walking, or reset
            -- to idle if we're not moving
            if self.controls:wasPressed('jump') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif self.controls:isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif self.controls:isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            elseif self.controls:isDown('crouch') then
                if self.state ~= 'crouching' then
                    self.state = 'crouching'
                    self.animations['crouching']:gotoFrame(1)
                    self.animation = self.animations['crouching']
                end
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            -- check for collisions moving left and right
            self:checkCollision()
            self:checkDrop()
        end,
        ['jumping'] = function(dt)
            -- break if we go below the surface
            if self.y > 300 then
                return
            end

            if self.controls:isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif self.controls:isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            end

            -- apply map's gravity before y velocity
            self.dy = self.dy + self.map.gravity

            -- check for collisions moving left and right
            self:checkCollision()
            self:checkLanding()
        end,
        ['crouching'] = function(dt)
            if self.y > 300 then
                return
            end

            if self.controls:wasPressed('jump') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif self.controls:isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif self.controls:isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            elseif not self.controls:isDown('crouch') then
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            else
                if not self.controls:isDown('crouch') then
                    self.dx = 0
                    self.state = 'idle'
                    self.animation = self.animations['idle']
                end
            end
            -- check for collisions moving left and right
            self:checkCollision()
            self:checkDrop()
        end
    }
end

function Player:headCollides(block)
    if type(block) == 'table' then
        for _, v in ipairs(block) do
            if self:headCollides(v) then
                return true
            end
        end
    end
    return self.map:tileAt(self.x, self.y).id == block or
    self.map:tileAt(self.x + self.width - 1, self.y).id == block
end

-- jumping and block hitting logic
function Player:calculateJumps()
    -- if we have negative y velocity (jumping), check if we collide
    -- with any blocks above us
    if self.dy < 0 then
        if not self:headCollides({TILE_EMPTY, CLOUD_LEFT, CLOUD_RIGHT}) then
            -- reset y velocity
            self.dy = 0

            -- change block to different block
            local playCoin = false
            local playHit = false
            if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
                local x = math.floor(self.x / self.map.tileWidth) + 1
                local y = math.floor(self.y / self.map.tileHeight) + 1
                self.map:setTile(x, y, JUMP_BLOCK_HIT)
                local coin = Coin((x - 0.85) * self.map.tileWidth, (y - 2) * self.map.tileHeight)
                coin.show = true
                table.insert(self.map.coins, coin)
                playCoin = true
            else
                playHit = true
            end
            if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
                local x = math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1
                local y = math.floor(self.y / self.map.tileHeight) + 1
                self.map:setTile(x, y, JUMP_BLOCK_HIT)
                local coin = Coin((x - 0.85) * self.map.tileWidth, (y - 2) * self.map.tileHeight)
                coin.show = true
                table.insert(self.map.coins, coin)
                playCoin = true
            else
                playHit = true
            end

            if playCoin then
                self.sounds['coin']:play()
            elseif playHit then
                self.sounds['hit']:play()
            end
        end
    end
end

-- checks two tiles to either side to see if a collision occurred
function Player:checkCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        local cTile
        cTile = self.map:tileAt(self.x - 1, self.y)
        if not self.map:collides(cTile) then
            cTile = self.map:tileAt(self.x - 1, self.y + self.height - 1)
        end
        if self.map:collides(cTile) then
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth

            -- if player collided with flagpole
            for _, v in ipairs({FLAGPOLE_TOP, FLAGPOLE_MIDDLE, FLAGPOLE_BOTTOM}) do
                if cTile.id == v and not self.cleared then
                    self.timer:stop()
                    self.cleared = true
                    table.insert(self.map.cleared_players, self.index)
                    break
                end
            end
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
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width

            -- if player collided with flagpole
            for _, v in ipairs({FLAGPOLE_TOP, FLAGPOLE_MIDDLE, FLAGPOLE_BOTTOM}) do
                if cTile.id == v and not self.cleared then
                    self.timer:stop()
                    self.cleared = true
                    table.insert(self.map.cleared_players, self.index)
                    break
                end
            end
        end
    end
end

function Player:checkLanding()
    -- check if there's a tile directly beneath us
    local cTile
    cTile = self.map:tileAt(self.x, self.y + self.height)
    if not self.map:collides(cTile) then
        cTile = self.map:tileAt(self.x + self.width - 1, self.y + self.height)
    end
    if self.map:collides(cTile) then            
        -- if so, reset velocity and position and change state
        self.dy = 0
        self.state = 'idle'
        self.animation = self.animations['idle']
        self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height

        -- if player collided with flagpole
        for _, v in ipairs({FLAGPOLE_TOP, FLAGPOLE_MIDDLE, FLAGPOLE_BOTTOM}) do
            if cTile.id == v and not self.cleared then
                self.timer:stop()
                self.cleared = true
                table.insert(self.map.cleared_players, self.index)
                break
            end
        end
    end
end

function Player:checkDrop()
    -- check if there's not a tile directly beneath us
    if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
    not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

    -- if so, reset velocity and position and change state
    self.state = 'jumping'
    self.animation = self.animations['jumping']
    end
end

function Player:setAlpha(value)
    self.alpha = value
end

function Player:render()
    local scaleX

    -- set negative x scale factor if facing left, which will flip the sprite
    -- when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end
    
    -- draw sprite with scale factor and offsets
    love.graphics.setColor(self.colour, self.alpha)
    self.animation:draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, scaleX, 1, self.xOffset, self.yOffset)
    love.graphics.setColor(1, 1, 1, 1)
    self.nametag:render()
    self.hearts:render()
    self.blast:render()
end
