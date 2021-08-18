local file = io.open(path .. "../maps/" .. srv.map .. ".map", "rb")
local data = file:read("*all")
local bit = require("bit")
local band = bit.band

read_stream(data)
map.sha256 = srv.sha2.sha256(data)
map.header = read_line()

map.scroll = read_byte()
map.modifiers = read_byte()
map.tile_heights = read_byte()
map.use64px = read_byte()
for i = 1, 6 do
	read_byte()
end

map.uptime = read_int()
map.usgnid = read_int()
map.daylight = read_int()
for i = 1, 7 do
	read_int()
end

map.author = read_line()
map.program = read_line()
for i = 1, 8 do
	read_line()
end

map.string = read_line()
map.tilset = read_line()
map.tile_count = read_byte() + 1
map.width = read_int() + 1
map.height = read_int() + 1
map.background = read_line()
map.background_xspeed = read_int()
map.background_yspeed = read_int()
map.background_red = read_byte()
map.background_green = read_byte()
map.background_blue = read_byte()

map.header_test = read_line()

map.tile_modes = {}
for i = 1, map.tile_count do
	map.tile_modes[i-1] = read_byte()
end

for i = 1, map.tile_count do
	if map.tile_heights > 0 then
		if map.tile_heights == 1 then
			read_int()
		elseif map.tile_heights == 2 then
			read_short()
			read_byte()
		end
	end
end

map.tiles = {}
for x = 1, map.width do
	map.tiles[x] = {}
	for y = 1, map.height do
		map.tiles[x][y] = {}
		map.tiles[x][y].tileid = read_byte()
		map.tiles[x][y].mode = map.tile_modes[map.tiles[x][y].tileid]
	end
end

local modifier
if map.modifiers == 1 then
	for x = 1, map.width do
		for y = 1, map.height do
			modifier = read_byte()
			if band(modifier, 128) == 1 or band(modifier, 64) == 1 then
				if band(modifier, 64) == 1 or band(modifier, 128) == 1 then
					read_line()
				elseif band(modifier, 64) == 1 or band(modifier, 128) ~= 1 then
					read_byte()
				else
					read_byte()
					read_byte()
					read_byte()
					read_byte()
				end
			end
		end
	end
end

local name, type, x, y, trigger
map.t_spawn_x = {}
map.t_spawn_y = {}
map.t_spawn_count = 1
map.ct_spawn_x = {}
map.ct_spawn_y = {}
map.ct_spawn_count = 1
map.entity_count = read_int()
for i = 1, map.entity_count do
	name = read_line()
	type = read_byte()
	x = read_int()
	y = read_int()
	trigger = read_line()
	for j = 1, 10 do
		read_int()
		read_line()
	end
	if type == 0 then
		map.t_spawn_x[map.t_spawn_count] = x
		map.t_spawn_y[map.t_spawn_count] = y
		map.t_spawn_count = map.t_spawn_count + 1
	elseif type == 1 then
		map.ct_spawn_x[map.ct_spawn_count] = x
		map.ct_spawn_y[map.ct_spawn_count] = y
		map.ct_spawn_count = map.ct_spawn_count + 1
	end
end
