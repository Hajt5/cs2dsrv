local sqrt = math.sqrt
local pi = math.pi
local floor = math.floor
local cos = math.cos
local sin = math.sin
local range, startx, starty, temprot, rotx, roty, tilex, tiley
local tilemode

function pnt(s)
	local line = os.date("[%X] ") .. s
	table.insert(srv.logs, line)
	print(line)
end

function append_logs()
	file = io.open(path .. "../sys/logs/" .. os.date("%d-%b-%Y") .. ".txt", "a")
	file:write(table.concat(srv.logs, "\n") .. "\n")
	file:close()
	srv.logs = {}
end

function status1()
	local status = 0
	if srv.password ~= "" then
		status = status + 1
	end
	if srv.usgnonly == 1 then
		status = status + 2
	end
	if srv.fow == 1 then
		status = status + 4
	end
	if srv.friendlyfire == 1 then
		status = status + 8
	end
	if true then
		status = status + 16
	end
	if srv.gamemode ~= 0 then
		status = status + 32
	end
	if srv.luascripts == 1 then
		status = status + 64
	end
	if srv.forcelight == 1 then
		status = status + 128
	end
	return status
end

function status2()
	local status = 0
	if srv.recoil == 1 then
		status = status + 1
	end
	if srv.offscreendamage == 1 then
		status = status + 2
	end
	if srv.hasdownloads == 1 then
		status = status + 4
	end
	return status
end

function getid(addr)
	for i = 1, 32 do
		if srv.players[i] == nil then
			ip, port = addr:match("([^,]+):([^,]+)")
			srv.players[i] = srv.conns[addr]
			srv.players[i].ip = ip
			srv.players[i].port = port
			srv.players[i].team = 0
			srv.players[i].favteam = 0
			srv.players[i].look = 0
			srv.players[i].score = 0
			srv.players[i].deaths = 0
			srv.players[i].assists = 0
			srv.players[i].mvp = 0
			srv.players[i].x = 0
			srv.players[i].y = 0
			srv.players[i].rot = 0
			srv.players[i].mouse = 0
			srv.players[i].health = 0
			srv.players[i].armor = 0
			srv.players[i].money = 0
			srv.players[i].weapon = 0
			srv.players[i].weaponmode = 0
			srv.players[i].reload = 0
			srv.players[i].ping = 0
			srv.conns[addr].id = i
			return i
		end
	end
end

function hex(s)
	return (s:gsub("..", function (c)
		return string.char(tonumber(c, 16))
	end))
end

function tohex(s)
	return (s:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

-- https://gist.github.com/Elemecca/6361899
function hexdump(str)
	local len = string.len(str)
	local dump = ""
	local hex = ""
	local asc = ""
	for i = 1, len do
		if 1 == i % 16 then
			dump = dump .. hex .. asc .. "\n"
			hex = string.format("%04x: ", i - 1)
			asc = ""
		end
		local ord = string.byte(str, i)
		hex = hex .. string.format("%02x ", ord)
		if ord >= 32 and ord <= 126 then
			asc = asc .. string.char(ord)
		else
			asc = asc .. "."
		end
	end
	dump = dump:sub(2)
	return dump .. hex .. string.rep("   ", 16 - len % 16) .. asc
end

function onfire(id)
	range = wpn[srv.players[id].weapon].range
	startx = srv.players[id].x
	starty = srv.players[id].y
	temprot = floor(srv.players[id].rot / 182)

	if temprot < 0 then
		temprot = 360 - (temprot * -1)
	end
	temprot = 360 - temprot

	temprot = temprot + 90
	if temprot > 360 then
		temprot = temprot - 360
	end

	rotx = cos(temprot * pi / 180)
	roty = sin(temprot * pi / 180)

	for i = 1, range do
		startx = startx + (i * rotx)
		starty = starty - (i * roty)

		tilex = floor(startx / 32)
		tiley = floor(starty / 32)

		if tilex < 0 or tiley < 0 or tilex >= map.width or tiley >= map.height then
			break
		end

		tilemode = map.tiles[tilex+1][tiley+1].mode
		if tilemode == 1 or tilemode == 3 or tilemode == 5 then
			break
		end

		for j, v in ipairs(srv.players) do
			if v.health > 0 and v.team ~= srv.players[id].team then
				if sqrt((v.x - startx) * (v.x - startx) + (v.y - starty) * (v.y - starty)) <= 16 then
					onhit(id, j, srv.players[id].weapon)
					return
				end
			end
		end
	end
end

function onhit(id, victim, weapon)
	srv.players[victim].health = srv.players[victim].health - wpn[weapon].dmg
	if srv.players[victim].health < 0 then
		onkill(id, victim, weapon)
		srv.players[victim].health = 0
	end
	write_stream()
	write_byte(17)
	write_byte(victim)
	write_byte(id)
	write_byte(srv.players[victim].health)
	write_byte(0)
	send_to_all(close_stream(), 1)
end

function onkill(id, victim, weapon)
	if id > 0 then
		pnt(srv.players[id].name .. " killed " .. srv.players[victim].name .. " with " .. wpn[weapon].name)
		srv.players[id].money = srv.players[id].money + 300
	end
	write_stream()
	write_byte(19)
	write_byte(victim)
	write_byte(id)
	write_byte(0)
	write_byte(weapon)
	write_short(srv.players[victim].x)
	write_short(srv.players[victim].y)
	send_to_all(close_stream(), 1)
end

function serverlist_add()
	pnt("Sending serverlist ADD-request...")
	write_stream()
	write_byte(1)
	write_byte(0)
	write_byte(27)
	write_byte(1)
	srv.udp:sendto(close_stream(), "81.169.236.243", 36963)
end

function serverlist_update()
	pnt("Sending serverlist UPDATE-request...")
	write_stream()
	write_byte(1)
	write_byte(0)
	write_byte(28)
	write_byte(1)
	srv.udp:sendto(close_stream(), "81.169.236.243", 36963)
end
