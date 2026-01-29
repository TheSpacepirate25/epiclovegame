local sti = require("sti") 
local player = require("player")
local weapon = require("weapon")
local enemy = require("enemy")

local shakeTime, shakeMag = 0, 0
local gameState = "menu"
local camX, camY = 0, 0
local map 
local scanOffset = 0

-- Boot Sequence Variables
local isBooting = false
local bootProgress = 0
local bootText = "INITIALIZING..."
local startupSound -- Define this here

function love.load()
    map = sti("maps/lablevel.lua")
    player.load()
    weapon.load()
    enemy.list = {} 
    
    -- Load your hard drive sound here
    -- startupSound = love.audio.newSource("sfx/startup.wav", "static")
end

function love.update(dt)
    -- Handle the Loading Bar logic
    if isBooting then
        bootProgress = bootProgress + dt * 0.4 -- Fills in about 2.5 seconds
        
        -- Flavor text changes based on progress
        if bootProgress < 0.3 then bootText = "ACQUIRING SECBOT.."
        elseif bootProgress < 0.6 then bootText = "EXTENDING COMMS ANTENNA"
        elseif bootProgress < 0.9 then bootText = "INITIALIZING OPERATIOR UI.."
        else bootText = "READY." end

        if bootProgress >= 1 then
            isBooting = false
            gameState = "playing"
            bootProgress = 0
        end
    end

    if gameState == "playing" then
        map:update(dt)
        scanOffset = (scanOffset + dt * 60) % love.graphics.getHeight()

        local sw, sh = love.graphics.getDimensions()
        camX = player.x - sw / 2
        camY = player.y - sh / 2

        player.update(dt, camX, camY, map)
        weapon.update(dt)
        
        if weapon.shakeRequest > 0 then
            shakeMag, shakeTime = weapon.shakeRequest, 0.15
            weapon.shakeRequest = 0
        end
        shakeTime = math.max(0, shakeTime - dt)

        if love.mouse.isDown(1) then 
            weapon.fire(player.x, player.y, player.angle, map) 
        end
        
        enemy.updateVisibility(player.x, player.y, player.angle, player.fov, player.viewDist, map)
        enemy.update(dt, player.x, player.y, map)

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
    if gameState == "menu" and not isBooting then
        if key == "return" then 
            isBooting = true 
            if startupSound then startupSound:play() end
        end
    elseif gameState == "playing" then
        if key == "q" or key == "e" then 
            weapon.switch() 
        elseif key == "r" then 
            weapon.reload() -- Manual reload for the robot
        elseif key == "escape" then 
            gameState = "menu" 
        end
    end
end

function love.wheelmoved(x, y) 
    if gameState == "playing" and y ~= 0 then weapon.switch() end 
end

local function drawScanlines()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.2)
    for i = 0, h, 4 do love.graphics.line(0, i, w, i) end
    love.graphics.setColor(0, 1, 0, 0.03)
    love.graphics.rectangle("fill", 0, scanOffset, w, 30)
end

function love.draw()
    if gameState == "menu" then
        love.graphics.clear(0.05, 0.05, 0.05)
        love.graphics.setColor(0, 1, 0)
        
        if not isBooting then
            love.graphics.printf(">> TERMINAL IDLE", 0, 250, love.graphics.getWidth(), "center")
            love.graphics.printf("PRESS [ENTER] TO BOOT UNIT", 0, 300, love.graphics.getWidth(), "center")
        else
            -- Loading Bar Drawing
            local bW, bH = 200, 20
            local bX, bY = (love.graphics.getWidth()-bW)/2, 280
            love.graphics.printf(">> " .. bootText, 0, 250, love.graphics.getWidth(), "center")
            love.graphics.rectangle("line", bX, bY, bW, bH)
            love.graphics.rectangle("fill", bX + 4, bY + 4, (bW - 8) * bootProgress, bH - 8)
        end
        drawScanlines()
    else
        -- Background Grid
        local gridSize = 40
        love.graphics.setColor(0.02, 0.08, 0.02)
        for i = -gridSize, love.graphics.getWidth() + gridSize, gridSize do
            love.graphics.line(i - (camX % gridSize), 0, i - (camX % gridSize), love.graphics.getHeight())
            love.graphics.line(0, i - (camY % gridSize), love.graphics.getWidth(), i - (camY % gridSize))
        end

        love.graphics.setColor(1, 1, 1)
        map:draw(-math.floor(camX), -math.floor(camY))

        love.graphics.push()
            love.graphics.translate(-math.floor(camX), -math.floor(camY))
            
            if shakeTime > 0 then
                local i = (shakeTime / 0.15) * shakeMag
                love.graphics.translate(love.math.random(-i, i), love.math.random(-i, i))
            end

            local poly = player.getVisiblePolygon(map)
            love.graphics.setColor(0, 1, 0, 0.12)
            if poly and #poly >= 6 then love.graphics.polygon("fill", poly) end
            
            enemy.draw()
            player.draw()
            weapon.draw(player.x, player.y)
        love.graphics.pop()

        -- HUD Display
        local wp = weapon.list[weapon.current]
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 80, 20)
        love.graphics.print("WEAPON: " .. wp.name, 20, 20)
        love.graphics.print("MAG: " .. wp.ammo .. " / " .. wp.magSize, 20, 40)
        
        -- Draw Loading/Reconfiguring/Reloading Bars
        local barY = 65
        if weapon.reloadTimer > 0 then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("CYCLING MAGAZINE...", 20, barY)
            love.graphics.rectangle("line", 20, barY + 20, 100, 10)
            love.graphics.rectangle("fill", 20, barY + 20, (1 - (weapon.reloadTimer / wp.reloadTime)) * 100, 10)
        elseif weapon.swapTimer > 0 then
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print("RECONFIGURING...", 20, barY)
            love.graphics.rectangle("line", 20, barY + 20, 100, 10)
            love.graphics.rectangle("fill", 20, barY + 20, (weapon.swapTimer / 1.5) * 100, 10)
        end

        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.print("SIGNAL_STRENGTH: NOMINAL", 20, love.graphics.getHeight() - 30)

        drawScanlines()
    end
end