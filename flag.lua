local FLAG_HITBOX = 50
local MAX_SPAWN_RADIUS = 4500
local MIN_SPAWN_RADIUS = 150
local MIN_OBSTACLE_SIZE = 50
local MAX_OBSTACLE_SIZE = 1000
local FLAG_DIRECTION_RADIUS = 200
local PTF_SPEED = 20

local MIN_SPEED = 0.5
local MAX_SPEED = 0.5

local Flag = {}
Flag._obstacles = {}

local function scaleDownPoints(points, scale)
    local newPoints = {}

    for k, v in pairs(points) do
        newPoints[k] = v
    end

    local cx, cy = 0, 0

    for i = 1, #newPoints, 2 do
        cx = cx + newPoints[i]
        cy = cy + newPoints[i + 1]
    end

    cx = cx / (#newPoints / 2)
    cy = cy / (#newPoints / 2)

    for i = 1, #newPoints, 2 do
        newPoints[i] = cx + (newPoints[i] - cx) * scale
        newPoints[i + 1] = cy + (newPoints[i + 1] - cy) * scale
    end

    return newPoints
end

function Flag:load()
    self.pos = {x = 100, y = 100}
    self._tweenPos = {x = 0, y = 0}
    self._iconDirection = {x = 0, y = 0}
    self._distanceBetweenPlayer = 0
    self._iconAngle = 0

    self._icon = love.graphics.newImage("flagIcon.png")
    self._sprite = love.graphics.newImage("flagSpriteSheet.png")
    self._arrow = love.graphics.newImage("arrow90.png")
    self._grid = ANIM8.newGrid(100, 100, self._sprite:getWidth(), self._sprite:getHeight())
    self._animation = ANIM8.newAnimation(self._grid("1-4", 1), 1, function()
        self:_pulse()
    end)

    self.body = love.physics.newBody(WORLD, self.pos.x, self.pos.y, "static")
    self.shape = love.physics.newCircleShape(FLAG_HITBOX)
    self.fixture = love.physics.newFixture(self.body, self.shape)

    self.fixture:setSensor(true)
    self.fixture:setUserData("Flag")
    self.body:setUserData("Flag")
end

function Flag:_getRandomPoint() --[[
    Yes this is AI, deal with it. This might cause conflict in the future if I win this game jam...
    If i get disqualified from it then it's ok. I didn't saw the no AI rule.
    If I win the jam getting 1st 2nd and etc. the prize will be given to the person below me.
    ]]
    local u = love.math.random()
    local v = love.math.random()

    -- Random radius (uniform distribution)
    local r = math.sqrt(
        MIN_SPAWN_RADIUS^2 + u * (MAX_SPAWN_RADIUS^2 - MIN_SPAWN_RADIUS^2)
    )

    -- Random angle
    local theta = 2 * math.pi * v

    -- Calculate position
    local x = self.pos.x + r * math.cos(theta)
    local y = self.pos.y + r * math.sin(theta)

    return x, y
end

function Flag:_pulse()
end

function Flag:update(dt)
    self:_pointToFlag(dt)
    self._animation:update(dt)

    --i fucking hate this
    for _, obstacle in pairs(self._obstacles) do
        local newX, newY = LERP_POSITION(
            obstacle.pos.x, obstacle.pos.y,
            PLAYER.pos.x, PLAYER.pos.y,
            FLAG_HITBOX, FLAG_HITBOX,
            obstacle.speed, dt
        )
        obstacle.body:setPosition(newX, newY)
    end
end

function Flag:_getAngle()
    local playerX, playerY = PLAYER.body:getPosition()
    local flagX, flagY = self.body:getPosition()

    local dx = playerX - flagX
    local dy = playerY - flagY

    local targetAngle = math.atan2(dy, dx)
    local currentAngle = PLAYER.body:getAngle()

    local difference = math.atan2(math.sin(targetAngle - currentAngle), math.cos(targetAngle - currentAngle))

    local mult = 10^1
    return math.floor(math.deg(targetAngle) * mult + 0.5) / mult--((currentAngle + difference) * (180 * math.pi))
end

function Flag:_pointToFlag(dt)
    local playerX, playerY = PLAYER.body:getWorldCenter()
    local dx = self.pos.x - playerX
    local dy = self.pos.y - playerY

    self._distanceBetweenPlayer = math.sqrt(dx^2 + dy^2)

    self._iconDirection = {
        x = playerX + FLAG_DIRECTION_RADIUS * (dx / self._distanceBetweenPlayer),
        y = playerY + FLAG_DIRECTION_RADIUS * (dy / self._distanceBetweenPlayer)
    }

    self._iconAngle = self:_getAngle()

    self._tweenPos.x, self._tweenPos.y = LERP_POSITION(
        self._tweenPos.x, self._tweenPos.y,
        self._iconDirection.x, self._iconDirection.y,
        1, 1, PTF_SPEED, dt
    )
end

function Flag:setRandomPosition(x, y)
    if not (x and y) then
        self.pos.x = PLAYER.pos.x + (MAX_SPAWN_RADIUS * math.cos(love.math.random(0, 360)))
        self.pos.y = PLAYER.pos.y + (MAX_SPAWN_RADIUS * math.cos(love.math.random(0, 360)))
    else
        self.pos.x = x
        self.pos.y = y
    end
    if self.pos.y > -50 then
        self.pos.y = -50
    end

    self.body:setPosition(self.pos.x, self.pos.y)
end

function Flag:_renderPTFIcon()
    if self._distanceBetweenPlayer <= FLAG_DIRECTION_RADIUS then
        love.graphics.setColor(1, 1, 1, 0)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.circle("fill", self._iconDirection.x, self._iconDirection.y, 10)

    love.graphics.draw(
        self._icon,
        self._tweenPos.x - (self._icon:getWidth() / 4),
        self._tweenPos.y - (self._icon:getHeight() / 4), 0, 0.5, 0.5
    )

    love.graphics.draw(
        self._arrow,
        0, 0,
        --self._iconDirection.x - (self._arrow:getWidth() / 4),
        --self._iconDirection.y - (self._arrow:getHeight() / 4),
        self._iconAngle
    )
    love.graphics.setColor(1, 1, 1, 1)

end

function Flag:_drawObstacles()
    for _, obstacle in pairs(self._obstacles) do
        local points = {obstacle.body:getWorldPoints(obstacle.shape:getPoints())}
        --outline
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.polygon("fill", scaleDownPoints(points, 1.01))
        
        --color
        love.graphics.setColor(0, 0, 1, 1)
        love.graphics.polygon("fill", obstacle.body:getWorldPoints(obstacle.shape:getPoints()))
        
        --inner color
        love.graphics.setColor(0, 1, 1, 1)
        love.graphics.polygon("fill", scaleDownPoints(points, 0.8))
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Flag:draw()
    self:_drawObstacles()
    self:_renderPTFIcon()
    self._animation:draw(self._sprite, self.pos.x - FLAG_HITBOX, self.pos.y - FLAG_HITBOX, 0, 0.9, 0.9)
end

function Flag:ui()
    local flagDistance = math.floor(math.sqrt((self.pos.x - PLAYER.posCenter.x)^2 + (self.pos.y - PLAYER.posCenter.y)^2))
    --love.graphics.print("Flag Distance: "..flagDistance, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print("rotation:"..self._iconAngle, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
    love.graphics.setColor(1, 1, 1, 1)
end

function Flag:_createObstacle()
    --fuck you _createObstacle
    local defaultWidth = love.math.random(MIN_OBSTACLE_SIZE, MAX_OBSTACLE_SIZE)
    local defaultHeight = love.math.random(MIN_OBSTACLE_SIZE, MAX_OBSTACLE_SIZE)

    local randomSpeed = love.math.random(MIN_SPEED, MAX_SPEED)

    local body = love.physics.newBody(WORLD, 0, 0, "static")
    local shape = love.physics.newRectangleShape(defaultWidth / 2, defaultHeight / 2, defaultWidth, defaultHeight)
    local fixture = love.physics.newFixture(body, shape)

    local x, y = self:_getRandomPoint()

    body:setPosition(x, y)

    table.insert(self._obstacles, {
        pos = {x = x, y = y},
        fixture = fixture,
        body = body,
        shape = shape,
        speed = randomSpeed,
    })
end

function Flag:spawnObstacles(number_Of_Obstacles)
    local spawnMoreObstacles = false
    for i = 1, number_Of_Obstacles do
        if spawnMoreObstacles then
            self:_createObstacle()
        else
            local obstacle = self._obstacles[i]
            if not obstacle then
                spawnMoreObstacles = true
                goto continue
            end

            obstacle.pos.x, obstacle.pos.y = self:_getRandomPoint()
            obstacle.body:setPosition(obstacle.pos.x, obstacle.pos.y)
        end
        ::continue::
    end
end

return Flag