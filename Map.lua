--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Coin'

Map = Class("Map")

TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- flag
FLAG_LEFT = 13
FLAG_MIDDLE = 14
FLAG_RIGHT = 15

-- flagpole tiles
FLAGPOLE_TOP = 8
FLAGPOLE_MIDDLE = 12
FLAGPOLE_BOTTOM = 16

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init(game, width, updated)
    self.game = game
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.surfaces = love.filesystem.getDirectoryItems("graphics/surfaces/")
    self.surface = love.graphics.newImage("graphics/surfaces/" .. self.surfaces[math.random(1, #self.surfaces)])
    self.sprites = generateQuads(self.spritesheet, 16, 16)

    self.sounds = {
        ['coin'] = love.audio.newSource('sounds/pickup.wav', 'static'),
        ['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),
        ['resume'] = love.audio.newSource('sounds/resume.wav', 'static'),
    }
    
    self.music = love.audio.newSource('sounds/music.wav', 'stream')

    self.tileWidth = 16
    self.tileHeight = 16
    print("the width is", width)
    self.mapWidth = width or 30
    self.mapHeight = 28
    self.cleared_players = {}
    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 15

    -- camera offsets
    self.camX = 0
    self.camY = -3

    self.coins = {}

    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    self.grid = anim8.newGrid(self.tileWidth, self.tileHeight, self.spritesheet:getWidth(), self.spritesheet:getHeight())

    -- Animation for the flag
    self.flagAnimation = anim8.newAnimation(self.grid(
        4, FLAG_LEFT % 4,
        4, FLAG_MIDDLE % 4,
        4, FLAG_RIGHT % 4
    ), 0.2)

    -- First, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables z
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    self.pyramidX = (self.mapWidth - math.max(math.floor(self.mapWidth * 0.23), 14))
    self.flagpoleX = (self.mapWidth - 2)
    self.flagX = self.flagpoleX
    self.flagpoleHeight = 3
    self.pyramidHeight = 8

    -- generate pyramid near the end
    local pyramidLevel = self.mapHeight / 2 - self.pyramidHeight
    for i = 1, self.pyramidHeight + 1 do
        for j = 0, i-1 do
            self:setTile(self.pyramidX + (self.pyramidHeight - i) + j, pyramidLevel, TILE_BRICK)
        end
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(self.pyramidX + (self.pyramidHeight - i), y, TILE_BRICK)
        end
        pyramidLevel = pyramidLevel + 1
    end

    -- Generate flagpole by self.flagpoleHeight
    self:setTile(self.flagpoleX, self.mapHeight / 2 - self.flagpoleHeight, FLAGPOLE_TOP)
    for i = (self.flagpoleHeight - 1), 1, -1 do
        self:setTile(self.flagpoleX, self.mapHeight / 2 - i, FLAGPOLE_MIDDLE)
    end
    self:setTile(self.flagpoleX, self.mapHeight / 2 - 1, FLAGPOLE_BOTTOM)
    for y = self.mapHeight / 2, self.mapHeight do
        self:setTile(self.flagpoleX, y, TILE_BRICK)
    end

    -- Begin generating the terrain using vertical scan lines
    local x = 1
    while x < self.mapWidth do
        -- If x gets to pyramid, then pass over it
        if x == self.pyramidX then
            x = x + self.pyramidHeight
        end

        -- 2% chance to generate a cloud
        -- make sure we're 2 tiles from edge at least
        if x < self.mapWidth - 2 then
            if math.random(20) == 1 then
                
                -- choose a random vertical spot above where blocks/pipes generate
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        -- 5% chance to generate a mushroom
        if math.random(20) == 1 then
            -- left side of pipe
            self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
            self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)

            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- next vertical scan line
            x = x + 1

        -- 10% chance to generate bush, being sure to generate away from edge
        elseif math.random(10) == 1 and x < self.mapWidth - 3 then
            local bushLevel = self.mapHeight / 2 - 1

            -- place bush component and then column of bricks
            self:setTile(x, bushLevel, BUSH_LEFT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

            self:setTile(x, bushLevel, BUSH_RIGHT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

        -- 10% chance to not generate anything, creating a gap
        elseif math.random(10) ~= 1 then

            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- chance to create a block for Mario to hit
            if math.random(15) == 1 then
                self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
            end

            -- next vertical scan line
            x = x + 1
        else
            -- increment X so we skip two scanlines, creating a 2-tile gap
            x = x + 2
        end
    end

    -- start the background music
    self.music:setLooping(true)
end

function Map:attach(players)
    self.players = players
    for  _, player in ipairs(self.players) do
        player:attach(self)
    end

    -- bring in the baddies
    self.enemies = {}
    for i = 0, math.floor(self.mapWidth / 30) do
        local enemyX = math.random(self.mapWidth)
        while enemyX >= self.pyramidX and enemyX <= self.pyramidX + self.pyramidHeight do
            enemyX = math.random(self.mapWidth)
        end
        enemy = Enemy(self.game, self, enemyX, false, self.players)
        -- enemy = FlyingEnemy(self.game, self, enemyX, self.players)
        table.insert(self.enemies, enemy)
    end
    for i = 0, math.floor(self.mapWidth / 60) do
        local enemyX = math.random(self.mapWidth)
        while enemyX >= self.pyramidX and enemyX <= self.pyramidX + self.pyramidHeight do
            enemyX = math.random(self.mapWidth)
        end
        enemy = FlyingEnemy(self.game, self, enemyX, self.players)
        table.insert(self.enemies, enemy)
    end
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT,
        MUSHROOM_TOP, MUSHROOM_BOTTOM,
        FLAGPOLE_TOP, FLAGPOLE_MIDDLE, FLAGPOLE_BOTTOM
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end 
    end
    
    return false
end

function Map:new(width)
    self:init(width)
end

-- function to update camera offset with delta time
function Map:update(dt)
    if self.game.state == 'playing' then
        self.music:play()
    end
    local terminated_players = {}
    for _, player in ipairs(self.players) do
        if player.alive == false then
            table.insert(terminated_players, player)
        end
    end
    if #(terminated_players) >= self.playerAmount then
        self.game.state = 'over'
        return
    end
    if #(self.cleared_players) >= self.playerAmount then
        self.game.state = 'cleared'
    end
    if self.game.state == 'paused' then
        return
    end

    if self.players then
        for _, player in ipairs(self.players) do
            player.timer:update(dt)
            if player.alive then
                player:update(dt)
            end
        end
        for _, enemy in ipairs(self.enemies) do
            if enemy.alive then
                enemy:update(dt)
            end
        end
    end
    self.flagAnimation:update(dt)
    
    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    local max = 1
    for i, v in ipairs(self.players) do
        if v.cleared == false then
            if v.alive or self.players[max].alive == true then
                if v.x > self.players[max].x or self.players[max].cleared == true then
                    max = i
                end
            end
        end
    end
    self.camX = math.max(0, math.min(self.players[max].x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.players[max].x)))
    for _, coin in ipairs(self.coins) do
        for _, player in ipairs(self.players) do
            if isColliding(player, coin) and coin.show == true then
                self.sounds['coin']:play()
                player.coinsCollected = player.coinsCollected + 1
                coin.show = false
            end
        end
    end
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- renders our map to the screen, to be called by game's render
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                if tile == TILE_BRICK then
                    love.graphics.draw(self.surface,
                        (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
                else
                    love.graphics.draw(self.spritesheet, self.sprites[tile],
                        (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
                end
            end
        end
    end

    -- draw in the flag at its current frame
    love.graphics.draw(self.spritesheet, self.flagAnimation:getCurrentFrame(),
        math.floor(((self.mapWidth - 2.35) * self.tileWidth) + 2),
        math.floor((((self.mapHeight / 2) - (self.flagpoleHeight + 1.25)) * self.tileHeight) + 2),
        0, -1, 1, 2, 2)

    if self.players then
        for _, player in ipairs(self.players) do
            if player.alive then
                player:render()
            end
        end
        for _, enemy in ipairs(self.enemies) do
            if enemy.alive then
                enemy:render()
            end
        end
        for _, coin in ipairs(self.coins) do
            coin:render()
        end
    end
end
