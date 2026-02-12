#include "py/dynruntime.h"

#include "stm32wb55_local_commands.h"

#ifndef STATIC
#define STATIC static
#endif

// Process a STM32CubeMonitor-RF local command (type 0x20).
// Takes a bytes/bytearray with the raw command payload (without the 0x20 type byte).
// Returns a bytes object with the response.
STATIC mp_obj_t local_hci_cmd_wrapper(mp_obj_t cmd_in) {
    mp_buffer_info_t bufinfo;
    mp_get_buffer_raise(cmd_in, &bufinfo, MP_BUFFER_READ);

    // local_hci_cmd works in-place on the buffer, so copy to a stack buffer.
    uint8_t buf[272];
    size_t len = bufinfo.len;
    if (len > sizeof(buf)) {
        len = sizeof(buf);
    }
    mp_fun_table.memmove_(buf, bufinfo.buf, len);

    size_t rsp_len = local_hci_cmd(len, buf);
    return mp_obj_new_bytes(buf, rsp_len);
}
MP_DEFINE_CONST_FUN_OBJ_1(local_hci_cmd_wrapper_obj, local_hci_cmd_wrapper);

mp_obj_t mpy_init(mp_obj_fun_bc_t *self, size_t n_args, size_t n_kw, mp_obj_t *args) {
    MP_DYNRUNTIME_INIT_ENTRY

    mp_store_global(MP_QSTR__local_hci_cmd, MP_OBJ_FROM_PTR(&local_hci_cmd_wrapper_obj));

    MP_DYNRUNTIME_INIT_EXIT
}
