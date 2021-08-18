local ffi = require("ffi")
local position = 0
local readbuff = nil
local writebuff = nil

function read_stream(str)
	position = 0
	readbuff = ffi.new("uint8_t[?]", #str)
	ffi.copy(readbuff, str, #str)
end

function write_stream()
	writebuff = ""
end

function close_stream()
	return writebuff
end

function get_position()
	return position
end

function set_position(p)
	position = p
end

function read_byte()
	local n = readbuff[position]
	position = position + 1
	return n
end

function read_short()
	local n = {}
	n[0] = read_byte()
	n[1] = read_byte()
	return n[0] + n[1] * 256
end

function read_int()
	local n = {}
	n[0] = read_byte()
	n[1] = read_byte()
	n[2] = read_byte()
	n[3] = read_byte()
	return n[0] + n[1] * 256 + n[2] * 65536 + n[3] * 16777216
end

function read_long()
	local n = {}
	n[0] = read_byte()
	n[1] = read_byte()
	n[2] = read_byte()
	n[3] = read_byte()
	n[4] = read_byte()
	n[5] = read_byte()
	n[6] = read_byte()
	n[7] = read_byte()
	local value = ffi.new("unsigned long")
	local longb = ffi.new("unsigned long", 256)
	for i = 0, 7 do
		value = value + ffi.new("unsigned long", n[i]) * longb ^ i
	end
	return value
end

function read_line()
	local chr = nil
	local str = ""
	while true do
		chr = read_byte()
		if chr == 10 or chr == 0 then
			break
		end
		if chr ~= 13 then
			str = str .. string.char(chr)
		end
	end
	return str
end

function read_string(len)
	local x = ffi.string(readbuff + position, len)
	position = position + len
	return x
end

function write_byte(n)
	local q = ffi.new("uint8_t[1]")
	q[0] = bit.band(n, 0xff)
	writebuff = writebuff .. ffi.string(q, 1)
end

function write_short(n)
	local q = ffi.new("uint8_t[2]")
	q[0] = bit.band(n, 0xff)
	n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff)
	writebuff = writebuff .. ffi.string(q, 2)
end

function write_int(n)
	local q = ffi.new("uint8_t[4]")
	q[0] = bit.band(n, 0xff)
	n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff)
	n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff)
	n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff)
	writebuff = writebuff .. ffi.string(q, 4)
end

function write_long(n)
	local q = ffi.new("uint8_t[8]")
	q[0] = bit.band(n, 0xff)
	n = bit.rshift(n - q[0], 8)
	q[1] = bit.band(n, 0xff)
	n = bit.rshift(n - q[1], 8)
	q[2] = bit.band(n, 0xff)
	n = bit.rshift(n - q[2], 8)
	q[3] = bit.band(n, 0xff)
	n = bit.rshift(n - q[3], 8)
	q[4] = bit.band(n, 0xff)
	n = bit.rshift(n - q[4], 8)
	q[5] = bit.band(n, 0xff)
	n = bit.rshift(n - q[5], 8)
	q[6] = bit.band(n, 0xff)
	n = bit.rshift(n - q[6], 8)
	q[7] = bit.band(n, 0xff)
	writebuff = writebuff .. ffi.string(q, 8)
end

function write_string(s)
	for i = 1, #s do
		write_byte(string.byte(s, i))
	end
end

function write_encoded_string(s)
	for i = 0, #s - 1 do
		if i % 3 == 0 then
			write_byte(string.byte(s, i + 1) + 110)
		elseif i % 3 == 1 then
			write_byte(string.byte(s, i + 1) + 97)
		elseif i % 3 == 2 then
			write_byte(string.byte(s, i + 1) + 109)
		end
	end
	write_byte(0)
end
