--[[
    Super Mario Bros. Demo
    Author: Colton Ogden
    Original Credit: Nintendo
]]

-- spritesheet for baddie made by MegAmi

require 'lib'

-- load in credits
CREDITS, _ = love.filesystem.read("credits.txt")

-- close resolution to NES but 16:9
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- actual window resolution
WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getDimensions()

EXT = ".sm50"

PLAYER_LIMIT = 4

-- default controls
DEFAULT_CONTROLS = {
    {
        ['jump'] = 'w',
        ['left'] = 'a',
        ['right'] = 'd',
        ['crouch'] = 's',
        ['shoot'] = 'q'
    },
    {
        ['jump'] = 'up',
        ['left'] = 'left',
        ['right'] = 'right',
        ['crouch'] = 'down',
        ['shoot'] = 'rctrl'
    },
    {
        ['jump'] = 'y',
        ['left'] = 'g' ,
        ['right'] = 'j',
        ['crouch'] = 'h',
        ['shoot'] = 't'
    },
    {
        ['jump'] = 'p',
        ['left'] = 'l',
        ['right'] = '\'',
        ['crouch'] = ';',
        ['shoot'] = 'o'
    },
}

-- seed RNG
math.randomseed(os.time())

-- makes upscaling look pixel-y instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

-- performs initialization of all objects and data needed by program
function love.load()
    -- sets up a different, better-looking retro font as our default
    defaultFont = love.graphics.newFont('fonts/font.ttf', 8)
    mediumFont = love.graphics.newFont('fonts/font.ttf', 16)
    largeFont = love.graphics.newFont('fonts/retrochips.otf', 32)
    coolFont = love.graphics.newFont('fonts/coolkids.otf', 32)
    titleFont = love.graphics.newFont('fonts/title.otf', 64)
    retroFont = love.graphics.newFont('fonts/retro.ttf', 8)
    love.graphics.setFont(defaultFont)

    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    scrollX = 0

    jupiter.saveDir = ''

    default_appdata = {
        _fileName = "appdata.save",
        vsync = 1,
        windowmode = "windowed fullscreen",
        MASTER_VOLUME = 1,
        MENU_VOLUME = 1,
        GAME_VOLUME = 1
    }

    appdata = jupiter.load("appdata.save") or default_appdata

    updatePairs(default_appdata, appdata)
    appdata.MASTER_VOLUME = round(appdata.MASTER_VOLUME, 1)
    appdata.MENU_VOLUME = round(appdata.MENU_VOLUME, 1)
    appdata.GAME_VOLUME = round(appdata.GAME_VOLUME, 1)
    
    for k, v in pairs(appdata) do print("k is", k, "and v is", v) end
    for k, v in pairs(default_appdata) do print("default k is", k, "and v is", v) end
    setup_screen()

    windowmodes = {
        "Windowed Fullscreen",
        "Fullscreen",
        "Windowed"
    }

    -- create the menu
    menu = Menu()

    -- create the game
    game = Game()

    -- displaying controls for every player
    controls_display = ControlsDisplay(game, menu)

    local title = love.window.getTitle()

    title_data = {
        text = title,
        x = 0 - titleFont:getWidth(title),
        y = 600,
        r = 0,
        sx = 1,
        sy = 1
    }

    title_tween = tween.new(1.45, title_data,
    {
        x = WINDOW_WIDTH / 5 - 150,
        y = 250
    }, 'inElastic')
end

function update_window(mode)
    mode = mode or appdata.windowmode or appdata.window_mode
    mode = string.lower(mode)
    if mode == "fullscreen" then
        return love.window.setFullscreen(true, "exclusive")
    elseif mode == "windowed fullscreen" then
        return love.window.setFullscreen(true, "desktop")
    elseif mode == "windowed" then
        return love.window.setFullscreen(false)
    elseif mode == "no fullscreen" then
        return love.window.setFullscreen(false)
    elseif mode == '1' then
        return love.window.setFullscreen(true)
    elseif mode == '0' then
        return love.window.setFullscreen(false)
    end
    return false
end

function setup_screen()
    -- sets up virtual screen resolution for an authentic retro feel
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = true,
        resizable = true
    })
    appdata.vsync = appdata.vsync or 1
    love.window.setVSync(appdata.vsync)
    appdata.windowmode = appdata.windowmode or "windowed fullscreen"
    update_window()
end

-- called when the game is quit
function love.quit()
    jupiter.save(appdata)
end

-- called whenever window is resized
function love.resize(w, h)
    push:resize(w, h)
    WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getDimensions()
    menu:resize(w, h)
end

-- global key pressed function
function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

function contains(set, key)
    return set[key] ~= nil
end

-- global key released function
function love.keyboard.wasReleased(key)
    if (love.keyboard.keysReleased[key]) then
        return true
    else
        return false
    end
end

function sleep(n)  -- seconds
    local t0 = os.clock()
    while os.clock() - t0 <= n do end
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
    game:keypressed(key)
    love.keyboard.keysPressed[key] = true
end

-- called whenever a key is released
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

-- called every frame, with dt passed in as delta in time since last frame
function love.update(dt)
    Timer.update(dt)
    -- reset all keys pressed and released this frame
    if game.state ~= 'menu' then
        game:update(dt)
        love.keyboard.keysPressed = {}
        love.keyboard.keysReleased = {}
    else
        if title_tween then
            if title_tween:update(dt) then
                title_tween = nil
            end
        end
        controls_display:update(dt)
        menu:update(dt)
    end
end

function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 20, 20)
    love.graphics.setColor(0, 1, 0, 1)
end

function isColliding(object1, object2)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if object1.x > object2.x + object2.width or object2.x > object1.x + object1.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if object1.y > object2.y + object2.height or object2.y > object1.y + object1.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

-- called each frame, used to render to the screen
function love.draw()
    love.graphics.clear(rgb{108, 140, 255}, 1)
    if game.state  ~= 'menu' then
        menu.music:pause()

        -- begin virtual resolution drawing
        push:start()
        
        -- clear screen using Mario background blue
        if game.state ~= 'cleared' and game.state ~= 'over' then
            love.graphics.translate(math.floor(-game.map.camX + 0.5), math.floor(-game.map.camY + 0.5))
        end
        
        game:render()
        displayFPS()

        -- end virtual resolution
        push:finish()
    else
        applyFont(titleFont)
        love.graphics.print(
            title_data.text,
            title_data.x,
            title_data.y,
            title_data.r,
            title_data.sx,
            title_data.sy
        )
        removeFont()

        love.graphics.translate(0.5, 0.5)
        menu:render()
        menu.music:play()
    end
end