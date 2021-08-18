local id, mid, join_state
local chat_message_type, chat_message
local team, look
local specpos_x, specpos_y
local ts
local weapon, ammoin, ammo, weaponmode
local reload_status
local pos
local floor = math.floor
local random = math.random
local tmp
local encrypted_pw
local item
local spray_x, spray_y, spray_color
local name

function confirmation(addr)
	srv.conns[addr].lastconf = read_short()
	return get_position()
end

function connection_setup(addr)
	read_short() -- uptime in ms
	return get_position()
end

function fire(id)
	srv.players[id].reload = 0
	onfire(id)
	read_byte()
	write_stream()
	write_byte(7)
	write_byte(id)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function weapon_special(id)
	srv.players[id].reload = 0
	srv.players[id].weaponmode = read_byte()
	return get_position()
end

function weapon_switch(id)
	srv.players[id].reload = 0
	srv.players[id].weapon = read_byte()
	srv.players[id].weaponmode = read_byte()
	write_stream()
	write_byte(9)
	write_byte(id)
	write_byte(srv.players[id].weapon)
	write_byte(srv.players[id].weaponmode)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function move(id)
	srv.players[id].x = read_short()
	srv.players[id].y = read_short()
	write_stream()
	write_byte(10)
	write_byte(id)
	write_short(srv.players[id].x)
	write_short(srv.players[id].y)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function walk(id)
	srv.players[id].x = read_short()
	srv.players[id].y = read_short()
	write_stream()
	write_byte(11)
	write_byte(id)
	write_short(srv.players[id].x)
	write_short(srv.players[id].y)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function reload(id)
	srv.players[id].reload = os.clock() + 1.1
	read_byte()
	write_stream()
	write_byte(16)
	write_byte(id)
	write_byte(1)
	send_to_all(close_stream(), 1)
	return get_position()
end

function usgn_unknown(data)
	read_byte()
	read_byte()
	read_byte()
	read_byte()
	read_byte()
	read_byte()
	return get_position()
end

function change_team(id)
	team = read_byte()
	look = read_byte()
	if team == 4 then
		team = random(1, 2)
	end
	if look == 4 then
		look = random(1, 3)
	end
	if team == 0 and look == 5 then
		pnt(srv.players[id].name .. " joins spectators")
		if srv.players[id].health > 0 then
			onkill(0, id, 0)
		end
		look = 0
		srv.players[id].team = team
		srv.players[id].look = look
	end
	if team >= 1 and team <= 2 and look <= 3 and look >= 0 then
		if team == 1 then
			pnt(srv.players[id].name .. " joins terrorists")
		else
			pnt(srv.players[id].name .. " joins counter-terrorists")
		end
		if srv.players[id].health > 0 and srv.players[id].team ~= 0 then
			onkill(0, id, 0)
		end
		srv.players[id].team = team
		srv.players[id].look = look
	end
	write_stream()
	write_byte(20)
	write_byte(id)
	write_byte(team)
	write_byte(look)
	send_to_all(close_stream(), 1)
	return get_position()
end

function buy(id)
	item = read_short()
	pnt(srv.players[id].name .. " tried to buy " .. wpn[item].name)
	--[[
	TODO:
	- check if in buyzone
	- check if enough money
	- check if already own
	- check if buytime over
	--]]
	return get_position()
end

function drop_weapon(id)
	weapon = read_byte()
	ammoin = read_short()
	ammo = read_short()
	weaponmode = read_byte()
	write_stream()
	write_byte(24)
	write_byte(id)
	write_byte(weapon)
	write_short(ammoin)
	write_short(ammo)
	write_byte(0)
	write_byte(1)
	write_byte(0)
	write_short(floor(srv.players[id].x / 32))
	write_short(floor(srv.players[id].y / 32))
	write_byte(50)
	send_to_all(close_stream(), 1)
	return get_position()
end

function serverlist_added()
	read_byte()
	pnt("Server added to serverlist")
	return get_position()
end

function serverlist_updated()
	read_byte()
	pnt("Serverlist entry updated")
	return get_position()
