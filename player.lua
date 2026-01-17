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

local function checkStiHit(x, y, stiMap)
    if not stiMap or not stiMap.layers["walls"] then return false end
    local tw = stiMap.tilewidth
    local th = stiMap.tileheight
    local tx = math.floor(x / tw) + 1
    local ty = math.floor(y / th) + 1
    
    return stiMap.layers["walls"].data[ty] and stiMap.layers["walls"].data[ty][tx]
end

-- uses old visible polygon drawing nonsense from v0.2 i think
function player.getVisiblePolygon(map)
    local px, py = math.floor(player.x), math.floor(player.y)
    local points = {px, py}
    local precision = 120 
    
    for i = 0, precision do
        local a = (player.angle - player.fov/2) + (player.fov * (i / precision))
        local cosA = math.cos(a)
        local sinA = math.sin(a)
        
        local hitX = px + cosA * player.viewDist
        local hitY = py + sinA * player.viewDist
        
        for d = 0, player.viewDist, 16 do
            local tx = px + cosA * d
            local ty = py + sinA * d
            
            if checkStiHit(tx, ty, map) then
                -- finds exact pixel edge and makes it look more like a cone and less like a bunch of rectangles being drawn. 
                -- i mean thats exactly what we're doing but the player doesnt need to know that
                for refine = d - 16, d do
                    local rx = px + cosA * refine
                    local ry = py + sinA * refine
                    if checkStiHit(rx, ry, map) then
                        hitX, hitY = rx, ry
                        break
                    end
                end
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
        
        -- X axis collision (uses checkStiHit)
        local nextX = player.x + dx
        if not checkStiHit(nextX + (dx > 0 and player.radius or -player.radius), player.y, stiMap) then
            player.x = nextX
        end

        -- Y axis collision (uses checkStiHit)
        local nextY = player.y + dy
        if not checkStiHit(player.x, nextY + (dy > 0 and player.radius or -player.radius), stiMap) then
            player.y = nextY
        end
    end

    local mx, my = love.mouse.getPosition()
    local worldMX = mx + (camX or 0)
    local worldMY = my + (camY or 0)
    
    local targetAngle = math.atan2(worldMY - player.y, worldMX - player.x)
    local angleDiff = targetAngle - player.angle
    
    -- normalize angle to prevent spinning in circles
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
        

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", 10, -3, 20, 6)
        

        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", 15, 0, -10, 10, -10, -10)
    love.graphics.pop()
end

return player