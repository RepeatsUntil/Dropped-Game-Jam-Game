local PLAYER_SIZE = {
    w = 50, h = 50
}

local BOUNCINESS = 70
local DRAG_COOLDOWN = 1
local MAX_MULTIPLIED_FORCE = 10
local IMAGE_OFFSET = 2.5 --This fixes the player's sprite from being offseted by 2.5 pixels
local ANGULAR_DAMPED = 5
local PLAYER_HITBOX_ID = 1
local PLAYER_ID = 2
local DEATH_TIME = 1

local PLAYER_SPRITESHEET = love.graphics.newImage("playerSpriteSheet.png")
local PLAYER_GRID = ANIM8.newGrid(50, 50, PLAYER_SPRITESHEET:getWidth(), PLAYER_SPRITESHEET:getHeight())

local PLAYER_DEATH_SPRITES = love.graphics.newImage("player_death_sprites.png")
local PLAYER_DEATH_GRID = ANIM8.newGrid(50, 50, PLAYER_DEATH_SPRITES:getWidth(), PLAYER_DEATH_SPRITES:getHeight())

local Player = {}
Player._animations = {
    idle = ANIM8.newAnimation(PLAYER_GRID("1-3", 1), 0.5),
    chargeIn = ANIM8.newAnimation(PLAYER_GRID("1-4", 2), 0.03, function()
        Player:_setAnimation("charge")
    end),
    charge = ANIM8.newAnimation(PLAYER_GRID("3-4", 2), 0.05),
}

