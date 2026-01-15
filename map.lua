local map = {}
map.walls = {}

function map.load()
    -- Expanded Outer Boundaries
    table.insert(map.walls, {x = -1000, y = -1000, w = 3000, h = 40})
    table.insert(map.walls, {x = -1000, y = 2000, w = 3000, h = 40})
    table.insert(map.walls, {x = -1000, y = -1000, w = 40, h = 3000})
    table.insert(map.walls, {x = 2000, y = -1000, w = 40, h = 3000})
    
    -- Interior Walls
    table.insert(map.walls, {x = 300, y = 100, w = 20, h = 250})
    table.insert(map.walls, {x = 500, y = 350, w = 200, h = 20})
end

function map.draw()
    -- Draw an expanded background grid
    love.graphics.setColor(0.05, 0.1, 0.05)
    for i = -1000, 2000, 40 do
        love.graphics.line(i, -1000, i, 2000)
        love.graphics.line(-1000, i, 2000, i)
    end
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    for _, w in ipairs(map.walls) do
        love.graphics.rectangle("fill", w.x, w.y, w.w, w.h)
    end
end

return map