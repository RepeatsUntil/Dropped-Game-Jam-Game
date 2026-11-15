local ENEMY_HIT_RADIUS = 50
local ENEMY_SPAWN_RADIUS = 50000
local ENEMY_SPEED_PERCENT = 50
local ENEMY_MAX_SPEED = 10

local ENEMY_SPRITESHEET = love.graphics.newImage("enemySpriteSheet.png")
local ENEMY_GRID = ANIM8.newGrid(100, 100, ENEMY_SPRITESHEET:getWidth(), ENEMY_SPRITESHEET:getHeight())

local ENEMY_FACES = {
    ANIM8.newAnimation(ENEMY_GRID("1-1", 2), 1),
    ANIM8.newAnimation(ENEMY_GRID("2-2", 2), 1),
    ANIM8.newAnimation(ENEMY_GRID("3-3", 2), 1),
    ANIM8.newAnimation(ENEMY_GRID("4-4", 2), 1),
}

local ENEMIES = {}
local Enemy = {}
Enemy.__index = Enemy

local function getRandomPos()
    local angle = (love.math.random() * 2) * math.pi
    local distance = ENEMY_SPAWN_RADIUS * math.sqrt(love.math.random())

    local x = (PLAYER.pos.x + distance) * math.cos(angle)
    local y = (PLAYER.pos.y + distance) * math.sin(angle)

    return x, y
end

function Enemy.new()
    local enemy = setmetatable({}, Enemy)

    enemy.pos = {x = 0, y = 0}
    enemy.pos.x, enemy.pos.y = getRandomPos()

    local minSpeed = ENEMY_CURRENT_SPEED * (1 - (ENEMY_SPEED_PERCENT / 100))
    local maxSpeed = ENEMY_CURRENT_SPEED * (1 + (ENEMY_SPEED_PERCENT / 100))
    enemy._speed = love.math.random(minSpeed, math.min(maxSpeed, ENEMY_MAX_SPEED))
    
    enemy._anim = ANIM8.newAnimation(ENEMY_GRID("1-4", 1), 0.5)
    enemy._face = ENEMY_FACES[math.random(1, #ENEMY_FACES)]

    table.insert(ENEMIES, enemy)
    return enemy
end

function Enemy:_killPlayer()
    local distance = math.sqrt(
        (self.pos.x - PLAYER.posCenter.x)^2 +
        (self.pos.y - PLAYER.posCenter.y)^2
    )
    
    if distance < ENEMY_HIT_RADIUS then
        PLAYER:setIsDead(true)
    end
end

function Enemy:update(dt)
    self:_killPlayer()
    self.pos.x, self.pos.y = LERP_POSITION(
        self.pos.x, self.pos.y,
        PLAYER.posCenter.x, PLAYER.posCenter.y,
        0, 0,
        self._speed, dt
    )
    self._anim:update(dt)
end

function Enemy:draw()
    love.graphics.setColor(1, 0, 0, 1)
    self._anim:draw(ENEMY_SPRITESHEET, self.pos.x - ENEMY_HIT_RADIUS, self.pos.y - ENEMY_HIT_RADIUS)
    self._face:draw(ENEMY_SPRITESHEET, self.pos.x - ENEMY_HIT_RADIUS, self.pos.y - ENEMY_HIT_RADIUS)
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy.destroyAllEnemies()
    if #ENEMIES == 0 then
        return
    end
    for i = #ENEMIES, 1, -1 do
        table.remove(ENEMIES, i)
    end
end

function Enemy.updateAllEnemies(dt)
    for _, enemy in pairs(ENEMIES) do
        enemy:update(dt)
    end
end

function Enemy.drawAllEnemies()
    for _, enemy in pairs(ENEMIES) do
        enemy:draw()
    end
end

function Enemy.drawAllEnemiesDebug()
    for _, enemy in pairs(ENEMIES) do
        love.graphics.circle("line", enemy.pos.x, enemy.pos.y, ENEMY_HIT_RADIUS)
    end
end

return Enemy