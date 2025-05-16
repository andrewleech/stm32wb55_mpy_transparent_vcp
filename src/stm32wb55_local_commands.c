// STM32WB55 BLE_TransparentModeVCP Local Commands
// Based on functionality from:
// https://github.com/STMicroelectronics/STM32CubeWB/tree/83aacadecbd5136ad3194f39e002ff50a5439ad9/Projects/P-NUCLEO-WB55.USBDongle/Applications/BLE/BLE_TransparentModeVCP
//
// > Copyright (c) 2019-2021 STMicroelectronics.
// > All rights reserved.
// >
// > This software is licensed under terms that can be found in the LICENSE file
// > in the root directory of this software component.
// > If no LICENSE file comes with this software, it is provided AS-IS.
//
// Note: The LICENCE file referred to is copied here as LICENCE_ST.md

#include <string.h>
// Commented out hardware-specific includes for now
// #include "stm32wbxx_ll_utils.h"
// #include "stm32wbxx_ll_system.h"

#include "stm32wb55_local_commands.h"

// Stub implementation for development/testing purposes
// Actual implementation would need STM32WB hardware headers
size_t local_hci_cmd(size_t len, const uint8_t *buffer) {
    // Just return 0 length for now
    // When used on actual hardware, this would be replaced with the real implementation
    return 0;
}