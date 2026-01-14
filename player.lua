local map = require("map")
local player = {}

function player.load()
    player.x = 400
    player.y = 300
    player.speed = 50
    player.angle = 0
    player.radius = 10
    player.viewDist = 400
    player.fov = math.rad(90)
    player.rotationSpeed = math.pi * 1 
end

function player.getIntersection(x1, y1, x2, y2, x3, y3, x4, y4)
    local den = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)
    if den == 0 then return nil end
    local ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / den
    local ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / den
    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
        return {x = x1 + ua*(x2-x1), y = y1 + ua*(y2-y1), dist = ua}
    end
    return nil
end

function player.getVisiblePolygon()
    local points = {player.x, player.y}
    local precision = 100 
    local startAngle = player.angle - player.fov/2
    for i = 0, precision do
        local angle = startAngle + (player.fov * (i / precision))
        local rx, ry = player.x + math.cos(angle)*player.viewDist, player.y + math.sin(angle)*player.viewDist
        local closest = {x = rx, y = ry, dist = 1}
        for _, w in ipairs(map.walls) do
            local s = {
                {x1=w.x, y1=w.y, x2=w.x+w.w, y2=w.y}, {x1=w.x, y1=w.y+w.h, x2=w.x+w.w, y2=w.y+w.h},
                {x1=w.x, y1=w.y, x2=w.x, y2=w.y+w.h}, {x1=w.x+w.w, y1=w.y, x2=w.x+w.w, y2=w.y+w.h}
            }
            for _, line in ipairs(s) do
                local hit = player.getIntersection(player.x, player.y, rx, ry, line.x1, line.y1, line.x2, line.y2)
                if hit and hit.dist < closest.dist then closest = hit end
            end
        end
        table.insert(points, closest.x)
        table.insert(points, closest.y)
    end
    return points
end

function player.update(dt)
    -- Movement with Wall Collision
    local moveX, moveY = 0, 0
    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end

-- Honestly I couldn't tell you what this does
    local length = math.sqrt(moveX^2 + moveY^2)
    if length > 0 then
        local dx = (moveX / length) * player.speed * dt
        local dy = (moveY / length) * player.speed * dt
        local nx, ny = player.x + dx, player.y + dy
        local hit = false
        for _, w in ipairs(map.walls) do
            if nx+player.radius > w.x and nx-player.radius < w.x+w.w and ny+player.radius > w.y and ny-player.radius < w.y+w.h then hit = true end
        end
        if not hit then player.x, player.y = nx, ny end
    end

    -- Rotation
    local mx, my = love.mouse.getPosition()
    local targetAngle = math.atan2(my - player.y, mx - player.x)
    local angleDiff = targetAngle - player.angle
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

    local rotationStep = player.rotationSpeed * dt
    if math.abs(angleDiff) > rotationStep then
        player.angle = player.angle + (angleDiff > 0 and rotationStep or -rotationStep)
    else
        player.angle = targetAngle
    end
end

-- Drawing the player and gun and stuff
function player.draw()
    love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(player.angle)
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", 15, 0, -10, 10, -10, -10)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", 10, -3, 20, 6)
    love.graphics.pop()
end

return player