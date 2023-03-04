
local nb = 12
local dir
local radius = radius or 6

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

return { generator = function()
	local sradius = (radius + 0.5) * (engine.Map.tile_w + engine.Map.tile_h) / 2
	local ad = rng.float(0, 360)
	local a = math.rad(ad)
	local r = 0
	local x = r * math.cos(a)
	local y = r * math.sin(a)
	local static = rng.percent(40)
	local vel = sradius * ((24 - nb * 1.4) / 24) / 12

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
		trail = 1,
		life = 12,
		size = 12 - (12 - nb) * 0.7, sizev = 0, sizea = 0,

		x = x, xv = 0, xa = 0,
		y = y, yv = 0, ya = 0,
		dir = a, dirv = 0, dira = 0,
		vel = rng.float(vel * 0.6, vel * 1.2), velv = 0, vela = 0,

		r = returnR, rv = colorRV, ra = colorRA,
		g = returnG, gv = colorBV, ga = colorBA,
		b = returnB, bv = colorGV, ba = colorGA,
		a = returnA, av = colorAV, aa = colorAA,
	}
end, },
function(self)
	if nb > 0 then
		local i = math.min(nb, 6)
		i = (i * i)*0.5 * radius
		self.ps:emit(i*density)
		nb = nb - 1
	end
end,
30*radius*7*12,
"particle_cloud"