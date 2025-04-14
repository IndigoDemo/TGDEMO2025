local e = {}
 menger = require("/code/menger")
 mengerShader = menger.new()

function e.update(dt, color, iterations)
	mengerShader:update(dt, color, iterations)
end

function e.draw()
	mengerShader:draw()
end


return e