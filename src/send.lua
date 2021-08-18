function send(buf, addr, reliable)
	write_stream()
	if reliable == 1 then
		write_short(srv.conns[addr].lastsent)
		srv.conns[addr].lastsent = srv.conns[addr].lastsent + 2
	else
		srv.conns[addr].lastsent = srv.conns[addr].lastsent - 1
		write_short(srv.conns[addr].lastsent)
		srv.conns[addr].lastsent = srv.conns[addr].lastsent + 1
	end
	local ip, port = addr:match("([^,]+):([^,]+)")
	srv.udp:sendto(close_stream() .. buf, ip, port)
end

function send_to_all(buf, reliable)
	for i, v in ipairs(srv.players) do
		send(buf, v.ip .. ":" .. v.port, reliable)
	end
end

function send_to_all_others(id, buf, reliable)
	for i, v in ipairs(srv.players) do
		if i ~= id then
			send(buf, v.ip .. ":" .. v.port, reliable)
		end
	end
end

function send_to_team(id, buf, reliable)
	for i, v in ipairs(srv.players) do
		if v.team == srv.players[id].team then
			send(buf, v.ip .. ":" .. v.port, reliable)
		end
	end
end
