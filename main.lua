local sti = require("sti") 
local player = require("player")
local weapon = require("weapon")
local enemy = require("enemy")

local shakeTime, shakeMag = 0, 0
local gameState = "menu"
local camX, camY = 0, 0
local map 

function love.load()
    map = sti("maps/lablevel.lua")
    player.load()
    weapon.load()
    enemy.list = {} 
    
    -- Optional: Spawn enemies to test
    -- enemy.spawn(400, 300)
end

function love.update(dt)
    if gameState == "playing" then
        map:update(dt)

        -- Camera Logic
        local sw, sh = love.graphics.getDimensions()
        camX = player.x - sw / 2
        camY = player.y - sh / 2

        -- Updates
        player.update(dt, camX, camY, map)
        weapon.update(dt)
        
        -- Screenshake Logic
        if weapon.shakeRequest > 0 then
            shakeMag, shakeTime = weapon.shakeRequest, 0.15
            weapon.shakeRequest = 0
        end
        shakeTime = math.max(0, shakeTime - dt)

        -- firing
        if love.mouse.isDown(1) then 
            weapon.fire(player.x, player.y, player.angle, map) 
        end
        
        -- enemy logic
        enemy.updateVisibility(player.x, player.y, player.angle, player.fov, player.viewDist, map)
        enemy.update(dt, player.x, player.y, map)

        -- death if u get touched by a red guy
        for _, e in ipairs(enemy.list) do
            local dist = math.sqrt((e.x - player.x)^2 + (e.y - player.y)^2)
            if dist < (e.radius + player.radius) then 
                gameState = "menu"
                love.load() 
            end
        end
    end
end


function love.keypressed(key) 
    if gameState == "menu" then
        if key == "return" then 
            gameState = "playing" 
        end
    elseif gameState == "playing" then
        if key == "q" or key == "e" then 
            weapon.switch() 
        elseif key == "r" then 
            love.event.quit("restart") 
        elseif key == "escape" then 
            gameState = "menu" 
        end
    end
end

function love.wheelmoved(x, y) 
    if gameState == "playing" and y ~= 0 then weapon.switch() end 
end

function love.draw()
    if gameState == "menu" then
        love.graphics.clear(0.05, 0.05, 0.05)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("EPICLOVEGAME PROTOTYPE v0.4", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("PRESS ENTER TO START", 0, 300, love.graphics.getWidth(), "center")
    else
        -- background grid
        local gridSize = 40
        love.graphics.setColor(0.05, 0.1, 0.05)
        for i = -gridSize, love.graphics.getWidth() + gridSize, gridSize do
            love.graphics.line(i - (camX % gridSize), 0, i - (camX % gridSize), love.graphics.getHeight())
            love.graphics.line(0, i - (camY % gridSize), love.graphics.getWidth(), i - (camY % gridSize))
        end

        -- sti map. sti doesnt stand for sexually transmitted infection dont worry
        love.graphics.setColor(1, 1, 1)
        map:draw(-camX, -camY)

        -- draw stuff
        love.graphics.push()
            love.graphics.translate(-camX, -camY)
            
            if shakeTime > 0 then
                local i = (shakeTime / 0.15) * shakeMag
                love.graphics.translate(love.math.random(-i, i), love.math.random(-i, i))
            end

            -- visione cone
            local poly = player.getVisiblePolygon(map)
            love.graphics.setColor(0, 1, 0, 0.1)
            if poly and #poly >= 6 then love.graphics.polygon("fill", poly) end
            
            enemy.draw()
            player.draw()
            weapon.draw(player.x, player.y)
        love.graphics.pop()

        -- ui
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