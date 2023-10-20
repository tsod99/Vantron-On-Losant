local netm = require "luci.model.network".init()
local net = netm:get_network("4g")
local device = net and net:get_interface()

if device then
    
    local uptime     = net:uptime()
    local rx_bytes   = device:rx_bytes()
    local tx_bytes   = device:tx_bytes()
    local rx_packets = device:rx_packets()
    local tx_packets = device:tx_packets()

    local data = "uptime:" .. uptime .. ",rx_bytes:" .. rx_bytes .. ",tx_bytes:" .. tx_bytes .. ",rx_packets:" .. rx_packets .. ",tx_packets:" .. tx_packets
    
    print(data)
end


