#include "py/dynruntime.h"
#include "py/binary.h"
#include "py/objarray.h"

#include "stm32wb55_local_commands.h"

// Don't enable this if stdio is used for transp comms.
#define DEBUG_printf(...)  // mp_printf(&mp_plat_print, "rfcore_transp: " __VA_ARGS__)

#define STATE_IDLE 0
#define STATE_NEED_LEN 1
#define STATE_IN_PAYLOAD 2

#define HCI_KIND_BT_CMD (0x01) // <kind=1><?><?><len>
#define HCI_KIND_BT_ACL (0x02) // <kind=2><?><?><len LSB><len MSB>
#define HCI_KIND_BT_EVENT (0x04) // <kind=4><op><len><data...>
#define HCI_KIND_VENDOR_RESPONSE (0x11)
#define HCI_KIND_VENDOR_EVENT (0x12)
#define HCI_KIND_LOCAL_CMD (0x20) // Used by STM32CubeMonitor to query the device
#define HCI_KIND_LOCAL_RSP (0x21)

// Define STATIC macro if not defined
#ifndef STATIC
#define STATIC static
#endif

// Callback python function, can be used to provide feedback on each comm, eg. blink LED.
void mpy_run_callback(mp_obj_t callback, bool on) {
    if (callback != mp_const_none) {
        mp_obj_t args[] = {(on) ? mp_const_true : mp_const_false};
        mp_call_function_n_kw(callback, 1, 0, args);
    }
}

// Helper function to create a bytes object from buffer
STATIC mp_obj_t bytes_from_buffer(const uint8_t *buf, size_t len) {
    mp_obj_t bytes_obj = mp_obj_new_bytes(buf, len);
    return bytes_obj;
}

