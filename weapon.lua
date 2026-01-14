local map = require("map")
local enemy = require("enemy")
local weapon = {}

weapon.list = {
    { name = "Blaster", spread = 0, rays = 1, cooldown = 0.12, color = {0, 1, 0} },
    { name = "Shotgun", spread = math.rad(25), rays = 6, cooldown = 2, color = {1, 0.5, 0} }
}
weapon.current = 1
weapon.timer = 0
weapon.swapTimer = 0 
weapon.flashes = {} 

function weapon.fire(px, py, angle)
    if weapon.timer > 0 or weapon.swapTimer > 0 then return end
    
    local wp = weapon.list[weapon.current]
    weapon.timer = wp.cooldown

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
            color = wp.color, 
            life = 0.05 
        })
        enemy.checkHit(px, py, closest.x, closest.y)
    end
end

function weapon.switch()
    weapon.current = (weapon.current % #weapon.list) + 1
    ------ change this ↓ number and the number on line 65 of main.lua to change the weapon swap time in seconds.
    weapon.swapTimer = 1
end

function weapon.update(dt)
    weapon.timer = math.max(0, weapon.timer - dt)
    weapon.swapTimer = math.max(0, weapon.swapTimer - dt)
    
    for i = #weapon.flashes, 1, -1 do
        weapon.flashes[i].life = weapon.flashes[i].life - dt
        if weapon.flashes[i].life <= 0 then
            table.remove(weapon.flashes, i)
        end
    end
end

function weapon.draw(px, py)
    if not px or not py then return end
    love.graphics.setLineWidth(2)
    for _, f in ipairs(weapon.flashes) do
        love.graphics.setColor(f.color)
        love.graphics.line(px, py, px + f.offsetX, py + f.offsetY)
    end
    love.graphics.setLineWidth(1)
end

return weapon