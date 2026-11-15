function LERP_POSITION(x1, y1, x2, y2, w2, h2, speed, dt)
    local alpha = math.min(1, speed * dt)
    local newX, newY = x1, y1

    newX = newX + ((x2 + (w2 / 2)) - newX) * alpha
    newY = newY + ((y2 + (h2 / 2)) - newY) * alpha

    return newX, newY
end

function CHECK_COLLISION_TAGS(tag1, tag2, a, b)
    return (a == tag1 or b == tag1) and
        (a == tag2 or b == tag2)
end

__NULL__ = function (...) end

table.print = require("printTable")

CAMERA = require("camera")
ANIM8 = require("anim8")

ENEMY = require("enemy")
PLAYER = require("player")
FLAG = require("flag")

BACKGROUNDHANDLER = require("backgroundhandler")

CAM = CAMERA()
SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getWidth(), love.graphics.getHeight()
PIXELS_PER_SECOND = 100
GRAVITY = 50
ENEMY_CURRENT_SPEED = 0.5
WORLD = love.physics.newWorld(0, GRAVITY * PIXELS_PER_SECOND)
WORLD_DEATHEFFECT = love.physics.newWorld(0, 9.81 * PIXELS_PER_SECOND)

love.graphics.setDefaultFilter("nearest", "nearest")

local CAM_SPEED = 10
local MAX_OBSTACLES = 500

local groundBody
local EnemySpawnRate = 5
local playerTouchesFlag = -1
local ObstaclesSpawnRate = 10
local camPosX, camPosY = 0, 0
local pendingFlagTouched = false

local function whenPlayerTouchesFlag()
    if not pendingFlagTouched then
        return
    end
    pendingFlagTouched = false
    ENEMY:destroyAllEnemies()
    for _ = 1, EnemySpawnRate do
        ENEMY.new()
    end

    FLAG:setRandomPosition()
    FLAG:spawnObstacles(ObstaclesSpawnRate)
    ENEMY_CURRENT_SPEED = ENEMY_CURRENT_SPEED * (1 + (EnemySpawnRate / 100))
    EnemySpawnRate = EnemySpawnRate + 5
    playerTouchesFlag = playerTouchesFlag + 1
    ObstaclesSpawnRate = math.min(ObstaclesSpawnRate + (ObstaclesSpawnRate / 2), MAX_OBSTACLES)
end

local function beginContact(a, b, _)
    local userDataA, userDataB = a:getUserData(), b:getUserData()
    if not userDataA or not userDataB then
        return
    end

    if CHECK_COLLISION_TAGS("Player", "Flag", a:getUserData(), b:getUserData()) then
        pendingFlagTouched = true
    end
end

local function moveCam(dt)
    camPosX, camPosY = LERP_POSITION(
        camPosX, camPosY,
        PLAYER.posCenter.x, PLAYER.posCenter.y,
        PLAYER.size.w, PLAYER.size.h,
        CAM_SPEED, dt
    )
    CAM:lookAt(camPosX, camPosY)
end

function love.load()
    BACKGROUNDHANDLER:load()
    PLAYER:load()
    FLAG:load()
    PLAYER:loadCollisions()

    WORLD:setCallbacks(beginContact, __NULL__)

    groundBody = love.physics.newBody(WORLD, SCREEN_WIDTH / 2, PLAYER.size.h, "static")
    love.physics.newFixture(
        groundBody,
        love.physics.newRectangleShape(SCREEN_WIDTH * 100, 100)
    )
    love.physics.newFixture(
        love.physics.newBody(WORLD, SCREEN_WIDTH / 2, 500, "static"),
        love.physics.newRectangleShape(SCREEN_WIDTH * 100, 100)
    ):setUserData("Enemy")

    FLAG:setRandomPosition(500, 0)
end

function love.update(dt)
    if not PLAYER.isDead then
        WORLD:update(dt)
    
        PLAYER:update(dt)
        BACKGROUNDHANDLER:update()
        ENEMY.updateAllEnemies(dt)
        FLAG:update(dt)
    
        moveCam(dt)
        whenPlayerTouchesFlag()
    
        groundBody:setPosition(PLAYER.pos.x, PLAYER.size.h)
    else
        WORLD_DEATHEFFECT:update(dt)
        PLAYER:animateDeath(dt)
    end
    PLAYER:applyPhysicsToDeadParts()
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    BACKGROUNDHANDLER:draw()

    CAM:attach()


    love.graphics.rectangle("fill", PLAYER.pos.x - SCREEN_WIDTH, 0, SCREEN_WIDTH * 100, 100)

    FLAG:draw()
    ENEMY.drawAllEnemies()

    PLAYER:draw()
    PLAYER:drawPlayerDeath()

    --Debug
    --[[
        love.graphics.polygon("line", PLAYER._hitboxBody:getWorldPoints(PLAYER._hitboxShape:getPoints()))
        love.graphics.circle("line", FLAG.pos.x, FLAG.pos.y, 50)
        ENEMY.drawAllEnemiesDebug()
    ]]

    CAM:detach()
    FLAG:ui()
end

function love.mousepressed(x, y, button)
    PLAYER:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    PLAYER:mousereleased(x, y, button)
end