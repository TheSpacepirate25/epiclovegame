local player = require("player")
local weapon = require("weapon")
local map = require("map")
local enemy = require("enemy")

function love.load()
    map.load()
    player.load()
    enemy.spawn(100, 500)
    enemy.spawn(700, 500)
    enemy.spawn(400, 100)
end

function love.update(dt)
    player.update(dt)
    weapon.update(dt)
    
    if love.mouse.isDown(1) then
        weapon.fire(player.x, player.y, player.angle)
    end
    
    enemy.updateVisibility(player.x, player.y, player.angle, player.fov, player.viewDist)
    enemy.update(dt, player.x, player.y)

    for _, e in ipairs(enemy.list) do
        local d = math.sqrt((e.x - player.x)^2 + (e.y - player.y)^2)
        if d < (e.radius + player.radius) then 
            love.load()
        end
    end
end

function love.wheelmoved(x, y)
    if y ~= 0 then weapon.switch() end
end

function love.keypressed(key)
    if key == "q" or key == "e" then weapon.switch() end
    if key == "r" then love.load() end
end

function love.draw()
    map.draw()
    
    local poly = player.getVisiblePolygon()
    love.graphics.setColor(0, 1, 0, 0.1)
    if #poly >= 6 then 
        love.graphics.polygon("fill", poly) 
    end
    
    enemy.draw()
    player.draw()
    
    weapon.draw(player.x, player.y)
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("WEAPON: " .. weapon.list[weapon.current].name, 20, 20)
    
    local currentSwap = weapon.swapTimer or 0
    if currentSwap > 0 then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("STATUS: RECONFIGURING...", 20, 40)
        love.graphics.rectangle("line", 20, 60, 100, 10)
        ------------------------------------------ change this ↓ number and the number on line 61 of weapon.lua to change the weapon swap time in seconds
        love.graphics.rectangle("fill", 20, 60, (currentSwap / 1) * 100, 10)
    else
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print("STATUS: READY", 20, 40)
    end
end