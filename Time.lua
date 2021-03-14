Time = Class("Time")

function Time:init()
    self.time = 0
    self.running = false
end

function Time:update(dt)
    if self.running then
        self.time = round(self.time + dt, 3)
    end
end

function Time:stop()
    self.running = false
end

function Time:start()
    self.running = true
end

function Time:restart()
    self.time = 0
    self:stop()
end