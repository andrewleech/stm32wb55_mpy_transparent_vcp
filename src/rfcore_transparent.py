import asyncio


async def _relay(reader, writer):
    while True:
        data = await reader.read(256)
        if not data:
            break
        writer.write(data)
        await writer.drain()


async def _relay_host_to_hci(sr_host, sw_hci, sw_host):
    LOCAL_CMD = const(0x20)
    BT_CMD = const(0x01)
    BT_ACL = const(0x02)
    while True:
        type_byte = await sr_host.readexactly(1)
        ptype = type_byte[0]
        if ptype == BT_CMD or ptype == LOCAL_CMD:
            hdr = await sr_host.readexactly(3)
            plen = hdr[2]
            payload = await sr_host.readexactly(plen) if plen else b''
            pkt = type_byte + hdr + payload
            if ptype == LOCAL_CMD:
                rsp = _local_hci_cmd(pkt)
                sw_host.write(rsp)
                await sw_host.drain()
            else:
                sw_hci.write(pkt)
                await sw_hci.drain()
        elif ptype == BT_ACL:
            hdr = await sr_host.readexactly(4)
            plen = hdr[2] | (hdr[3] << 8)
            payload = await sr_host.readexactly(plen) if plen else b''
            sw_hci.write(type_byte + hdr + payload)
            await sw_hci.drain()
        else:
            raise ValueError("unknown HCI packet type: 0x%02x" % ptype)


async def start_async(host_stream):
    import bluetooth

    hci = bluetooth.hci_io()
    sr_host = asyncio.StreamReader(host_stream)
    sw_host = asyncio.StreamWriter(host_stream, {})
    sr_hci = asyncio.StreamReader(hci)
    sw_hci = asyncio.StreamWriter(hci, {})
    t1 = asyncio.create_task(_relay_host_to_hci(sr_host, sw_hci, sw_host))
    t2 = asyncio.create_task(_relay(sr_hci, sw_host))
    try:
        await asyncio.gather(t1, t2)
    finally:
        t1.cancel()
        t2.cancel()
        try:
            await t1
        except (asyncio.CancelledError, Exception):
            pass
        try:
            await t2
        except (asyncio.CancelledError, Exception):
            pass
        hci.close()