end

function spray(id)
	spray_x = read_short()
	spray_y = read_short()
	read_byte() -- 02
	spray_color = read_byte()
	return get_position()
end

function spec_pos(id)
	read_short()
	read_short()
	return get_position()
end

function spawn(id)
	if srv.players[id].team >= 2 then
		tmp = random(map.ct_spawn_count - 1)
		srv.players[id].x = (map.ct_spawn_x[tmp] + 0.5) * 32
		srv.players[id].y = (map.ct_spawn_y[tmp] + 0.5) * 32
	elseif srv.players[id].team == 1 then
		tmp = random(map.t_spawn_count - 1)
		srv.players[id].x = (map.t_spawn_x[tmp] + 0.5) * 32
		srv.players[id].y = (map.t_spawn_y[tmp] + 0.5) * 32
	end
	srv.players[id].health = 100
	srv.players[id].weapon = 3
	write_stream()
	write_byte(21)
	write_byte(id)
	write_short(srv.players[id].x)
	write_short(srv.players[id].y)
	write_byte(srv.players[id].weapon)
	write_byte(0) -- bomb/defkit
	write_short(srv.players[id].money)
	write_byte(3) -- weapons
	write_byte(3)
	write_byte(32)
	write_byte(50)
	send_to_all(close_stream(), 1)
	return get_position()
end

function spectating(id)
	read_byte()
	return get_position()
end

