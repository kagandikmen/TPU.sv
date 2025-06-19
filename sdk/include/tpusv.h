// TPU.sv C library header
// Created:     2025-06-18
// Modified:    2025-06-19

// Copyright (c) 2025 Kagan Dikmen
// See LICENSE for details

#ifndef __TPUSV_H_
#define __TPUSV_H_


#include <errno.h>
#include <stdint.h>
#include <stdlib.h>


/////
/////   macros
/////

#define TPUSV_BASE 				    (0x43C00000)

#define TPUSV_WEIGHT_BUFFER_BASE    (TPUSV_BASE)
#define TPUSV_WEIGHT_BUFFER_SIZE    0x8000  // 32,768

#define TPUSV_UNIFIED_BUFFER_BASE   (TPUSV_BASE + 0x80000)
#define TPUSV_UNIFIED_BUFFER_SIZE   0x1000  // 4,096

#define TPUSV_INSTR_BASE            (TPUSV_BASE + 0x90000)

#define TPUSV_SYSTOLICARRAY_WIDTH           14
#define TPUSV_SYSTOLICARRAY_WIDTH_PADDED    16      // ceil(log2(TPUSV_SYSTOLICARRAY_WIDTH))

/////   do not modify below this line (unless you know what you are doing)

#define TPUSV_CLOCK_PERIOD_NS       7

#define TPUSV_OPCODE_NOP            0x00
#define TPUSV_OPCODE_HALT           0x02
#define TPUSV_OPCODE_RWEIGHTS       0x08
#define TPUSV_OPCODE_MMUL           0x20
#define TPUSV_OPCODE_ACTIVATE       0x80
#define TPUSV_OPCODE_SYNCHRONIZE    0xFF

#define GET_WEIGHT_ADDR(weight_addr)     ((uint64_t)(weight_addr.wide & 0x000000FFFFFFFFFF))
#define GET_BUFFER_ADDR(buffer_addr)     ((uint32_t)(buffer_addr.wide & 0x00FFFFFF))


#ifdef __cplusplus
extern "C" {
#endif


/////
/////   type definitions
/////

typedef union {
    uint8_t bytes[3];
    uint32_t wide;
} buffer_addr_t;

typedef union {
    uint8_t bytes[5];
    uint64_t wide;
} weight_addr_t;

typedef union {
    uint8_t bytes[2];
    uint16_t wide;
} acc_addr_t;

typedef union {
    uint8_t bytes[4];
    uint32_t wide;
} calc_length_t;

typedef uint8_t opcode_t;

typedef union tpusv_vector {
    uint8_t     vector_in_bytes[TPUSV_SYSTOLICARRAY_WIDTH];
    uint32_t    vector_in_words[TPUSV_SYSTOLICARRAY_WIDTH_PADDED/4];
} tpusv_vector_t;

typedef union tpusv_instr {
   struct {
        union {
            struct {
                buffer_addr_t buf_addr;
                acc_addr_t acc_addr;
            };
            weight_addr_t weight_addr;
        };
        calc_length_t calc_length;
        opcode_t opcode;
    };

    struct {
        uint16_t upper_instr_word;
        uint32_t middle_instr_word;
        uint32_t lower_instr_word;
    };
} tpusv_instr_t;


/////
/////   function declarations
/////

int32_t read_vector_from_buffer(tpusv_vector_t *output_vector, const buffer_addr_t buffer_addr);

int32_t write_input_vector(const tpusv_vector_t *input_vector, const buffer_addr_t buffer_addr);

int32_t write_instr(const tpusv_instr_t *instr);

int32_t write_weight_vector(const tpusv_vector_t *weight_vector, const weight_addr_t weight_addr);


#ifdef __cplusplus
}
#endif


#endif // __TPUSV_H_
