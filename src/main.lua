function getPath(str)
	local ret = str:match("(.*/)")
	if ret == nil then
		return ""
	end
	return ret
end

srv = {}
map = {}
wpn = {}
path = getPath(arg[0])
srv.udp = require("socket").udp()
srv.time = require(path .. "3rdparty/time")
srv.inspect = require(path .. "3rdparty/inspect")
srv.sha2 = require(path .. "3rdparty/sha2")
srv.logs = {}
srv.conns = {}
srv.players = {}
srv.time.install()

dofile(path .. "settings.lua")
dofile(path .. "weapons.lua")
dofile(path .. "stream.lua")
dofile(path .. "map.lua")
dofile(path .. "misc.lua")
dofile(path .. "send.lua")
dofile(path .. "packets.lua")
dofile(path .. "loop.lua")
