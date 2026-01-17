local enemy = require("enemy")
local weapon = {}

local function checkStiHit(x, y, map)
    if not map or not map.layers["walls"] then return false end
    local tx = math.floor(x / map.tilewidth) + 1
    local ty = math.floor(y / map.tileheight) + 1
    return map.layers["walls"].data[ty] and map.layers["walls"].data[ty][tx]
end

function weapon.load()
    weapon.sounds = {
        blaster = love.audio.newSource("sfx/blaster.wav", "static"),
        shotgun = love.audio.newSource("sfx/shotgun.wav", "static")
    }
end

weapon.list = {
    { name = "Blaster", spread = 0, rays = 1, cooldown = 0.12, color = {0, 1, 0}, shake = 2, flashSize = 10, sound = "blaster" },
    { name = "Shotgun", spread = math.rad(25), rays = 6, cooldown = 0.8, color = {1, 0.5, 0}, shake = 8, flashSize = 25, sound = "shotgun" }
}

weapon.current = 1
weapon.timer = 0
weapon.swapTimer = 0 
weapon.flashes = {} 
weapon.shakeRequest = 0
weapon.activeMuzzleFlash = { x = 0, y = 0, size = 0, life = 0 }
weapon.casings = {}

function weapon.fire(px, py, angle, map)
    if weapon.timer > 0 or weapon.swapTimer > 0 then return end
    
    local wp = weapon.list[weapon.current]
    weapon.timer = wp.cooldown
    weapon.shakeRequest = wp.shake

    -- RESTORED SOUND LOGIC
    if weapon.sounds[wp.sound] then
        weapon.sounds[wp.sound]:setPitch(love.math.random(0.9, 1.1)) -- slight pitch variation
        weapon.sounds[wp.sound]:stop() 
        weapon.sounds[wp.sound]:play()
    end

    -- Muzzle Flash
    local muzzleDist = 30 
    weapon.activeMuzzleFlash = {
        x = px + math.cos(angle) * muzzleDist,
        y = py + math.sin(angle) * muzzleDist,
        size = wp.flashSize,
        life = 0.05
    }

    -- Firing Rays
    for i = 1, wp.rays do
        local shotAngle = angle
        if wp.rays > 1 then
            shotAngle = angle - (wp.spread / 2) + (wp.spread * (i - 1) / (wp.rays - 1))
        end

        local hitX, hitY = px, py
        local maxDist = 1000
        local step = 8 
        
        for d = 0, maxDist, step do
            local nextX = px + math.cos(shotAngle) * d
            local nextY = py + math.sin(shotAngle) * d
            
            -- Changed to checkStiHit
            if checkStiHit(nextX, nextY, map) then
                hitX, hitY = nextX, nextY
                break
            else
                hitX, hitY = nextX, nextY 
            end
        end

        table.insert(weapon.flashes, {
            offsetX = hitX - px,
            offsetY = hitY - py,
            color = wp.color, life = 0.05 
        })
        
        enemy.checkHit(px, py, hitX, hitY)
    end
end

function weapon.switch()
    weapon.current = (weapon.current % #weapon.list) + 1
    weapon.swapTimer = 1.5
end

function weapon.update(dt)
    weapon.timer = math.max(0, weapon.timer - dt)
    weapon.swapTimer = math.max(0, weapon.swapTimer - dt)
    
    if weapon.activeMuzzleFlash.life > 0 then
        weapon.activeMuzzleFlash.life = weapon.activeMuzzleFlash.life - dt
    end

    for i = #weapon.casings, 1, -1 do
        local c = weapon.casings[i]
        c.x, c.y = c.x + c.vx * dt, c.y + c.vy * dt
        c.vx, c.vy = c.vx * c.friction, c.vy * c.friction
        c.angle, c.rotVel = c.angle + c.rotVel * dt, c.rotVel * c.friction
        c.life = c.life - dt
        if c.life <= 0 then table.remove(weapon.casings, i) end
    end

    for i = #weapon.flashes, 1, -1 do
        weapon.flashes[i].life = weapon.flashes[i].life - dt
        if weapon.flashes[i].life <= 0 then table.remove(weapon.flashes, i) end
    end
end

function weapon.draw(px, py)
    for _, c in ipairs(weapon.casings) do
        love.graphics.push()
        love.graphics.translate(c.x, c.y)
        love.graphics.rotate(c.angle)
        love.graphics.setColor(0.8, 0.6, 0.2, math.min(1, c.life))
        love.graphics.rectangle("fill", -2, -1, 4, 2)
        love.graphics.pop()
    end

    love.graphics.setLineWidth(2)
    for _, f in ipairs(weapon.flashes) do
        love.graphics.setColor(f.color)
        love.graphics.line(px, py, px + f.offsetX, py + f.offsetY)
    end
    love.graphics.setLineWidth(1)

    if weapon.activeMuzzleFlash.life > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", weapon.activeMuzzleFlash.x, weapon.activeMuzzleFlash.y, weapon.activeMuzzleFlash.size)
        local c = weapon.list[weapon.current].color
        love.graphics.setColor(c[1], c[2], c[3], 0.5)
        love.graphics.circle("fill", weapon.activeMuzzleFlash.x, weapon.activeMuzzleFlash.y, weapon.activeMuzzleFlash.size * 1.5)
    end
end

return weapon