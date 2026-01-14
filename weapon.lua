local map = require("map")
local enemy = require("enemy")
local weapon = {}

weapon.list = {
    { name = "Blaster", spread = 0, rays = 1, cooldown = 0.12, color = {0, 1, 0}, shake = 2, flashSize = 10 },
    { name = "Shotgun", spread = math.rad(25), rays = 6, cooldown = 0.8, color = {1, 0.5, 0}, shake = 8, flashSize = 25 }
}
weapon.current = 1
weapon.timer = 0
weapon.swapTimer = 0 
weapon.flashes = {} 
weapon.shakeRequest = 0
weapon.activeMuzzleFlash = { x = 0, y = 0, size = 0, life = 0 }
weapon.casings = {}

function weapon.fire(px, py, angle)
    if weapon.timer > 0 or weapon.swapTimer > 0 then return end
    
    local wp = weapon.list[weapon.current]
    weapon.timer = wp.cooldown
    weapon.shakeRequest = wp.shake

    -- Muzzle Flash
    local muzzleDist = 30 
    weapon.activeMuzzleFlash = {
        x = px + math.cos(angle) * muzzleDist,
        y = py + math.sin(angle) * muzzleDist,
        size = wp.flashSize,
        life = 0.05
    }

    -- Shell Casing
    local ejectAngle = angle + math.pi/2 + love.math.random(-0.5, 0.5)
    local ejectSpeed = love.math.random(150, 250)
    table.insert(weapon.casings, {
        x = px, y = py,
        vx = math.cos(ejectAngle) * ejectSpeed,
        vy = math.sin(ejectAngle) * ejectSpeed,
        angle = love.math.random(0, math.pi*2),
        rotVel = love.math.random(-10, 10),
        friction = 0.92, life = 1
    })

    -- Firing Rays
    for i = 1, wp.rays do
        local shotAngle = angle
        if wp.rays > 1 then
            shotAngle = angle - (wp.spread / 2) + (wp.spread * (i - 1) / (wp.rays - 1))
        end

        local tx, ty = px + math.cos(shotAngle)*1000, py + math.sin(shotAngle)*1000
        local closest = {x = tx, y = ty, dist = 1}

        for _, wall in ipairs(map.walls) do
            local s = {
                {x1=wall.x, y1=wall.y, x2=wall.x+wall.w, y2=wall.y}, 
                {x1=wall.x, y1=wall.y+wall.h, x2=wall.x+wall.w, y2=wall.y+wall.h}, 
                {x1=wall.x, y1=wall.y, x2=wall.x, y2=wall.y+wall.h}, 
                {x1=wall.x+wall.w, y1=wall.y, x2=wall.x+wall.w, y2=wall.y+wall.h}
            }
            for _, line in ipairs(s) do
                local den = (px-tx)*(line.y1-line.y2) - (py-ty)*(line.x1-line.x2)
                if den ~= 0 then
                    local t = ((px-line.x1)*(line.y1-line.y2)-(py-line.y1)*(line.x1-line.x2))/den
                    local u = -((px-tx)*(py-line.y1)-(py-ty)*(px-line.x1))/den
                    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
                        if t < closest.dist then closest = {x=px+t*(tx-px), y=py+t*(ty-py), dist=t} end
                    end
                end
            end
        end
        
        table.insert(weapon.flashes, {
            offsetX = closest.x - px,
            offsetY = closest.y - py,
            color = wp.color, life = 0.05 
        })
        enemy.checkHit(px, py, closest.x, closest.y)
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