local map = {}
map.walls = {}

function map.load()
    -- Outer Boundaries
    table.insert(map.walls, {x = 0, y = 0, w = 800, h = 20})
    table.insert(map.walls, {x = 0, y = 580, w = 800, h = 20})
    table.insert(map.walls, {x = 0, y = 0, w = 20, h = 600})
    table.insert(map.walls, {x = 780, y = 0, w = 20, h = 600})
    
    -- Interior Walls
    table.insert(map.walls, {x = 300, y = 100, w = 20, h = 250})
    table.insert(map.walls, {x = 500, y = 350, w = 200, h = 20})
end

function map.draw()
    love.graphics.setColor(0.05, 0.1, 0.05)
    for i = 0, 800, 40 do
        love.graphics.line(i, 0, i, 600)
        love.graphics.line(0, i, 800, i)
    end
    love.graphics.setColor(0.2, 0.2, 0.2)
    for _, w in ipairs(map.walls) do
        love.graphics.rectangle("fill", w.x, w.y, w.w, w.h)
    end
end

return map