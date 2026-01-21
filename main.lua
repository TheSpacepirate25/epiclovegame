local sti = require("sti") 
local player = require("player")
local weapon = require("weapon")
local enemy = require("enemy")

local shakeTime, shakeMag = 0, 0
local gameState = "menu"
local camX, camY = 0, 0
local map 
local scanOffset = 0

function love.load()
    map = sti("maps/lablevel.lua")
    player.load()
    weapon.load()
    enemy.list = {} 
end

function love.update(dt)
    if gameState == "playing" then
        map:update(dt)

        -- rolling scanline animation like on old tvs
        scanOffset = (scanOffset + dt * 60) % love.graphics.getHeight()

        -- camera logic 
        local sw, sh = love.graphics.getDimensions()
        camX = player.x - sw / 2
        camY = player.y - sh / 2

        player.update(dt, camX, camY, map)
        weapon.update(dt)
        
        -- screenshake on weapon shoot
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

        -- death logic
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
        if key == "return" then gameState = "playing" end
    elseif gameState == "playing" then
        if key == "q" or key == "e" then weapon.switch() 
        elseif key == "r" then love.event.quit("restart") 
        elseif key == "escape" then gameState = "menu" end
    end
end

function love.wheelmoved(x, y) 
    if gameState == "playing" and y ~= 0 then weapon.switch() end 
end

-- crt scanline effect
local function drawScanlines()
    local w, h = love.graphics.getDimensions()
    
    -- horizontal lines also like a crt
    love.graphics.setColor(0, 0, 0, 0.2) -- adjust 0.2 for darker/lighter lines if you want
    love.graphics.setLineWidth(1)
    for i = 0, h, 4 do
        love.graphics.line(0, i, w, i)
    end

    -- moving referesh bar
    love.graphics.setColor(0, 1, 0, 0.03)
    love.graphics.rectangle("fill", 0, scanOffset, w, 30)
end

function love.draw()
    if gameState == "menu" then
        love.graphics.clear(0.05, 0.05, 0.05)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf(">> TERMINAL BOOT SEQUENCE v0.4", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("PRESS [ENTER] TO ACCESS FEED", 0, 300, love.graphics.getWidth(), "center")
        drawScanlines()
    else
        -- background grid
        local gridSize = 40
        love.graphics.setColor(0.02, 0.08, 0.02)
        for i = -gridSize, love.graphics.getWidth() + gridSize, gridSize do
            love.graphics.line(i - (camX % gridSize), 0, i - (camX % gridSize), love.graphics.getHeight())
            love.graphics.line(0, i - (camY % gridSize), love.graphics.getWidth(), i - (camY % gridSize))
        end

        -- draw map
        love.graphics.setColor(1, 1, 1)
        map:draw(-math.floor(camX), -math.floor(camY))

        love.graphics.push()
            love.graphics.translate(-math.floor(camX), -math.floor(camY))
            
            if shakeTime > 0 then
                local i = (shakeTime / 0.15) * shakeMag
                love.graphics.translate(love.math.random(-i, i), love.math.random(-i, i))
            end

            -- vision cone
            local poly = player.getVisiblePolygon(map)
            love.graphics.setColor(0, 1, 0, 0.12)
            if poly and #poly >= 6 then love.graphics.polygon("fill", poly) end
            
            enemy.draw()
            player.draw()
            weapon.draw(player.x, player.y)
        love.graphics.pop()

        -- ui overlay
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 80, 20)
        love.graphics.print("SIGNAL_STRENGTH: NOMINAL", 20, love.graphics.getHeight() - 30)
        love.graphics.print("CURRENT_LOADOUT: " .. weapon.list[weapon.current].name, 20, 20)
        
        local sw = weapon.swapTimer or 0
        if sw > 0 then
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print("RECONFIGURING...", 20, 45)
            love.graphics.rectangle("line", 20, 65, 100, 10)
            love.graphics.rectangle("fill", 20, 65, (sw / 1.5) * 100, 10)
        end

        drawScanlines()
    end
end