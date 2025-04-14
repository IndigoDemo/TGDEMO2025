local e = {}

function e.load()
lbheight = -1 --should be 0 
rbheight = 1 -- should be 0 
tbwidth = 1 -- should be 0 
bbwidth = -1 -- should be 0
intbeat = 0 
alpha = 0 
end

function e.update(dt, beat)
	
	if not firstbeat then 
		firstbeat = beat
	end
	intbeat = beat - firstbeat
	
	if intbeat > 0 then 
		if intbeat < 4 then
			alpha = alpha + dt*9
			if alpha > 1 then alpha = 1
			end
		end

		lbheight=lbheight+(dt*3)
		if lbheight > 0 then lbheight = 0 end
	end
	if intbeat > 1 then 
		bbwidth=bbwidth+(dt*3)
		if bbwidth > 0 then bbwidth = 0 end
	end
	if intbeat > 2 then 
		rbheight=rbheight-(dt*3)
		if rbheight < 0 then rbheight = 0 end
	end
	if intbeat > 3 then 
		tbwidth=tbwidth-(dt*3)
		if tbwidth < 0 then tbwidth = 0 end
	end

	if intbeat > 4 then 
		alpha = alpha - dt*7
		if alpha < 0 then alpha = 0 end
	end

end

function e.draw()
		love.graphics.setColor (0,0,0,alpha)
		love.graphics.rectangle("fill",0,0, _w, _h)

		love.graphics.setColor (func.toRGB(108, 94, 181),1)
		love.graphics.rectangle("fill",0, _h*lbheight, _w*.1, _h) --left border
		love.graphics.rectangle("fill",_w*.9, _h*rbheight, _w*.1, _h)--right border
		love.graphics.rectangle("fill",_w*tbwidth, 0, _w, _h*.1)--top border
		love.graphics.rectangle("fill",_w*bbwidth, _h*.9, _w, _h*.1)--bottom border



end

return e