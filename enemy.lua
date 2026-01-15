local map = require("map")
local enemy = {}
enemy.list = {}

function enemy.spawn(x, y)
    table.insert(enemy.list, {x=x, y=y, radius=12, speed=120, isVisible = false})
end

function enemy.updateVisibility(px, py, pAngle, pFov, pDist)
    for _, e in ipairs(enemy.list) do
        local dist = math.sqrt((e.x - px)^2 + (e.y - py)^2)
        local angleTo = math.atan2(e.y - py, e.x - px)
        local diff = (angleTo - pAngle + math.pi) % (2 * math.pi) - math.pi
        local inCone = (dist < pDist and math.abs(diff) < pFov/2)
        local blocked = false
        
        if inCone then
            for _, w in ipairs(map.walls) do
                local s = {
                    {x1=w.x, y1=w.y, x2=w.x+w.w, y2=w.y}, 
                    {x1=w.x, y1=w.y+w.h, x2=w.x+w.w, y2=w.y+w.h}, 
                    {x1=w.x, y1=w.y, x2=w.x, y2=w.y+w.h}, 
                    {x1=w.x+w.w, y1=w.y, x2=w.x+w.w, y2=w.y+w.h}
                }
                for _, line in ipairs(s) do
                    local den = (px - e.x) * (line.y1 - line.y2) - (py - e.y) * (line.x1 - line.x2)
                    if den ~= 0 then
                        local t = ((px - line.x1) * (line.y1 - line.y2) - (py - line.y1) * (line.x1 - line.x2)) / den
                        local u = -((px - e.x) * (py - line.y1) - (py - e.y) * (px - line.x1)) / den
                        if t > 0 and t < 1 and u > 0 and u < 1 then blocked = true; break end
                    end
                end
                if blocked then break end
            end
        end
        e.isVisible = inCone and not blocked
    end
end

function enemy.update(dt, px, py)
    for _, e in ipairs(enemy.list) do
        local angle = math.atan2(py - e.y, px - e.x)
        local dx = math.cos(angle) * e.speed * dt
        local dy = math.sin(angle) * e.speed * dt

        -- Sliding Collision
        local nx = e.x + dx
        local hitX = false
        for _, w in ipairs(map.walls) do
            if nx+e.radius > w.x and nx-e.radius < w.x+w.w and 
               e.y+e.radius > w.y and e.y-e.radius < w.y+w.h then hitX = true end
        end
        if not hitX then e.x = nx end

        local ny = e.y + dy
        local hitY = false
        for _, w in ipairs(map.walls) do
            if e.x+e.radius > w.x and e.x-e.radius < w.x+w.w and 
               ny+e.radius > w.y and ny-e.radius < w.y+w.h then hitY = true end
        end
        if not hitY then e.y = ny end
    end
end

function enemy.checkHit(x1, y1, x2, y2)
    for i = #enemy.list, 1, -1 do
        local e = enemy.list[i]
        local dx, dy = x2-x1, y2-y1
        local t = math.max(0, math.min(1, ((e.x-x1)*dx + (e.y-y1)*dy) / (dx*dx + dy*dy)))
        local dist = math.sqrt((e.x - (x1+t*dx))^2 + (e.y - (y1+t*dy))^2)
        if dist < e.radius then table.remove(enemy.list, i) end
    end
end

function enemy.draw()
    for _, e in ipairs(enemy.list) do
        if e.isVisible then
            -- Restore Red Hollow Circle
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("line", e.x, e.y, e.radius)
        end
    end
end

return enemy