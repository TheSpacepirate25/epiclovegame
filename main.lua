local player = require("player")
local weapon = require("weapon")
local map = require("map")
local enemy = require("enemy")

local shakeTime, shakeMag = 0, 0
local gameState = "menu"
local camX, camY = 0, 0

function love.load()
    map.load()
    player.load()
    enemy.list = {} 
    enemy.spawn(100, 500)
    enemy.spawn(700, 500)
    enemy.spawn(400, 100)
end

function love.update(dt)
    if gameState == "playing" then
        -- Update Camera position centered on player
        local sw, sh = love.graphics.getDimensions()
        camX = player.x - sw / 2
        camY = player.y - sh / 2

        -- Pass camera offsets to player for the aiming fix
        player.update(dt, camX, camY)
        weapon.update(dt)
        
        if weapon.shakeRequest > 0 then
            shakeMag, shakeTime = weapon.shakeRequest, 0.15
            weapon.shakeRequest = 0
        end
        shakeTime = math.max(0, shakeTime - dt)

        if love.mouse.isDown(1) then 
            weapon.fire(player.x, player.y, player.angle) 
        end
        
        enemy.updateVisibility(player.x, player.y, player.angle, player.fov, player.viewDist)
        enemy.update(dt, player.x, player.y)

        for _, e in ipairs(enemy.list) do
            if math.sqrt((e.x - player.x)^2 + (e.y - player.y)^2) < (e.radius + player.radius) then 
                gameState = "menu"
                love.load() 
            end
        end
    end
end

function love.wheelmoved(x, y) 
    if gameState == "playing" and y ~= 0 then weapon.switch() end 
end

function love.keypressed(key) 
    if gameState == "menu" then
        if key == "return" then gameState = "playing" end
    elseif gameState == "playing" then
        if key == "q" or key == "e" then weapon.switch() 
        elseif key == "r" then love.load() 
        elseif key == "escape" then gameState = "menu" end
    end
end

function love.draw()
    if gameState == "menu" then
        love.graphics.clear(0.05, 0.05, 0.05)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("LABORATORY INFILTRATOR", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("PRESS ENTER TO START", 0, 300, love.graphics.getWidth(), "center")
    else
        love.graphics.push()
            -- Apply Camera Translation
            love.graphics.translate(-camX, -camY)
            
            if shakeTime > 0 then
                local i = (shakeTime / 0.15) * shakeMag
                love.graphics.translate(love.math.random(-i, i), love.math.random(-i, i))
            end

            map.draw()
            local poly = player.getVisiblePolygon()
            love.graphics.setColor(0, 1, 0, 0.1)
            if #poly >= 6 then love.graphics.polygon("fill", poly) end
            
            enemy.draw()
            player.draw()
            weapon.draw(player.x, player.y)
        love.graphics.pop()

        -- UI Elements (Drawn in Screen Space, unaffected by camera)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("WEAPON: " .. weapon.list[weapon.current].name, 20, 20)
        local sw = weapon.swapTimer or 0
        if sw > 0 then
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print("RECONFIGURING...", 20, 40)
            love.graphics.rectangle("line", 20, 60, 100, 10)
            love.graphics.rectangle("fill", 20, 60, (sw / 1.5) * 100, 10)
        end
    end
end