// The main function - entry point for the native module
STATIC mp_obj_t rfcore_transparent(mp_obj_t stream_in, mp_obj_t stream_out, mp_obj_t callback) {
    // Make sure we have suitable stream objects.
    mp_get_stream_raise(stream_in, MP_STREAM_OP_READ | MP_STREAM_OP_IOCTL);
    mp_get_stream_raise(stream_out, MP_STREAM_OP_WRITE);

    mp_obj_t stm_module = mp_import_name(MP_QSTR_stm, mp_const_none, MP_OBJ_NEW_SMALL_INT(0));
    mp_obj_t rfcore_ble_hci_obj = mp_import_from(stm_module, MP_QSTR_rfcore_ble_hci);

    mp_obj_t time_module = mp_import_name(MP_QSTR_time, mp_const_none, MP_OBJ_NEW_SMALL_INT(0));
    mp_obj_t sleep_ms_obj = mp_import_from(time_module, MP_QSTR_sleep_ms);

    uint8_t buf[1024];
    size_t rx = 0;
    size_t len = 0;
    int state = 0;
    int cmd_type = 0;

    // We'll use these functions from MicroPython for streaming
    mp_obj_t write_method = mp_load_attr(stream_out, MP_QSTR_write);
    mp_obj_t read_method = mp_load_attr(stream_in, MP_QSTR_read);

    while (true) {
        // Sleep briefly to allow micropython background processing.
        mp_obj_t sleep_args[] = {MP_OBJ_NEW_SMALL_INT(1)};
        mp_call_function_n_kw(sleep_ms_obj, 1, 0, sleep_args);

        if (state == STATE_IN_PAYLOAD && len == 0) {
            size_t rsp_len = 0;

            if (cmd_type == HCI_KIND_LOCAL_CMD) {
                // Process the command directly (cpu1).
                DEBUG_printf("local_hci_cmd\n");
                rsp_len = local_hci_cmd(rx, buf);
                DEBUG_printf("rsp: len 0x%x\n", rsp_len);

            } else {
                // Forward command to rfcore (cpu2).
                DEBUG_printf("rfcore_ble_hci_cmd\n");
                mp_obj_array_t cmd = {{&mp_type_bytearray}, BYTEARRAY_TYPECODE, 0, rx, buf};
                mp_obj_array_t rsp = {{&mp_type_bytearray}, BYTEARRAY_TYPECODE, 0, sizeof(buf), buf};

                mp_obj_t args[] = {MP_OBJ_FROM_PTR(&cmd), MP_OBJ_FROM_PTR(&rsp)};
                mp_obj_t rsp_len_o = mp_call_function_n_kw(rfcore_ble_hci_obj, 2, 0, args);
                rsp_len = mp_obj_get_int(rsp_len_o);
            }

            if (rsp_len > 0) {
                DEBUG_printf("rsp: len 0x%x\n", rsp_len);
                // Create a bytes object and write to stream
                mp_obj_t bytes_obj = bytes_from_buffer(buf, rsp_len);
                // Use mp_call_function_n_kw instead of mp_call_function_1
                mp_obj_t write_args[] = {bytes_obj};
                mp_call_function_n_kw(write_method, 1, 0, write_args);
                mpy_run_callback(callback, false);
            } else {
                DEBUG_printf("rsp: None\n");
            }

            rx = 0;
            len = 0;
            state = STATE_IDLE;

        } else {
            // Try reading one byte
            mp_obj_t read_args[] = {MP_OBJ_NEW_SMALL_INT(1)};
            mp_obj_t data = mp_call_function_n_kw(read_method, 1, 0, read_args);
            
            // Check if we got any data
            // Instead of using mp_obj_is_str_or_bytes, directly check the type
            const mp_obj_type_t *type = mp_obj_get_type(data);
            if ((type == &mp_type_str || type == &mp_type_bytes) && mp_obj_len(data) > 0) {
                // Get the byte
                size_t data_len;
                const byte *data_ptr = (const byte*)mp_obj_str_get_data(data, &data_len);
                if (data_len > 0) {
                    uint8_t c = data_ptr[0];
                    mpy_run_callback(callback, true);
                    
                    if (state == STATE_IDLE) {
                        if (c == HCI_KIND_BT_CMD || c == HCI_KIND_BT_ACL || c == HCI_KIND_BT_EVENT || 
                            c == HCI_KIND_VENDOR_RESPONSE || c == HCI_KIND_VENDOR_EVENT || c == HCI_KIND_LOCAL_CMD) {
                            cmd_type = c;
                            state = STATE_NEED_LEN;
                            buf[rx++] = c;
                            len = 0;
                            DEBUG_printf("cmd_type 0x%x\n", c);
                        } else {
                            DEBUG_printf("cmd_type unknown 0x%x\n", c);
                        }
                    } else if (state == STATE_NEED_LEN) {
                        buf[rx++] = c;
                        if (cmd_type == HCI_KIND_BT_ACL && rx == 4) {
                            len = c;
                        }
                        if (cmd_type == HCI_KIND_BT_ACL && rx == 5) {
                            len += ((size_t)c) << 8;
                            DEBUG_printf("len 0x%x\n", c);
                            state = STATE_IN_PAYLOAD;
                        }
                        if (cmd_type == HCI_KIND_BT_EVENT && rx == 3) {
                            len = c;
                            DEBUG_printf("len 0x%x\n", c);
                            state = STATE_IN_PAYLOAD;
                        }
                        if (cmd_type == HCI_KIND_BT_CMD && rx == 4) {
                            len = c;
                            DEBUG_printf("len 0x%x\n", c);
                            state = STATE_IN_PAYLOAD;
                        }
                        if (cmd_type == HCI_KIND_LOCAL_CMD && rx == 4) {
                            len = c;
                            DEBUG_printf("len 0x%x\n", c);
                            state = STATE_IN_PAYLOAD;
                        }
                    } else if (state == STATE_IN_PAYLOAD) {
                        buf[rx++] = c;
                        --len;
                    }
                }
            }
        }
    }

    return mp_const_none;
}

MP_DEFINE_CONST_FUN_OBJ_3(rfcore_transparent_obj, rfcore_transparent);

mp_obj_t mpy_init(mp_obj_fun_bc_t *self, size_t n_args, size_t n_kw, mp_obj_t *args) {
    // This must be first, it sets up the globals dict and other things
    MP_DYNRUNTIME_INIT_ENTRY

    // Make the function available in the module's namespace
    mp_store_global(MP_QSTR__rfcore_transparent_start, MP_OBJ_FROM_PTR(&rfcore_transparent_obj));

    // This must be last, it restores the globals dict
    MP_DYNRUNTIME_INIT_EXIT
}