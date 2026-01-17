local sti = require("sti") -- Swapped map.lua for STI
local player = require("player")
local weapon = require("weapon")
local enemy = require("enemy")

local shakeTime, shakeMag = 0, 0
local gameState = "menu"
local camX, camY = 0, 0
local map -- Global variable to hold the STI map object

function love.load()
    -- Load the Tiled map export from your maps folder
    map = sti("maps/lablevel.lua")
    
    player.load()
    -- Ensure spawn is at a valid coordinate in your Tiled map
    player.x = 200
    player.y = 200

    enemy.list = {} 
    -- enemy.spawn(100, 500) -- Removed for now per your request
end

function love.update(dt)
    if gameState == "playing" then
        -- Update STI internal logic (animations, etc.)
        map:update(dt)

        -- Update Camera position centered on player
        local sw, sh = love.graphics.getDimensions()
        camX = player.x - sw / 2
        camY = player.y - sh / 2

        -- Pass 'map' to player.update for the new Tiled collision logic
        player.update(dt, camX, camY, map)
        weapon.update(dt)
        
        if weapon.shakeRequest > 0 then
            shakeMag, shakeTime = weapon.shakeRequest, 0.15
            weapon.shakeRequest = 0
        end
        shakeTime = math.max(0, shakeTime - dt)

        -- Pass 'map' to weapon.fire so rays can hit Tiled walls
        if love.mouse.isDown(1) then 
            weapon.fire(player.x, player.y, player.angle, map) 
        end
        
        -- Note: If you re-enable enemies, updateVisibility will need map support too
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
        love.graphics.printf("EPICLOVEGAME PROTOTYPE v0.4", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("PRESS ENTER TO START", 0, 300, love.graphics.getWidth(), "center")
    else
        -- 1. Draw your custom background grid (keep it aligned to camera)
        local gridSize = 40
        love.graphics.setColor(0.05, 0.1, 0.05)
        for i = -gridSize, love.graphics.getWidth() + gridSize, gridSize do
            love.graphics.line(i - (camX % gridSize), 0, i - (camX % gridSize), love.graphics.getHeight())
            love.graphics.line(0, i - (camY % gridSize), love.graphics.getWidth(), i - (camY % gridSize))
        end

        -- 2. Draw the STI Map layers
        map:draw(-camX, -camY)

        -- 3. Draw World Objects (Player, Vision, Weapons)
        love.graphics.push()
            love.graphics.translate(-camX, -camY)
            
            if shakeTime > 0 then
                local i = (shakeTime / 0.15) * shakeMag
                love.graphics.translate(love.math.random(-i, i), love.math.random(-i, i))
            end

            -- Updated: Pass 'map' to your visibility logic
            local poly = player.getVisiblePolygon(map)
            love.graphics.setColor(0, 1, 0, 0.1)
            if #poly >= 6 then love.graphics.polygon("fill", poly) end
            
            enemy.draw()
            player.draw()
            weapon.draw(player.x, player.y)
        love.graphics.pop()

        -- 4. UI Elements (Screen Space)
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