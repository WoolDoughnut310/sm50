Stats = Class("Stats")

function Stats:init(params)
    self.params = params
end

function Stats:update(dt) end

function Stats:render()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Level cleared!',
            0,
            30,
            VIRTUAL_WIDTH,
            'center')
    for i = 1, #self.params do
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.setFont(defaultFont)
        love.graphics.printf("Time: " .. tostring(params[i].time, 3) .. "s",
            ((i - 1) * 125) - (30 * #self.params),
            80,
            VIRTUAL_WIDTH,
            'center')
        love.graphics.printf("Enemies Defeated: " .. tostring(#params[i].defeated),
            ((i - 1) * 125) - (30 * #self.params),
            90,
            VIRTUAL_WIDTH,
            'center')
        love.graphics.printf("Coins collected: " .. tostring(params[i].coinsCollected),
            ((i - 1) * 125) - (30 * #self.params),
            100,
            VIRTUAL_WIDTH,
            'center')
        self.action_score = math.pow((#params[i].defeated * 10) + (params[i].coinsCollected * 5), 2)
        self.time_score = math.pow(0.9, params[i].time) * 10000
        self.score = round(self.action_score + self.time_score, 0)
        love.graphics.printf("Score: " .. tostring(self.score),
            ((i - 1) * 125) - (30 * #self.params),
            115,
            VIRTUAL_WIDTH,
            'center')
        love.graphics.printf(tostring(params[i].name),
            ((i - 1) * 125) - (30 * #self.params),
            125,
            VIRTUAL_WIDTH,
            'center')
    end
end