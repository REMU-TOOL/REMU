/***************************************************************************************
 * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan
 *PSL v2. You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY
 *KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 *NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#ifndef __COMMON_H__
#define __COMMON_H__

#include "macro.hpp"
#include <cinttypes>
#include <cstdbool>
#include <cstdint>

using word_t = uint32_t;
using sword_t = int32_t;
#define FMT_WORD MUXDEF(CONFIG_ISA64, "0x%016" PRIx64, "0x%08" PRIx32)
#define FMT_WORD_X MUXDEF(CONFIG_ISA64, "0x%016" PRIx64, "0x%08" PRIx32)
#define FMT_WORD_U MUXDEF(CONFIG_ISA64, "%20" PRIu64, "%12" PRIu32)
#define FMT_WORD_D MUXDEF(CONFIG_ISA64, "%20" PRId64, "%12" PRId32)

#define HEX_WORD "{:#010x}"

using vaddr_t = word_t;
using paddr_t = uint32_t;
#define FMT_PADDR MUXDEF(PMEM64, "0x%016" PRIx64, "0x%08" PRIx32)
enum {
  TEST_NAME_NON,
  TEST_NAME_FUNC,
  TEST_NAME_PERF,
  TEST_NAME_SYST,
  TEST_NAME_UBOOT,
  TEST_NAME_UCORE,
  TEST_NAME_LINUX
};

#endif