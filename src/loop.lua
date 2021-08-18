local data, ip, port
local mstime = os.clock()
local timecounter = os.clock()
local tickcounter = 0
local fps = 1000 / srv.fps
local fpsnow = 0
local every3s = os.clock() + 3
local every60s = os.clock() + 60

pnt("#######################################################")
pnt("Custom CS2D Dedicated Server written in Lua")
pnt("Repository: https://github.com/Hajt5/cs2dsrv")
pnt("Operating System: " .. jit.os)
pnt("Architecture: " .. jit.arch)
pnt("Server for 1.0.1.2")
pnt(jit.version)
pnt("#######################################################")

math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
srv.udp:settimeout(0)
if srv.udp:setsockname("*", srv.port) ~= nil then
	pnt("UDP socket initialized using port " .. srv.port)
end

serverlist_add()
while true do
	if timecounter - os.clock() <= 0 then
		fpsnow = tickcounter
		tickcounter = 0
		timecounter = os.clock() + 1
	end
	tickcounter = tickcounter + 1

	for i, v in ipairs(srv.players) do
		if v.reload > 0 and v.reload <= os.clock() then
			write_stream()
			write_byte(16)
			write_byte(i)
			write_byte(2)
			send_to_all(close_stream(), 1)
			srv.players[i].reload = 0
		end
	end

	if every3s <= os.clock() then
		for i, v in ipairs(srv.players) do
			write_stream()
			write_byte(229)
			write_int(math.floor(os.clock() * 1000))
			write_byte(247)
			write_byte(#srv.players)
			write_byte(fpsnow)
			write_short(0) -- network traffic up
			write_short(0) -- network traffic down
			for k, l in ipairs(srv.players) do
				write_byte(k)
				write_short(l.ping)
			end
			send(close_stream(), v.ip .. ":" .. v.port, 0)
		end
		every3s = os.clock() + 3
	end

	if every60s <= os.clock() then
		append_logs()
		serverlist_update()
		every60s = os.clock() + 60
	end

	while true do
		data, ip, port = srv.udp:receivefrom()
		if data then
			process_packet(data, ip .. ":" .. port)
		else
			break
		end
	end

	srv.time.sleep((fps + mstime - os.clock()) / 1000)
	mstime = os.clock()
end