local function calculateForce(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function Player:load()
    self.pos = {x = 0, y = 0}
    self.posCenter = {x = 0, y = 0}
    self.size = {w = PLAYER_SIZE.w, h = PLAYER_SIZE.h}
    self.isDead = false

    self._mousepressedPos = {x = 0, y = 0}

    --uses os library
    self._dragCooldownTarget = 0
    self._dragPressedTime = 0

    self._isHoldingMouse = false
    self._applyPhysicsToDeadParts = false
    self._currentDeathTime = 0

    self:_setAnimation("idle")
end

function Player:_setAnimation(newState)
    if self.isDead then
        return
    end
    if self._currentAnim == newState then
        return
    end

    self._currentAnim = newState
    self._anim = self._animations[newState]
    self._anim:gotoFrame(1)
    self._anim:resume()
end

function Player:_loadDeathParts()
    local playerLayers = {
        [1] = "body",
        [2] = "body_corners",
        [3] = "body_cross",
        [4] = "mouth",
        [5] = "eyes",
    }

    self._deathAnimImages = {}
    self._deathAnimCollisions = {}

    for animName, anim in pairs(self._animations) do
        self._deathAnimImages[animName] = {}
        for frame = 1, #anim.frames do
            local frames = {}

            for index, layer in ipairs(playerLayers) do
                if animName == "charge" then
                    frames[layer] = ANIM8.newAnimation(PLAYER_DEATH_GRID(tostring(frame + 2).."-"..tostring(frame + 2), index + 5), 1)
                elseif animName == "chargeIn" then
                    frames[layer] = ANIM8.newAnimation(PLAYER_DEATH_GRID(tostring(frame).."-"..tostring(frame), index + 5), 1)
                else
                    frames[layer] = ANIM8.newAnimation(PLAYER_DEATH_GRID(tostring(frame).."-"..tostring(frame), index), 1)
                end
            end

            table.insert(self._deathAnimImages[animName], frames)
        end
    end
    
    for animName, _ in pairs(self._animations) do
        self._deathAnimCollisions[animName] = {}
        for _, layer in ipairs(playerLayers) do
            local body = love.physics.newBody(WORLD_DEATHEFFECT, 0, 0, "dynamic")
            local shape = love.physics.newRectangleShape(PLAYER_SIZE.w / 2, PLAYER_SIZE.h / 2, PLAYER_SIZE.w, PLAYER_SIZE.h)
            local fixture = love.physics.newFixture(body, shape)
            
            fixture:setSensor(true)
            fixture:setGroupIndex(-1)
            body:setAngularDamping(ANGULAR_DAMPED)
            
            table.insert(self._deathAnimCollisions[animName], {
                pos = {x = 0, y = 0},
                body = body,
                fixture = fixture,
                shape = shape,
                layer = layer,
            })
        end
    end
end

function Player:loadCollisions()
    self.body = love.physics.newBody(WORLD, self.pos.x, self.pos.y, "dynamic")
    self.shape = love.physics.newRectangleShape(PLAYER_SIZE.w / 2, PLAYER_SIZE.h / 2, PLAYER_SIZE.w, PLAYER_SIZE.h) --oh my gosh this breaks when you visualize this
    self.fixture = love.physics.newFixture(self.body, self.shape)
    
    local hitboxWidth, hitboxHeight = PLAYER_SIZE.w / 2, PLAYER_SIZE.h / 2 --I actually set this to [PLAYERSIZE] / 50 instead of half (fuck my life)
    self._hitboxBody = love.physics.newBody(WORLD, self.pos.x, self.pos.y, "kinematic")
    self._hitboxShape = love.physics.newRectangleShape(hitboxWidth, hitboxHeight)--(hitboxWidth / 2, hitboxHeight / 2, hitboxWidth, hitboxHeight)
    self.hitbox = love.physics.newFixture(self._hitboxBody, self._hitboxShape)
    
    self:_loadDeathParts()
    
    self.fixture:setRestitution(BOUNCINESS / 100)
    self.fixture:setUserData("Player")
    self.fixture:setCategory(PLAYER_ID)
    self.fixture:setGroupIndex(-1)
    self.body:setFixedRotation(false)
    self.body:setAngularDamping(ANGULAR_DAMPED)
    self.body:setUserData("Player")
    
    self.hitbox:setSensor(true)
    self.hitbox:setUserData("PlayerHitbox")
    self.hitbox:setCategory(PLAYER_HITBOX_ID)
    self.hitbox:setGroupIndex(-1)
    self._hitboxBody:setUserData("PlayerHitbox")
end

function Player:_movement()
    self.pos.x, self.pos.y = self.body:getPosition()
    self.posCenter.x, self.posCenter.y = self.body:getWorldCenter()
    
    local hbX = self.posCenter.x
    local hbY = self.posCenter.y
    self._hitboxBody:setPosition(hbX, hbY)
end

function Player:applyPhysicsToDeadParts()
    if not self._applyPhysicsToDeadParts then
        return
    end
    
    for _, collider in pairs(self._deathAnimCollisions[self._currentAnim]) do
        collider.pos.x, collider.pos.y = collider.body:getPosition()
    end
end

function Player:update(dt)
    if self.isDead then
        return
    end
    self:_movement()
    self._anim:update(dt)
end

function Player:animateDeath(dt)
    self._currentDeathTime = self._currentDeathTime + dt
    if self._currentDeathTime < DEATH_TIME then
        for _, collider in pairs(self._deathAnimCollisions[self._currentAnim]) do
            collider.body:setPosition(self.pos.x, self.pos.y)
            collider.pos.x, collider.pos.y = collider.body:getPosition()
            collider.body:setAngle(self.body:getAngle())
            
            local angle = love.math.random() * (math.pi * 2)
            local dirX = math.cos(angle) * (angle * 1000)
            local dirY = math.sin(angle) * -(angle * 1000)
            
            collider.body:applyLinearImpulse(dirX, dirY, 0, -love.math.random(1, 10))
        end
    else
        self._applyPhysicsToDeadParts = true
    end
end

function Player:drawPlayerDeath()
    if not self.isDead then
        return
    end

    for _, collider in pairs(self._deathAnimCollisions[self._currentAnim]) do
        local frameData = self._deathAnimImages[self._currentAnim][self._anim.position][collider.layer]

        love.graphics.push()
        love.graphics.translate(collider.pos.x, collider.pos.y)
        love.graphics.rotate(collider.body:getAngle())
        frameData:draw(PLAYER_DEATH_SPRITES, 0, 0, 0, 1.1, 1.1)
        love.graphics.pop()
    end
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.push()
    if not self.isDead then
        love.graphics.translate(self.pos.x, self.pos.y)
        love.graphics.rotate(self.body:getAngle())
        self._anim:draw(PLAYER_SPRITESHEET, -IMAGE_OFFSET, -IMAGE_OFFSET, 0, 1.1, 1.1)
    end
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:_throwPlayer(x, y)
    if self._isHoldingMouse and os.time() < self._dragCooldownTarget then
        return
    end
    self:_setAnimation("idle")

    local dx = x - self._mousepressedPos.x
    local dy = y - self._mousepressedPos.y
    local length = math.sqrt(dx^2 + dy^2)

    if length == 0 then
        self.body:setLinearVelocity(0, 0)
        return
    end

    local dragTimeMS = (love.timer.getTime() - self._dragPressedTime) * 100
    local multipliedForce = math.min(math.max(dragTimeMS, MAX_MULTIPLIED_FORCE), MAX_MULTIPLIED_FORCE^2)

    local force = calculateForce(
        self._mousepressedPos.x, self._mousepressedPos.y,
        x, y
    ) * multipliedForce

    local dirX = -((dx / length) * force)
    local dirY = -((dy / length) * force)

    self.body:applyLinearImpulse(dirX, dirY, 0, length / multipliedForce)
    self._dragCooldownTarget = os.time() + DRAG_COOLDOWN
end

function Player:setIsDead(bool)
    self.isDead = bool
    if bool == true then
        self._currentDeathTime = 0
    end
end

function Player:mousepressed(x, y, button)
    if self.isDead then
        return
    end
    if button ~= 1 then
        return
    end

    self._mousepressedPos = {x = x, y = y}
    self._isHoldingMouse = true
    self._dragPressedTime = love.timer.getTime()
    self:_setAnimation("chargeIn")
end

function Player:mousereleased(x, y, button)
    if self.isDead then
        return
    end
    if button ~= 1 then
        return
    end

    self._isHoldingMouse = false
    self:_throwPlayer(x, y)
end

return Player