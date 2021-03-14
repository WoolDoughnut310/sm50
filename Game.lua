Game = Class("Game")

--[[ The amount of players can change,
each one would have the controls in CONFIGURATIONS]]

function Game:init()
    self.level = 1
    self.score = 0
    self.scores = {}

    self.sounds = {
        ['level_cleared'] = love.audio.newSource('sounds/level-completed.wav', 'stream'),
        ['game_over'] = love.audio.newSource('sounds/game-over.wav', 'stream'),
        ['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),
        ['resume'] = love.audio.newSource('sounds/resume.wav', 'static'),
    }

    self.map = Map(self, 60 * self.level)

    self.controls_objects = {}
    for i = 1, 4 do
        self.controls_objects[i] = Controls("controls/" ..i ..EXT, DEFAULT_CONTROLS[i])
    end

    self.players = self:initialise_players()
    self.state = 'menu'
end

function Game:initialise_players()
    -- associate players with game
    local players = {}
    for i = 1, PLAYER_LIMIT do
        player = Player(self, i, self.controls_objects[i], {0.5, 0, 0.5})
        table.insert(players, player)
    end
    return players
end

function Game:quit()
    for _, v in ipairs(self.controls_objects) do
        v:save()
    end
end

function Game:start()
    self.state = 'playing'
    self.map:attach(self.players)
    for _, player in ipairs(self.players) do
        player.timer:start()
    end
end

function Game:render()
    -- renders our map object onto the screen
    if self.state ~= 'menu' then
        self.map:render()
    end
    if self.state == 'cleared' then
        self.map.music:pause()
        love.graphics.translate(0.5, 0.5)
        love.graphics.setFont(largeFont)
        self.sounds['level_cleared']:play()
        love.graphics.setColor(1, 1, 1, 1)
        -- print stats
        params = {}
        for i, v in ipairs(self.players) do
            params[i] = {
                ['time'] = v.timer.time,
                ['defeated'] = v.defeated,
                ['coinsCollected'] = v.coinsCollected,
                ['name'] = v.name
            }
        end
        stats = Stats(params)
        stats:render()
        for i, player in ipairs(self.players) do
            player.dx = 0
            player.dy = 0
            player.x = 340
            player.y = (i * 25) + 19
            player.state = 'idle'
            player.animation = player.animations['idle']
            player.hearts.show = false
        end
        love.graphics.setFont(defaultFont)
    elseif self.state == 'playing' then
        love.graphics.setFont(coolFont)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(
            "Level " .. tostring(self.level),
            -100,
            40,
            VIRTUAL_WIDTH,
            'center'
        )
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(defaultFont)
    elseif self.state == 'over' then
        love.graphics.translate(0.5, 0.5)
        self.map.music:pause()
        love.graphics.clear(0, 0, 0, 1)
        self.sounds['game_over']:play()
        love.graphics.print(
            "Game Over\nPress Enter to restart.\nEscape to quit",
            150,
            100,
            0
        )
    end
end

function Game:update(dt)
    if self.state ~= 'menu' then
        self.map:update(dt)
    end
    self.mapWidth = self.map.mapWidth
end

function Game:keypressed(key)
    if key == 'enter' or key == 'return' then
        if self.state == 'paused' then
            -- resume here
            self.sounds['resume']:play()
            self.state = 'playing'
            self.map.music:play()
        elseif self.state == 'playing' then
            self.sounds['pause']:play()
            self.state = 'paused'
            self.map.music:pause()
        elseif self.state == 'over' then
            self.map.music:pause()
            self.state = 'playing'
            self = self:init()
        elseif self.state == 'cleared' then
            self.level = self.level + 1
            table.insert(self.scores, self.score)
            self.score = 0
            self.map:new(60 * self.level)
            self.level_cleared:pause()
            self.state = 'playing'
        end
    end
end