function message(id)
	chat_message_type = read_byte()
	chat_message = read_string(read_byte() * 2)
	read_byte()
	write_stream()
	write_byte(240)
	write_byte(id)
	write_byte(chat_message_type)
	write_byte(#chat_message * 2)
	write_string(chat_message)
	write_byte(0)
	if chat_message_type == 1 then
		send_to_all(close_stream(), 1)
	elseif chat_message_type == 2 then
		send_to_team(id, close_stream(), 1)
	end
	return get_position()
end

function join(data, addr, id)
	join_state = read_byte()
	if join_state == 0 then
		srv.conns[addr].lastconf = 0
		srv.conns[addr].lastsent = 2
		write_stream()
		write_byte(252)
		write_byte(0)
		write_byte(#srv.secret)
		write_string(srv.secret)
		send(close_stream(), addr, 1)
		return get_position()
	elseif join_state == 1 then
		srv.conns[addr].name = read_string(read_byte())
		srv.conns[addr].password = read_string(read_byte())
		srv.conns[addr].auth = read_string(read_byte())
		srv.conns[addr].version = read_short()
		srv.conns[addr].usgn = read_int()
		srv.conns[addr].usgnname = read_string(read_short())
		srv.conns[addr].os = read_byte()
		srv.conns[addr].steamname = read_string(read_short())
		srv.conns[addr].steamid = read_long()
		srv.conns[addr].sprayname = read_string(read_byte())
		srv.conns[addr].auth2 = read_string(read_byte())
		read_byte() -- 00
		read_byte() -- 02
		read_byte() -- f4
		read_byte() -- 31
		read_byte() -- 03
		srv.conns[addr].screenw = read_int()
		srv.conns[addr].screenh = read_int()
		srv.conns[addr].language = read_string(read_short())
		srv.conns[addr].language_iso = read_string(read_short())
		srv.conns[addr].widescreen = read_byte()
		srv.conns[addr].micsupport = read_byte()
		srv.conns[addr].windowed = read_byte()
		write_stream()
		write_byte(252)
		write_byte(2)
		write_byte(0)
		write_byte(getid(addr))
		write_byte(#srv.map)
		write_string(srv.map)
		write_byte(#srv.secret)
		write_string(srv.secret)
		send(close_stream(), addr, 1)
		return get_position()
	elseif join_state == 3 then
		srv.conns[addr].checksum1 = read_string(read_byte()) -- SHA256
		srv.conns[addr].checksum2 = read_string(read_byte())
		read_byte() -- 06
		write_stream()
		write_byte(252)
		write_byte(4)
		write_byte(0) -- https://pastebin.com/SaeXVkVm
		send(close_stream(), addr, 1)
		return get_position()
	elseif join_state == 5 then
		srv.conns[addr].map = read_string(read_byte())
		srv.conns[addr].checksum3 = read_string(read_byte()) -- SHA256
		write_stream()
		write_byte(252)
		write_byte(6)
		write_byte(0)
		write_byte(#srv.map)
		write_string(srv.map)
		write_byte(#srv.name)
		write_string(srv.name)
		write_short(srv.t_score)
		write_short(srv.ct_score)
		write_byte(srv.roundtime)
		write_byte(srv.freezetime)
		write_byte(srv.c4timer)
		write_byte(50)
		write_byte(50)
		write_byte(0)
		write_byte(0)
		write_byte(1)
		write_byte(0)
		write_byte(srv.maxplayers)
		write_byte(srv.fow)
		write_byte(srv.specmode)
		write_byte(srv.gamemode)
		write_byte(srv.respawndelay)
		write_byte(srv.infammo)
		write_byte(srv.radar)
		write_byte(#srv.supplyitems)
		for i = 1, #srv.supplyitems do
			write_byte(srv.supplyitems[i])
		end
		write_byte(0)
		write_byte(srv.hud)
		write_byte(srv.flashlight)
		write_byte(srv.smokeblock)
		write_byte(srv.hovertext)
		write_byte(srv.friendlyfire)
		write_byte(#map.background)
		write_string(map.background)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(1)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(3)
		write_byte(2) -- mp_lagcompensation
		write_byte(0)
		write_byte(16) -- mp_lagcompensationdivisor
		write_byte(0)
		write_byte(114)
		write_byte(2)
		write_byte(1)
		write_byte(0)
		write_byte(1)
		write_byte(1)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(3)
		write_byte(65) -- A
		write_byte(67) -- C
		write_byte(75) -- K
		send(close_stream(), addr, 1)
		pnt(srv.players[id].name .. " connected")
		write_stream()
		write_byte(252)
		write_byte(7)
		write_byte(1)
		write_byte(#srv.players)
		for i, v in ipairs(srv.players) do
			if i ~= id then
				write_byte(i)
				write_byte(#v.name)
				write_encoded_string(v.name)
				write_int(v.usgn)
				write_byte(v.os)
				if v.usgn > 0 and v.steamid > 0 then
					write_short(#v.usgnname)
					write_string(v.usgnname)
					write_long(v.steamid)
					write_short(#v.steamname)
					write_string(v.steamname)
				else
					write_short(#v.steamname)
					write_string(v.steamname)
					write_long(v.steamid)
					write_short(#v.usgnname)
					write_string(v.usgnname)
				end
				write_byte(v.team)
				write_byte(v.favteam)
				write_byte(v.look)
				write_short(v.score + 1000)
				write_short(v.deaths)
				write_short(v.assists)
				write_short(v.mvp)
				write_byte(0)
				write_short(v.x)
				write_short(v.y)
				write_short(v.rot)
				write_byte(v.health)
				write_byte(v.armor)
				write_byte(0)
				write_byte(v.weapon)
				write_byte(v.weaponmode)
				write_byte(0)
				write_byte(255)
				write_byte(255)
			end
		end
		write_byte(id)
		write_byte(#srv.players[id].name)
		write_encoded_string(srv.players[id].name)
		write_int(srv.players[id].usgn)
		write_byte(srv.players[id].os)
		write_short(#srv.players[id].steamname)
		write_string(srv.players[id].steamname)
		write_long(srv.players[id].steamid)
		write_short(#srv.players[id].usgnname)
		write_string(srv.players[id].usgnname)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_short(srv.players[id].score + 1000)
		write_short(srv.players[id].deaths)
		write_short(srv.players[id].assists)
		write_short(srv.players[id].mvp)
		for i=1,13 do write_byte(0) end
		write_byte(255)
		write_byte(255)
		send(close_stream(), addr, 1)
		send(hex("fc070100"), addr, 1) -- player data
		send(hex("fc070200"), addr, 1) -- hostage data
		send(hex("fc070300"), addr, 1) -- item data
		send(hex("fc070400"), addr, 1) -- entity data
		send(hex("fc070500"), addr, 1) -- dyn object data
		send(hex("fc070600"), addr, 1) -- projectile data
		send(hex("fc070a00"), addr, 1) -- resource paths data
		send(hex("fc070700"), addr, 1) -- dyn object img data
		send(hex("fc070800"), addr, 1) -- tween data
		send(hex("fc070900"), addr, 1) -- custom tile data
		send(hex("fc070b7c00a5000000789c15cc490ec2400c04c0f1" ..
		"321325087109905cc2be1dc2f683fc02c15bfaefb42fa5b6dbb" ..
		"208acd6c00465ee02af33a90ac98d63d1cf1c4dd50a922d1549" ..
		"5789ac396ac7e44382d886f836d22ed29ef407321d493905e76" ..
		"82fc1d5207a8b2f23c7e11ebb07793f49fb0a3e6cf3d779f723" ..
		"f607ab2c161c"), addr, 1) -- weapon settings
		send(hex("fc070c00"), addr, 1) -- idk
		send(hex("fc070d00"), addr, 1) -- idk
		send(hex("fc07c80341434b1c0001"), addr, 1) -- ACK
		write_stream()
		write_byte(248)
		write_byte(id)
		write_byte(#srv.players[id].name)
		write_string(srv.players[id].name)
		write_byte(0)
		write_int(srv.players[id].usgn)
		write_short(#srv.players[id].usgnname)
		write_string(srv.players[id].usgnname)
		write_long(srv.players[id].steamid)
		write_short(#srv.players[id].steamname)
		write_string(srv.players[id].steamname)
		send_to_all_others(id, close_stream(), 1)
		return get_position()
	elseif join_state == 10 then
		return #data
	end
end

function rot(id)
	srv.players[id].rot = read_short()
	srv.players[id].mouse = read_byte()
	write_stream()
	write_byte(70)
	write_byte(id)
	write_short(srv.players[id].rot)
	write_byte(srv.players[id].mouse)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function rotmove(id)
	srv.players[id].x = read_short()
	srv.players[id].y = read_short()
	srv.players[id].rot = read_short()
	srv.players[id].mouse = read_byte()
	write_stream()
	write_byte(71)
	write_byte(id)
	write_short(srv.players[id].x)
	write_short(srv.players[id].y)
	write_short(srv.players[id].rot)
	write_byte(srv.players[id].mouse)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function rotwalk(id)
	srv.players[id].x = read_short()
	srv.players[id].y = read_short()
	srv.players[id].rot = read_short()
	srv.players[id].mouse = read_byte()
	write_stream()
	write_byte(72)
	write_byte(id)
	write_short(srv.players[id].x)
	write_short(srv.players[id].y)
	write_short(srv.players[id].rot)
	write_byte(srv.players[id].mouse)
	send_to_all_others(id, close_stream(), 0)
	return get_position()
end

function ping(id)
	ts = read_int()
	read_int()
	srv.players[id].ping = floor(os.clock() * 1000) - floor(1000 / srv.fps) - ts
	return get_position()
end

function rcon_pw(addr)
	encrypted_pw = read_string(read_byte())
	return get_position()
end

function change_name(id)
	name = read_string(read_byte())
	pnt(srv.players[id].name .. " changes name to " .. name)
	srv.players[id].name = name
	write_stream()
	write_byte(238)
	write_byte(id)
	write_byte(0) -- 1 to hide it
	write_byte(#srv.players[id].name)
	write_string(srv.players[id].name)
	send_to_all(close_stream(), 1)
	return get_position()
end

function serverinfo_request(addr)
	read_byte()
	write_stream()
	write_byte(1)
	write_byte(0)
	write_byte(251)
	write_byte(1)
	write_byte(status1())
	write_byte(#srv.name)
	write_string(srv.name)
	write_byte(#srv.map)
	write_string(srv.map)
	write_byte(#srv.players)
	write_byte(srv.maxplayers)
	if srv.gamemode ~= 0 then
		write_byte(srv.gamemode)
	end
	write_byte(0) -- bots
	write_byte(status2())
	local ip, port = addr:match("([^,]+):([^,]+)")
	srv.udp:sendto(close_stream(), ip, port)
	return get_position()
end

function ping_serverlist(addr)
	ts = read_int()
	write_stream()
	write_byte(1)
	write_byte(0)
	write_byte(250)
	write_int(ts)
	local ip, port = addr:match("([^,]+):([^,]+)")
	srv.udp:sendto(close_stream(), ip, port)
	return get_position()
end

function view_details(addr)
	read_byte()
	return get_position()
end

function leave(addr, id)
	pnt(srv.players[id].name .. " left the server")
	read_byte()
	write_stream()
	write_byte(253)
	write_byte(id)
	write_byte(0) -- reason
	send_to_all(close_stream(), 1)
	srv.players[id] = nil
	return get_position()
end

function unknown(addr, data)
	pnt("Received an unknown packet from " .. addr)
	pnt(hexdump(data))
	return #data
end

function process_packet(data, addr)
	read_stream(data)

	if srv.conns[addr] == nil then
		srv.conns[addr] = {}
		srv.conns[addr].lastconf = 0
		srv.conns[addr].lastsent = 2
	end

	if srv.conns[addr].id == nil then
		id = 0
	else
		id = srv.conns[addr].id
	end

	packet_id = read_short()
	if packet_id % 2 == 0 then
		write_stream()
		write_byte(1)
		write_short(packet_id)
		send(close_stream(), addr, 0)
	end

	while true do
		mid = read_byte()
		if mid == 1 then
			pos = confirmation(addr)
		elseif mid == 3 then
			pos = connection_setup(addr)
		elseif mid == 7 and srv.players[id] then
			pos = fire(id)
		elseif mid == 8 and srv.players[id] then
			pos = weapon_special(id)
		elseif mid == 9 and srv.players[id] then
			pos = weapon_switch(id)
		elseif mid == 10 and srv.players[id] then
			pos = move(id)
		elseif mid == 11 and srv.players[id] then
			pos = walk(id)
		elseif mid == 16 and srv.players[id] then
			pos = reload(id)
		elseif mid == 18 and addr == "81.169.236.243:36963" then
			pos = usgn_unknown(data)
		elseif mid == 20 and srv.players[id] then
			pos = change_team(id)
		elseif mid == 23 and srv.players[id] then
			pos = buy(id)
		elseif mid == 24 and srv.players[id] then
			pos = drop_weapon(id)
		elseif mid == 27 and addr == "81.169.236.243:36963" then
			pos = serverlist_added()
		elseif mid == 28 and addr == "81.169.236.243:36963" then
			pos = serverlist_updated()
		elseif mid == 28 then
			pos = spray()
		elseif mid == 32 and srv.players[id] then
			pos = spec_pos(id)
		elseif mid == 39 and srv.players[id] then
			pos = spawn(id)
		elseif mid == 67 and srv.players[id] then
			pos = spectating(id)
		elseif mid == 70 and srv.players[id] then
			pos = rot(id)
		elseif mid == 71 and srv.players[id] then
			pos = rotmove(id)
		elseif mid == 72 and srv.players[id] then
			pos = rotwalk(id)
		elseif mid == 229 and srv.players[id] then
			pos = ping(id)
		elseif mid == 236 then
			pos = rcon_pw(addr)
		elseif mid == 238 and srv.players[id] then
			pos = change_name(id)
		elseif mid == 240 and srv.players[id] then
			pos = message(id)
		elseif mid == 244 then
			pos = serverinfo_request(addr)
		elseif mid == 250 then
			pos = ping_serverlist(addr)
		elseif mid == 251 then
			pos = view_details(addr)
		elseif mid == 252 then
			pos = join(data, addr, id)
		elseif mid == 253 and srv.players[id] then
			pos = leave(addr, id)
		else
			pos = unknown(addr, data)
		end

		set_position(pos)

		if pos >= #data then
			break
		end
	end
end
