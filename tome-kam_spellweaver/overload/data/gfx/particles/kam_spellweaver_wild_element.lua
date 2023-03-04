-- Based on arcane_power's particles.
can_shift = true
base_size = 32

local colorRLow = colorRLow or 0
local colorRTop = colorRTop or 0
local colorBLow = colorBLow or 0
local colorBTop = colorBTop or 0
local colorGLow = colorGLow or 0
local colorGTop = colorGTop or 0
local colorALow = colorALow or 0
local colorATopAlt = colorATopAlt or 0
local colorRLowAlt = colorRLowAlt or 0
local colorRTopAlt = colorRTopAlt or 0
local colorBLowAlt = colorBLowAlt or 0
local colorBTopAlt = colorBTopAlt or 0
local colorGLowAlt = colorGLowAlt or 0
local colorGTopAlt = colorGTopAlt or 0
local colorALowAlt = colorALowAlt or 0
local colorATopAlt = colorATopAlt or 0
local colorRV = colorRV or 0
local colorRA = colorRA or 0
local colorBV = colorBV or 0
local colorBA = colorBA or 0
local colorGV = colorGV or 0
local colorGA = colorGA or 0
local colorAV = colorAV or 0
local colorAA = colorAA or 0
local density = density or 1

return { 
	blend_mode=core.particles.BLEND_SHINY, 
	generator = function()
		local ad = rng.range(0, 360)
		local a = math.rad(ad)
		local dir = math.rad(90)
		local r = rng.range(18, 22)
		local dirchance = rng.chance(2)
		local x = rng.range(-16, 16)
		local y = 16 - math.abs(math.sin(x / 16) * 8)

		local returnR
		local returnG
		local returnB
		local returnA
		
		if (colorATopAlt == 0) or (rng.percent(50)) then
			returnR = (rng.range(colorRLow, colorRTop))/255
			returnG = (rng.range(colorGLow, colorGTop))/255
			returnB = (rng.range(colorBLow, colorBTop))/255
			returnA = (rng.range(colorALow, colorATop))/255
		else
			returnR = (rng.range(colorRLowAlt, colorRTopAlt))/255
			returnG = (rng.range(colorGLowAlt, colorGTopAlt))/255
			returnB = (rng.range(colorBLowAlt, colorBTopAlt))/255
			returnA = (rng.range(colorALowAlt, colorATopAlt))/255
		end

		return {
			trail = 0,
			life = rng.range(10, 18),
			size = rng.range(2, 4), sizev = 0, sizea = 0.003,

			x = x, xv = 0, xa = 0,
			y = y, yv = 0, ya = -0.2,
			dir = 0, dirv = 0, dira = 0,
			vel = 0, velv = 0, vela = 0,

			r = returnR, rv = colorRV, ra = colorRA,
			g = returnG, gv = colorBV, ga = colorBA,
			b = returnB, bv = colorGV, ba = colorGA,
			a = returnA * rng.range(100, 255) / 255, av = -0.03, aa = 0,
		}
	end, 
},
function(self)
	self.ps:emit(math.max(1, density * 4))
end,
40, "particles_images/transpcircle"