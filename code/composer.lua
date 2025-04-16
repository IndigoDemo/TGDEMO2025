return { --this is the demo, guys. it's all here. that's the demo. 

----##------####----##----#####---######--#####--------------------
----##-----#---##-##--##--##--##--##------##--##-------------------
----##-----#---##-##--##--##---#--#####---#####--------------------
----##-----#---##-######--##--##--##------##--##-------------------
----######--####--##--##--####----######--##--##-------------------
	{	
		-- load function for the whole demo because i'm lazy and didn't want to 
		-- write a real loader. also, it loads fast as fuck anyway.
		-- yea, i said it. the loadingscreen is a phony. a big fat phony.

		load = function()
		demo.effect.loader = require ("code/loader")
		font = {one = gfx.newFont(math.floor(60*global.scale))}
		tallfont = gfx.newFont("media/ferrum.otf", math.floor(500*global.scale))
		thisfont = gfx.newFont("media/MTF Toast.ttf", math.floor(350*global.scale) )
		-- set global max, min, current-value for shader params
		global.noisestrength = {max = 1, min = .1, current = .1}

		-- load shaders and configure if necessary 
		-- deadline is nearing, code suffers.
		demo.shader.whirlpool = gfx.newShader[[ 
		    extern vec2 center = vec2(0.5, 0.5); 
		    extern number radius = 1.0;          
		    extern number strength = 10.0;       
		    extern number tightness = 3.0;       
		    
		    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
		    {
		        vec2 distance = texture_coords - center;
		        float dist = length(distance);
		        float angle = atan(distance.y, distance.x);
		        float swirl = strength * (1.0 - (dist / radius));
		        if (dist < radius) {
		            angle += swirl / tightness;
		            float newX = dist * cos(angle);
		            float newY = dist * sin(angle);
		            vec2 new_coords = center + vec2(newX, newY);
		            return Texel(tex, new_coords) * color;
		        } else {
		            return Texel(tex, texture_coords) * color;
		        }
		    }
		]]

		demo.shader.angry = require ("code/nastortion")
		demo.shader.angry:init()
		demo.shader.angry:setIntensity(0)
		demo.shader.c64 = require ("code/petscii")
		demo.shader.bloom = require ("code/bloomshader")
		demo.shader.vhs = require ("code/retroshader")
		demo.shader.negative = require ("code/negative")
		demo.shader.portal = require("code/mixmask")
		demo.shader.menger2 = require("code/menger2")
		demo.shader.menger3 = require("code/menger3")
		video = gfx.newVideo("media/dance.ogv")
		cuboid = demo.shader.menger2.new()
		cuboid2 = demo.shader.menger3.new()

		local resolution = {_w,_h}
		fluidX = {default = -_w, current = 0 } 
    	plx = -_h
    	demo.shader.vhs:send("resolution", resolution)
    	
		charData = require ("/code/chardata")
		noise = require ("/code/noise") 
		Arwing = require ("/code/arwing") 

    	-- create framebuffers 
		canvas1 		= gfx.newCanvas() --we're doing a shitload of shader combinations
		canvas2 		= gfx.newCanvas() --so we'll probably need them all
		canvas3 		= gfx.newCanvas() -- hope yall's got some vram
		canvas4 		= gfx.newCanvas() -- cuz we're using all of it
		canvas5 		= gfx.newCanvas() -- like the bastards we are
		vcanvas 		= gfx.newCanvas(1920,1080)
		squarecanvas 	= gfx.newCanvas(_w,_w)

		-- configure bloom-shader values for the different effects
		-- i'm not very good at coming up with names. 		
		
		---bakgrunn
		bloomEffect = demo.shader.bloom:new()
    	bloomEffect:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect:setBloomParams(0.3, 10, 200.0, 3)
		---tekst
		bloomEffect2 = demo.shader.bloom:new()
    	bloomEffect2:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect2:setBloomParams(0.1, 6, 500.0, 3)
		---outrun 
		bloomEffect3 = demo.shader.bloom:new()
   	 	bloomEffect3:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect3:setBloomParams(0.2, 10, 200.0, 3)
    	---spheretube
    	bloomEffect4 = demo.shader.bloom:new()
        bloomEffect4:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
        bloomEffect4:setBloomParams(0.2, 10, 200.0, 3)
        
       	-- load effects
		demo.effect.fluid 		= require ("code/fluid")
		demo.effect.fluid.load()
		
		demo.effect.tos 			= require("code/textonscreen")
		demo.effect.tos.load()
		
		demo.effect.c64 			= require ("code/c64")
		demo.effect.c64.load()

		demo.effect.meatballs 	= require("code/meatballs")
		demo.effect.meatballs.load()

		demo.effect.cube 		= require("code/twistcube")
		demo.effect.cube:load()

		demo.effect.outrun 		= require("code/outrun")
		demo.effect.outrun.load()

		demo.effect.spheretube 	= require("code/spheretube")
		demo.effect.spheretube.load()
		
		demo.effect.fractal = require("code/fractal")
		demo.effect.fractal.load()

		demo.effect.raycast 		= require("code/wallceiling")
		demo.effect.raycast.load()

		demo.effect.objv			= require("code/objviewer")
		demo.effect.objv.load("media/indigo.obj")
		
		demo.effect.plasma 		= require("code/plasma")
		demo.effect.menger 		= require("code/mengereffect")
		
		-- play that funky music, audio-boi
		love.audio.play(loadingsong)
		gfx.clear()
		end,
		
		update = function(dt)
			demo.effect.loader.update(dt)
		end,
		draw = function()
			demo.effect.loader.draw()
		
		end


	}
	
--------------------######----------------------------------------
--------------------------#---------------------------------------
----------------------####--------: fluid splash and text --------
---------------------#--------------------------------------------
--------------------#########-------------------------------------

	,
	{ 
	
	draw = function()
		--draw the background to effectcanvas
		demo.effect.fluid.draw() 
		-- switch canvas and render effectcanvas into canvas 1
		gfx.setCanvas(canvas1)
		gfx.draw(demo.effect.fluid.fluidcanvas)
		-- switch to canvas 2 and make the retroshader active
		gfx.setCanvas(canvas2)
		gfx.setShader(demo.shader.vhs)
		-- add bloom to canvas1 and render into canvas 2 with
		-- retroshader active
		bloomEffect:apply(canvas1)
		gfx.setCanvas()
		-- draw canvas 2 to screen and reset shader
		gfx.draw(canvas2, fluidX.current, 0)
		--gfx.draw(canvas2)
		gfx.setShader()
		-- set canvas 3, clear it, and render texteffect to it
		gfx.setCanvas(canvas3)
		gfx.clear()
		demo.effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		--gfx.clear()
		bloomEffect2:apply(canvas3)
	end, 
	update = function(dt)
		local num 
		-- update effects with vars
		demo.effect.tos.update(dt, t.pbeat)
		
		demo.effect.fluid.update(dt, t.pbeat, 0)
		demo.shader.vhs:send("time", love.timer.getTime())
		
		if t.pbeat > 26 then
			if fluidX.current > fluidX.default then 
				local deff = ((math.abs(fluidX.default) / func.diff(fluidX.current, fluidX.default))*dt*200)
				fluidX.current = fluidX.current - math.pow(deff,2) 
			
			end 
		end	
		-- check if we're directly on a beat, and modify the
		-- shaders parameters for a pulsing effect if we are
		local onbeat = false
		if math.floor(t.pbeat) == t.pbeat then
			onbeat = true
			global.noisestrength.current = global.noisestrength.max
		end 
		-- easing the parameters back to normal over time
		num = func.diff(global.noisestrength.min, global.noisestrength.current)
		global.noisestrength.current = global.noisestrength.current - num*(dt*10)
		--else
		--	num = .01	
		--end
		-- send parameters to shaders
		bloomEffect:setBloomParams(0.09, 10*num, 200.0, 3)
		demo.shader.vhs:send("vhsNoiseStrength", global.noisestrength.current)
		demo.shader.vhs:send("aberrationStrength", 1*num)
	end,
	},
----------------------#########-----------------------------------
------------------------------#-----------------------------------
--------------------------####-----: C64 Stuff and text ----------
------------------------------#-----------------------------------
----------------------########------------------------------------
 	{ 
	draw = function()
		if demo.effect.loader then demo.effect.loader = nil end 
		if t.pbeat > 47 and t.pbeat < 65 then 
			demo.effect.plasma.draw(0, 0)
		end 
		if t.pbeat > 31 then 
			demo.effect.cube.draw()
		end
		-- switch canvas and render effectcanvas into canvas 1
		gfx.setCanvas(canvas1)
		gfx.setColor(1,1,1,1)
		gfx.clear()
		gfx.setColor(0,0.23,1)
		gfx.rectangle("fill",0,0,_w,_h)
		gfx.setColor(1,1,1)

		if t.pbeat > 47 and t.pbeat < 64 then 
			gfx.draw(demo.effect.plasma.canvas, 0, plx)
		end
			
		if t.pbeat > 31 then 
			if woffset then 
				demo.tea = global.time
				woffset = false
			end
			woffs = ilib.transition(_w*5, 0, global.time, demo.tea + 10, "easeOut")
			gfx.draw(demo.effect.cube.canvas, woffs, 0)
		end
		gfx.setCanvas()
		-- draw canvas 2 to screen and reset shader
		if t.pbeat > 30 then gfx.setShader(demo.shader.c64) end 
		gfx.draw(canvas1)
		demo.effect.cube.draw()
		demo.effect.c64.draw()
		gfx.setShader()
		-- set canvas 3, clear it, and render texteffect to it
		gfx.setCanvas(canvas3)
		gfx.clear()
		demo.effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		bloomEffect2:apply(canvas3)
	end, 
	
	update = function(dt)
		local num 
		if t.pbeat > 47 and t.pbeat < 62 then 
			boing = func.diff(plx, 0)
			plx = plx + ( boing * dt * 1.5)
			if plx > 0 then plx = 0 end 
		end
		-- update effects with vars
		demo.effect.cube.update(dt)
		demo.effect.plasma.update(dt)
		demo.effect.tos.update(dt, t.pbeat)
		--demo.effect.fluid.update(dt, t.pbeat)
		demo.shader.vhs:send("time", love.timer.getTime())
		-- check if we're directly on a beat, and modify the
		-- shaders parameters for a pulsing effect if we are
		if t.pbeat>31 then 
			local onbeat = false
			if math.floor(t.pbeat) == t.pbeat then
				onbeat = true
				demo.effect.plasma.speed = 5
				global.noisestrength.current = global.noisestrength.max
			end 
			-- easing the parameters back to normal over time
			
			if demo.effect.plasma.speed > 1.5 then 
				demo.effect.plasma.speed = demo.effect.plasma.speed - dt*10
			end
			--print (demo.effect.plasma.speed)
			num = func.diff(global.noisestrength.min, global.noisestrength.current)
			global.noisestrength.current = global.noisestrength.current - num*(dt*10)
		else
			num = .01	
		end
		-- send parameters to shaders
		bloomEffect:setBloomParams(0.09, 10*num, 200.0, 3)
		demo.shader.vhs:send("vhsNoiseStrength", global.noisestrength.current)
		demo.shader.vhs:send("aberrationStrength", 10*num)
		demo.effect.c64.update(dt, t.pbeat)
	end,
	
	}, 

----------------------#----#--------------------------------------
----------------------#----#--------------------------------------
----------------------######------: Menger Wall and Invert--------
---------------------------#--------------------------------------
---------------------------#--------------------------------------

	{
	update = function(dt)
		if demo.effect.fluid then demo.effect.fluid = nil end		

		demo.coleur = demo.coleur + .001 
		demo.effect.tos.update(dt, t.pbeat)
		demo.effect.menger.update(dt, demo.coleur, 4)
		demo.effect.meatballs.update(dt)	
		local onbeat = math.floor(t.pbeat) 
		if t.pbeat == onbeat and onbeat > global.oldbeat then 
			global.oldbeat = onbeat
		end
	end
	, 
	
	draw = function()
		gfx.setCanvas(canvas1)
		demo.effect.menger:draw()
		gfx.setCanvas()
		demo.effect.meatballs.draw()
		demo.shader.negative:send("maskTexture", demo.effect.meatballs.canvas)
		gfx.setCanvas(canvas5)
		gfx.setShader(demo.shader.negative)
		gfx.draw(canvas1)
		gfx.setShader()
		gfx.setCanvas()
		gfx.draw(canvas5)
		gfx.setCanvas(canvas3)
		gfx.clear()
		demo.effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		bloomEffect2:apply(canvas3)
	end 
	}, 

---------------------#######--------------------------------------
---------------------##-------------------------------------------
---------------------######---------: Menger Cube and dancer 1----
---------------------------#--------------160 - 192---------------
---------------------#######--------------------------------------

	{ 
	update = function (dt)
		if demo.effect.cube then demo.effect.cube = nil end
		if demo.effect.plasma then demo.effect.plasma = nil end 
		if math.floor(t.pbeat) == 188 then
			mengIterations = 2
		end 
		if math.floor(t.pbeat) == 189 then
			mengIterations = 3
		end 
		if math.floor(t.pbeat) == 190 then
			mengIterations = 4
		end 
		if math.floor(t.pbeat) == 191 then
			mengIterations = 5
		end 

		cuboid:update(dt, global.time, t.pbeat)
		cuboid2:update(dt, global.time, t.pbeat, mengIterations)
		
		if global.videoplaying == false then 
			video:seek(29)
			video:play()
			demo.effect.tos.setIndex(63)
			global.videoplaying = true
		end
		


		demo.effect.tos.update(dt, t.pbeat, 1)
	end, 

	draw = function()
		gfx.setCanvas(vcanvas) 
		gfx.draw(video, _w*.3, _h/2, 0, 1, 1, _w/2, _h/2)
		demo.shader.portal:send("maskTexture", vcanvas)
		gfx.setCanvas()
		gfx.setCanvas(canvas2)
		gfx.clear()
		cuboid:draw()
		demo.shader.portal:send("alternateTexture", canvas2)
		gfx.setCanvas()
		gfx.setCanvas(canvas3)
		gfx.clear()
		cuboid2:draw()
		gfx.setCanvas()
		gfx.setShader(demo.shader.portal)
		gfx.clear()
		gfx.draw(canvas3)
		gfx.setShader()
		gfx.setCanvas(canvas4)
		gfx.clear()
		demo.effect.tos.draw()
		gfx.setCanvas(canvas5)
		gfx.clear()
		bloomEffect2:apply(canvas4)
		gfx.setCanvas()
		gfx.setColor(1,1,1,demo.effect.tos.getalpha())
		gfx.draw(canvas5)
		gfx.setColor(1,1,1,1)
		if t.pbeat < 192 then 
			demo.effect.tos.draw2()
		end
	end, 
	},

-------------------------######-----------------------------------
-------------------------##---------------------------------------
-------------------------#####------: Outrun Synthwave -----------
-------------------------##---#-----------------------------------
--------------------------#####-----------------------------------
{
	update = function(dt)
		if math.floor(t.pbeat) == t.pbeat then
			onbeat = true
		else 
			onbeat = false
		end

		demo.effect.outrun.update(dt, onbeat, t.pbeat)
		demo.shader.vhs:send("time", love.timer.getTime())
    	demo.shader.vhs:send("vhsNoiseStrength", .1)
    	demo.shader.vhs:send("aberrationStrength", .001)
	end, 

	draw = function()
		local sine = math.sin(global.time/10)
		gfx.setCanvas(background)
    	gfx.clear()
    	demo.effect.outrun.drawBackground()
    	gfx.setCanvas(landscape)
    	gfx.clear()
   	 	bloomEffect3:apply(background)
    	demo.effect.outrun.drawLandscape()
    	gfx.setCanvas(shiplayer)
    	gfx.clear()
    	demo.effect.outrun.drawShips()
       	gfx.setCanvas(scroller)
    	gfx.clear()
    	demo.effect.outrun.drawScroller()
       	gfx.setColor(1, 1, 1, 1)
    	gfx.setCanvas()
    	gfx.clear()
    	gfx.setShader(demo.shader.vhs)
    	gfx.draw(landscape, screenWidth/2, screenHeight/2, sine*.19, 1.3, 1.3, screenWidth/2 , screenHeight/2)
    	gfx.draw(shiplayer, screenWidth/2, screenHeight/2, sine*.19, 1.3, 1.3, screenWidth/2, screenHeight/2)
    	gfx.setColor(1, 1, 1, 1)
    	gfx.setShader()
    	-- draw the scroller framebuffer
    	gfx.draw(scroller, 0, screenHeight*-.7, 0, 2, 4)		
	end
	}, 
	
-------------------------######-----------------------------------
-----------------------------##-----------------------------------
---------------------------##-----: TODO PLACEHOLDER -------------
--------------------------##--------------------------------------
--------------------------##--------------------------------------

	{ 

	update = function (dt)
		if not tsize then 
			tsize = 1
		else
			if tsize > 1 then tsize = tsize - dt end
		end 
		if t.pbeat == math.floor(t.pbeat) then 
			tsize = 2
		end
	end, 

	draw = function()
		local text = "//TODO:"
		local textHeight = font.one:getHeight(text) 
		local textWidth = font.one:getWidth(text) 
		gfx.setFont(font.one)
		gfx.setColor(.2,1,.2)
		gfx.print(text, _w, _h, 0, tsize, tsize, textWidth/2, textHeight/2)
		gfx.setColor(1,1,1)
	end, 
	}, 

-------------------------######-----------------------------------
------------------------#------#----------------------------------
-------------------------######------: tube glitch  --
------------------------#------#----------------------------------
-------------------------######-----------------------------------
	{
	update = function (dt)
		local boost = 1 
		if not shaderset then 
			
			demo.shader.angry:combineShaders({"pixelSort", "rgbSplit"})
			shaderset = true
		end

		global.color = global.color + 1
		if global.color > 8 then global.color = 1 end
		global.z = math.sin(global.time)*45
		global.y = global.y - 2 
		global.x = global.x - 3
		if global.x < 1 then global.x = 90 end
		if global.y < 1 then global.y = 90 end
		if global.z > 90 then global.z = 1 end

		for i = 1, 45 do 
			demo.effect.spheretube.blink(global.x,i, 1)
			demo.effect.spheretube.blink(global.y,i, 6)
		end
		
		for i = 1, 90 do 
			demo.effect.spheretube.blink(i, math.floor(global.z), 4)
		end
	
		demo.shader.angry:update(dt)
		demo.incdt = demo.incdt + (dt*50*boost)  

		demo.spherefov = demo.spherefov - demo.incdt
		if demo.spherefov < -180 then demo.spherefov = 180 end
		--print (demo.spherefov)
		sx, sy, sz = 0,global.time *.3,global.time
		
		if isInt(t.pbeat) then 
			boost = 6
			demo.effect.spheretube.setSphereCam(math.sin(global.time)*200, math.cos(global.time)*200, 100)
			demo.effect.spheretube.update(dt, demo.spherefov, sx+boost, sy, sz)
			demo.plusminus = -demo.plusminus	
			plox = 0 
		else
			demo.effect.spheretube.update(dt)
			plox = plox + dt*3
			if plox > 1 then plox = 1 end
		end
		demo.shader.angry:setIntensity(plox)

		if t.pbeat > 240 then 
			demo.effect.tos.setIndex(62)
			demo.effect.tos.update(dt, t.pbeat, nil) 
		end
	end, 

	draw = function(arg)
		local effectlist = {"pixelSort", "rgbSplit", "waveDist", "glitch", "vhs", "pixelation", "scanLines", "crtWarp"}
		local indexer = math.floor(math.random()*#effectlist)+1
		local indexer2 = math.floor(math.random()*#effectlist)+1
		gfx.clear()
		if demo.plusminus == 1 then
			demo.shader.angry:combineShaders( {effectlist[indexer],effectlist[indexer2]})
			demo.effect.spheretube.draw("sphere")
		else
			demo.shader.angry:combineShaders({"waveDist", "glitch"})
			demo.effect.spheretube.draw()
		end
		gfx.setCanvas(canvas1)
		gfx.clear()
		gfx.draw(demo.effect.spheretube.spherecanvas)	
		if t.pbeat > 240 and t.pbeat < 255 then 
			demo.effect.tos.draw()
		end
		gfx.setCanvas(canvas2)
		gfx.clear()
		bloomEffect4:apply(canvas1)
		gfx.setCanvas()
		gfx.setShader(demo.shader.angry:getActiveShader())
		gfx.clear()
		gfx.draw(canvas2)
		gfx.setShader()
		
	end
	}, 

-------------------------#######----------------------------------
------------------------#------#----------------------------------
-------------------------#######----: Menger Cube and dancer 2 ---
-------------------------------#----------------------------------
------------------------########----------------------------------
	{ 
	update = function (dt)
		local colors = {h = 1, s = .1}
		local beatfactor = {default = -1, max = 10}		
		local iter = 3
		local oldbeat = 0 
		local dummyangle = 0 
		cubeangle = {0.785, 1.57, 2.356, 3.14, 3.93, 4.71, 5.5, 6.28}

		if t.pbeat > 220 then 
			beatfactor.default = .2
			beatfactor.max = .2
		end

		cuboid:update(dt, global.time, t.pbeat, colors, iter, true)
		cuboid2:update(dt, global.time, t.pbeat, 1)
		cuboid:setBeatFactor(beatfactor)
		
		if t.pbeat == math.floor(t.pbeat) and math.floor(t.pbeat) > oldbeat + 4 then 
			oldbeat = math.floor (t.pbeat)
			demo.effect.aindex = demo.effect.aindex + 1
			dummyangle  = 0 
			if demo.effect.aindex > #cubeangle then demo.effect.aindex = 1 end
		end

		if dummyangle < 1 then 
			dummyangle = dummyangle + func.diff(dummyangle, 5) * dt*2 
		end		

		if t.pbeat < 220 then 
			demo.currentangle = demo.currentangle + dummyangle/10
		end

		if demo.currentangle > 6.28 then 
			demo.currentangle = demo.currentangle - 6.28
		end 

		if global.videoplaying == false then 
			video:seek(29)
			video:play()
			demo.effect.tos.setIndex(63)
			global.videoplaying = true
			
		end
		demo.effect.tos.update(dt, t.pbeat, 1)
	end, 

	draw = function(dt)
		gfx.reset()
		-- set up the mask (video stream) and send it to the shader
		gfx.setCanvas(vcanvas) 
		gfx.draw(video, _w*.4, _h/2, 0, 1.5, 1.5, _w/2, _h/2)
		demo.shader.negative:send("maskTexture", vcanvas)
		-- draw the menger cube into a square canvas for easier rotation
		gfx.setCanvas(squarecanvas) 
		gfx.clear()
		cuboid:draw2()
		-- send the square canvas trough the twisty shader and draw it into canvas 3
		gfx.setCanvas(canvas2) 
		gfx.setShader(demo.shader.whirlpool)
		gfx.clear()
		gfx.draw(squarecanvas, _w/2, _h/2, demo.currentangle, 1.2, 1.2, _w/2, _w/2) --fraktal med maske nå i canvas 3
		gfx.setShader()
		-- draw canvas 3 (twisty menger) into canvas 4 with the negative shader enabled
		gfx.setCanvas(canvas4)
		gfx.setShader(demo.shader.negative)
		gfx.draw(canvas2)
		gfx.setShader()
		-- draw the main textlayer into canvas 5
		gfx.setCanvas(canvas5)
		gfx.clear()
		demo.effect.tos.draw()
		-- apply bloom to canvas 5 (main text layer) and put it into canvas 1
		gfx.setCanvas(canvas1)
		gfx.clear()
		bloomEffect2:apply(canvas5)
		gfx.setColor(1,1,1,1)
		gfx.setCanvas()	
		-- draw canvas 4 (twisty, negative-masked menger) to screen
		gfx.draw(canvas4)
		-- set alpha values and draw canvas1 (bloomy main text layer) to screen 
		gfx.setColor(1,1,1,demo.effect.tos.getalpha())
		gfx.draw(canvas1)
		gfx.setColor(1,1,1,1)
		-- draw textlayer 2 to screen 
		if t.pbeat < 224 then 
			demo.effect.tos.draw2()
		end
	end, 
	},
------------------##----#######-----------------------------------
----------------####---##-----##----------------------------------
------------------##---##-----##----: pretty fucking fractal
------------------##---##-----##----------------------------------
------------------##----#######-----------------------------------
	{
	update = function(dt)
		
		if global.videoplaying == true then 
			video:seek(0)
			video:play()
			demo.effect.tos.setIndex(63)
			global.videoplaying = false
		end

		if isInt(t.pbeat) then 
			demo.beatfact.current = 70
			if t.pbeat > 79 then 
				demo.rtrig[1] = 1
			end
			if t.pbeat > 80 then 
				demo.rtrig[2] = 1
			end
			if t.pbeat > 81 then 
				demo.rtrig[3] = 1
				demo.rtrig[1] = 0
			end
			if t.pbeat > 82 then 
				demo.rtrig[4] = 1
				demo.rtrig[2] = 0
			end
			if t.pbeat > 83 then 
				demo.rtrig[5] = 1
				demo.rtrig[3] = 0
			end
			if t.pbeat > 84 then 
				demo.rtrig[4] = 0
			end
			if t.pbeat > 85 then 
				demo.rtrig[5] = 0
				demo.rtrig[6] = 1
			end
			if t.pbeat > 87 then 
				demo.rtrig[6] = 0
			end
		end
		
		for i = 1, 6 do 
			if demo.rtrig[i] == 1 and demo.rscale[i] < 1 then 
				demo.rscale[i] = demo.rscale[i] + func.diff(demo.rscale[i], 1) * dt * 6
			end
			if demo.rtrig[i] == 0 and demo.rypos[i] < 1 then 
				demo.rypos[i] = demo.rypos[i] + func.diff(demo.rypos[i], 1) * dt * 6
			end
		end

			if demo.beatfact.current > demo.beatfact.default then 
				demo.beatfact.current = demo.beatfact.current - (func.diff(demo.beatfact.current, demo.beatfact.default) * dt * 4)
			end
		demo.effect.fractal.update(dt, demo.beatfact.current)
		
		if t.pbeat > 92 then 
			if isInt(t.pbeat) then 
				demo.effect.objv.setvars(8, 2)
				demo.effect.objv.update(dt)
			end
		end
		if t.pbeat < 92 then demo.effect.objv.update(dt) end
		if t.pbeat > 92 and t.pbeat < 150 then demo.gendalpha = demo.gendalpha - dt * 8 end
	end, 

	draw = function()
		demo.effect.fractal.draw()
		gfx.setCanvas(canvas1)
		gfx.clear()
		gfx.setColor(1,1,1,1)
		local textlist = {"I","N","D","I","G","O"}
		gfx.setFont(tallfont)
		for i = 1, 6 do 
			local textWidth = tallfont:getWidth(textlist[2])
			local textHeight = tallfont:getHeight(textlist[i])
			gfx.setColor (1,1,1,1)
			gfx.rectangle("fill", (i*(_w/6))-_w/6, _h*demo.rypos[i], _w/6, _h*demo.rscale[i])
			gfx.setColor (0,0,0,1)
	
			gfx.print(textlist[i], (i*(_w/6)-textWidth*1.5), _h/2-(textHeight*.65), 0, 1, 2, -textWidth/2 )
		end
		gfx.setColor(1,1,1,1)
		gfx.setCanvas()
		demo.shader.negative:send("maskTexture", canvas1)
		gfx.setCanvas(canvas2)
		gfx.setShader(demo.effect.fractal.shader)
		gfx.rectangle("fill",0,0,_w,_h)
		gfx.setShader()
		gfx.setCanvas(canvas4)
		gfx.setShader(demo.shader.negative)
		gfx.draw(canvas2)
		gfx.setShader()
		gfx.setCanvas()
		
		gfx.setColor(1,1,1,demo.gendalpha)
		gfx.draw(canvas4)
		
		if t.pbeat > 88 and t.pbeat < 150 then  
			demo.effect.objv.draw()
		end		
	end
	}, 
------------------##---##----------------------------------------
----------------####-####-----------------------------------------
------------------##---##-----------: Conway on an infinite plane
------------------##---##-----------------------------------------
------------------##---##-----------------------------------------
	{ 
		load = function()
			demo.effect.raycast.load()
		end, 

		update = function(dt)
			demo.gendalpha = 1
			if set11shader == false then 
				demo.shader.angry:combineShaders({"pixelSort", "glitch"})
				set11shader=true
			end 
			demo.effect.objv.resetvars()
			demo.effect.raycast.update(dt)
			demo.effect.objv.update(dt)
			if t.pbeat > 288 then 
				demo.endalpha = demo.endalpha - dt *.5 
				demo.shader.angry:update(dt)
				demo.shader.angry:setIntensity(demo.angerintensity)
			else
				demo.endalpha = 1
			end
			
		end, 

		draw = function()
			demo.effect.raycast.draw()
			gfx.setCanvas(canvas1)
			gfx.draw(demo.effect.raycast.outputcanvas)
			gfx.setCanvas()
			
			gfx.setCanvas(canvas2)
			gfx.setColor(1,1,1,1)
				gfx.clear()
				demo.effect.objv.draw()
			gfx.setCanvas()
			gfx.setCanvas(canvas3)
			gfx.setColor(1,1,1,1)
			gfx.clear()
			gfx.setShader(demo.shader.angry:getActiveShader())
				gfx.draw(canvas2)
			gfx.setShader()
			gfx.setCanvas()
		
			gfx.setColor(1,1,1,demo.endalpha)
			gfx.draw(canvas1)
			gfx.setColor(1,1,1,1)
			if t.pbeat > 292 then 
				gfx.draw(canvas3)
				
			else
				gfx.draw(canvas2)
			end
			if t.pbeat > 290 then 
				demo.lastalpha = demo.lastalpha + global.delta *.3
				demo.angerintensity = demo.angerintensity + global.delta *.3
				local text = "Vote With Your Heart: Vote Indigo"
				local textWidth = font.one:getWidth(text)
				love.graphics.setFont(font.one)
				gfx.setColor(1,1,1,demo.lastalpha)
				gfx.print(text, _w*.5, _h*.8, 0, global.scale, global.scale, textWidth/2 )
				gfx.setColor(1,1,1,1)
			end
		end
	}
}