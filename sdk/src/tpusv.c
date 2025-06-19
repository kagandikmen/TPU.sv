// TPU.sv C library implementation
// Created:		2025-06-18
// Modified:	2025-06-19

// Copyright (c) 2025 Kagan Dikmen
// See LICENSE for details

#include "tpusv.h"

int32_t read_vector_from_buffer(tpusv_vector_t *output_vector, const buffer_addr_t buffer_addr) {

	uint32_t buffer_addr_masked = GET_BUFFER_ADDR(buffer_addr);
	
	if(buffer_addr_masked >= TPUSV_UNIFIED_BUFFER_SIZE) return EFAULT;

	buffer_addr_masked <<= (uint32_t) TPUSV_SYSTOLICARRAY_WIDTH_PADDED;

	for(size_t i=0, j=0; j < TPUSV_SYSTOLICARRAY_WIDTH; i++, j+=sizeof(uint32_t)) {
		output_vector->vector_in_words[i] = *(volatile uint32_t*)(TPUSV_UNIFIED_BUFFER_BASE+buffer_addr_masked+j);
	}

	return 0;
}

int32_t write_input_vector(const tpusv_vector_t *input_vector, const buffer_addr_t buffer_addr) {

	uint32_t buffer_addr_masked = GET_BUFFER_ADDR(buffer_addr);

	if(buffer_addr_masked >= TPUSV_UNIFIED_BUFFER_SIZE) return EFAULT;

	buffer_addr_masked <<= (uint32_t) TPUSV_SYSTOLICARRAY_WIDTH_PADDED;

	for(size_t i=0, j=0; j < TPUSV_SYSTOLICARRAY_WIDTH; i++, j+=sizeof(uint32_t)) {
		*(volatile uint32_t *)(TPUSV_UNIFIED_BUFFER_BASE+buffer_addr_masked+j) = input_vector->vector_in_words[i];
	}

	return 0;
}

int32_t write_instr(const tpusv_instr_t *instr) {
	*(volatile uint32_t *)(TPUSV_INSTR_BASE+ 4) = instr->lower_instr_word;
	*(volatile uint32_t *)(TPUSV_INSTR_BASE+ 8) = instr->middle_instr_word;
	*(volatile uint16_t *)(TPUSV_INSTR_BASE+12)	= instr->upper_instr_word;

	return 0;
}

int32_t write_weight_vector(const tpusv_vector_t *weight_vector, const weight_addr_t weight_addr) {

	uint32_t weight_addr_masked = GET_WEIGHT_ADDR(weight_addr);

	if(weight_addr_masked >= TPUSV_WEIGHT_BUFFER_SIZE) return EFAULT;

	weight_addr_masked <<= (uint32_t) TPUSV_SYSTOLICARRAY_WIDTH_PADDED;

	for(size_t i=0, j=0; j < TPUSV_SYSTOLICARRAY_WIDTH; i++, j+=sizeof(uint32_t)) {
		*(volatile uint32_t *)(TPUSV_WEIGHT_BUFFER_BASE+weight_addr_masked+j) = weight_vector->vector_in_words[i];
	}

	return 0;
}
