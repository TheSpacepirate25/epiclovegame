local player = {}

function player.load()
    player.x = 200
    player.y = 200
    player.speed = 100
    player.angle = 0
    player.radius = 12
    player.viewDist = 400
    player.fov = math.rad(60)
    player.rotationSpeed = math.pi * 1
end

-- Helper to check if a pixel is inside a Tiled 'walls' layer
local function checkStiHit(x, y, stiMap)
    if not stiMap or not stiMap.layers["walls"] then return false end
    local tw = stiMap.tilewidth
    local th = stiMap.tileheight
    -- Convert pixel coordinates to tile coordinates (Lua is 1-indexed)
    local tx = math.floor(x / tw) + 1
    local ty = math.floor(y / th) + 1
    
    -- Returns true if there is a tile at this location in the "walls" layer
    return stiMap.layers["walls"].data[ty] and stiMap.layers["walls"].data[ty][tx]
end

-- Used for line-of-sight and vision cone
function player.getVisiblePolygon(stiMap)
    local points = {player.x, player.y}
    local precision = 100 
    local startAngle = player.angle - player.fov/2
    
    for i = 0, precision do
        local angle = startAngle + (player.fov * (i / precision))
        local hitX, hitY = player.x + math.cos(angle)*player.viewDist, player.y + math.sin(angle)*player.viewDist
        
        -- Step through the ray to find a Tiled wall
        -- We check every 8 pixels along the line for better performance
        for d = 0, player.viewDist, 8 do
            local tx = player.x + math.cos(angle) * d
            local ty = player.y + math.sin(angle) * d
            if checkStiHit(tx, ty, stiMap) then
                hitX, hitY = tx, ty
                break
            end
        end
        table.insert(points, hitX)
        table.insert(points, hitY)
    end
    return points
end

function player.update(dt, camX, camY, stiMap)
    local moveX, moveY = 0, 0
    if love.keyboard.isDown("w") then moveY = moveY - 1 end
    if love.keyboard.isDown("s") then moveY = moveY + 1 end
    if love.keyboard.isDown("a") then moveX = moveX - 1 end
    if love.keyboard.isDown("d") then moveX = moveX + 1 end

    local length = math.sqrt(moveX^2 + moveY^2)
    if length > 0 then
        local dx = (moveX / length) * player.speed * dt
        local dy = (moveY / length) * player.speed * dt
        
        -- Movement with STI Wall Collision
        local nextX = player.x + dx
        -- Check collision on X axis (including player radius for padding)
        if not checkStiHit(nextX + (dx > 0 and player.radius or -player.radius), player.y, stiMap) then
            player.x = nextX
        end

        local nextY = player.y + dy
        -- Check collision on Y axis (including player radius for padding)
        if not checkStiHit(player.x, nextY + (dy > 0 and player.radius or -player.radius), stiMap) then
            player.y = nextY
        end
    end

    -- Aiming Fix: Account for camera scrolling
    local mx, my = love.mouse.getPosition()
    local worldMX = mx + (camX or 0)
    local worldMY = my + (camY or 0)
    
    local targetAngle = math.atan2(worldMY - player.y, worldMX - player.x)
    local angleDiff = targetAngle - player.angle
    
    -- Normalize angle differences to prevent 360-degree spins
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

    local rotationStep = player.rotationSpeed * dt
    if math.abs(angleDiff) > rotationStep then
        player.angle = player.angle + (angleDiff > 0 and rotationStep or -rotationStep)
    else
        player.angle = targetAngle
    end
end

function player.draw()
    love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(player.angle)
        
        -- Gun Barrel
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", 10, -3, 20, 6)
        
        -- Robot Body
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", 15, 0, -10, 10, -10, -10)
    love.graphics.pop()
end

return player