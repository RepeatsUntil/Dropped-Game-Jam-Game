local BG_IMAGE = love.graphics.newImage("background.png")
local BG_SCALE = 1.5
local BG_SPEED = 5

local backgroundHandler = {}

function backgroundHandler:load()
    self.bgPos = {x = 0, y = 0}
    self._quad = love.graphics.newQuad(0, 0, BG_IMAGE:getWidth(), BG_IMAGE:getHeight(), BG_IMAGE:getWidth(), BG_IMAGE:getHeight())
    BG_IMAGE:setWrap("repeat", "repeat", "repeat")
end

function backgroundHandler:update()
    self.bgPos.x = (self.bgPos.x - BG_SPEED)
    self.bgPos.y = (self.bgPos.y - BG_SPEED)
end

function backgroundHandler:draw()
    love.graphics.push()
    love.graphics.scale(BG_SCALE, BG_SCALE)
    self._quad:setViewport(
        self.bgPos.x,
        self.bgPos.y, BG_IMAGE:getWidth(), BG_IMAGE:getHeight(), BG_IMAGE:getWidth(), BG_IMAGE:getHeight())
    love.graphics.draw(BG_IMAGE, self._quad, 0, 0, 0)
    love.graphics.pop()
end

return backgroundHandler