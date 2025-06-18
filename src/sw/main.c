// Demo application for TPU.sv SDK
// Created:     2025-06-18
// Modified:    2025-06-19

// Original Template (c) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
    // SPDX-License-Identifier: MIT

// Modifications (c) 2025 Kagan Dikmen
// See LICENSE for details

/*
 * main.c: simple demo application for TPU.sv SDK
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */


#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "xil_printf.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xparameters.h"
#include "xparameters_ps.h"

#include "tpusv.h"

#define WEIGHTS     "weights={"
#define INPUTS      "inputs={"
#define INSTRS      "instrs={"
#define END         "}"

#define DELIMITERS  "{},"

static XScuGic INTCInst;

static volatile uint8_t is_synchronized;

void isr(void *vp);
int32_t load_inputs(char*);
int32_t load_instrs(char*);
int32_t load_weights(char*);
int setup_interrupt(void);

int main()
{
    int32_t status = 0;
    is_synchronized = 0;

    // setup interrupts
    status = setup_interrupt();
    if(XST_SUCCESS != status) {
        printf("setup_interrupt failed (error code: %d)\n\r", status);
    }

    char user_input[1024];

    while(1) {
    // until interrupted (by synchronize signal) keep doing:
        
        // receive user_input from stdin
        printf("Enter data:\n\r");
        scanf("%s", user_input);

        // print out user_input to stdout
        printf("Entered: %s\n\r", user_input);

        //read weights from stdout & write them into weight buffer
        status = load_weights(user_input);
        if(0 != status) {
            fprintf(stderr, "load_weights failed (error code: %d)\n\r", status);
        }

        // read inputs from stdin & write them into unified buffer
        status = load_inputs(user_input);
        if(0 != status) {
            fprintf(stderr, "load_inputs failed (error code: %d)\n\r", status);
        }

        // read instructions & write them into instruction buffer
        status = load_instrs(user_input);
        if(0 != status) {
            fprintf(stderr, "load_instrs failed (error code: %d)\n\r", status);
        }
    }

    return 0;
}

// interrupt service routine (sets the value pointed by instance pointer to one)
void isr(void *vp) {
    *(int*) vp = 1;
}

int32_t load_inputs(char *stdinput) {
    
    buffer_addr_t input_addr;
    input_addr.wide = 0;
    
    if(strncmp(INPUTS, stdinput, sizeof(INPUTS)) == 0) {

        while(1) {
        // if stdinput starts with "inputs = {" (or whatever INPUTS is) then keep doing:

            scanf("%s", stdinput);

            // leave loop if END character is entered
            if(0 == strncmp(END, stdinput, sizeof(END))) {
                break;
            }

            tpusv_vector_t vector;

            // save the entered values into vector.vector_in_bytes
            uint32_t i = 0;
            char *str = strtok(stdinput, DELIMITERS);
            while(NULL != str) {
                if(i >= TPUSV_SYSTOLICARRAY_WIDTH) {
                    fprintf(stderr, "vector out of bounds: (vector size: %d, systolic array width: %d)\n\r", i, TPUSV_SYSTOLICARRAY_WIDTH);
                    return EFAULT;
                }
                vector.vector_in_bytes[i++] = atoi(str);
                str = strtok(NULL, DELIMITERS);
            }

            // user maybe did not enter enough values
            if(i < TPUSV_SYSTOLICARRAY_WIDTH-1) {
                fprintf(stderr, "vector too small: (vector size: %d, systolic array width: %d)\n\r", i, TPUSV_SYSTOLICARRAY_WIDTH);
                return EINVAL;
            }

            if(write_input_vector(&vector, input_addr)) {
            // if write_input_vector fails then do:
                fprintf(stderr, "write_input_vector failed\n\r");
                return EIO;
            }

            printf("load_inputs wrote 0x%04x%08x%08x%08x to unified buffer address 0x%012" PRIx32 "\n\r", vector.vector_in_words[3],
                                                                                                          vector.vector_in_words[2],
                                                                                                          vector.vector_in_words[1],
                                                                                                          vector.vector_in_words[0], 
                                                                                                          GET_BUFFER_ADDR(input_addr)
            );
            input_addr.wide++;
        }
    }

    return 0;
}

int32_t load_instrs(char *stdinput) {

    if(strncmp(INSTRS, stdinput, sizeof(INSTRS)) == 0) {
    // if stdinput starts with "instrs = {" (or whatever INSTRS is) then do:

        tpusv_instr_t instrs[512];

        char done = 0;
        do {
            size_t i = 0;
            for(; i<sizeof(instrs); ++i) {
            // for each instuction, do:

                scanf("%s", stdinput);

                // if END character is entered then break out of the for loop
                // & execute the outer do-while loop for the last time
                if(strncmp(END, stdinput, sizeof(END)) == 0) {
                    done = 1;
                    break;
                } else if(i == sizeof(instrs)-1) {
                    fprintf(stderr, "instruction buffer full, upcoming instructions will be ignored\n\r");
                    done = 1;
                }

                uint32_t j = 0;

                opcode_t opcode;
                calc_length_t calc_length;
                acc_addr_t acc_addr;
                buffer_addr_t buffer_addr;
                weight_addr_t weight_addr;

                char *str = strtok(stdinput, DELIMITERS);
                while(NULL != str) {
                    
                    // an instruction has at most 4 data fields
                    if(j >= 4) {
                        fprintf(stderr, "instruction out of bounds\n\r");
                    }

                    // save entered data fields into dedicated variables
                    switch(j) {
                        case 0:
                            opcode = strtoul(str, NULL, 0);
                            break;
                        case 1:
                            calc_length.wide = strtoul(str, NULL, 0);
                            break;
                        case 2:
                            acc_addr.wide = strtoul(str, NULL, 0);
                            weight_addr.wide = strtoul(str, NULL, 0);
                            break;
                        case 3:
                            buffer_addr.wide = strtoul(str, NULL, 0);
                            break;
                    }

                    j++;
                    str = strtok(NULL, DELIMITERS);
                }

                // instruction data already read by here

                instrs[i].opcode = opcode;
                instrs[i].calc_length = calc_length;

                if(j == 4) { // standard instruction:
                    instrs[i].acc_addr = acc_addr;
                    instrs[i].buf_addr = buffer_addr;
                } else { // weight instruction:
                    instrs[i].weight_addr = weight_addr;
                }
            }

            for(size_t x=0; x<i; ++x) {
                write_instr(&instrs[x]);

                printf("load_instrs wrote instruction 0x%08x%08x%08x\n\r", instrs[x].upper_instr_word, 
                                                                          instrs[x].middle_instr_word, 
                                                                          instrs[x].lower_instr_word
                );
            }

        } while(!done);

        // wait until interrupt from TPU
        while(!is_synchronized);

        is_synchronized = 0;
        uint32_t cycles;
        cycles = *(volatile uint32_t *) TPUSV_INSTR_BASE;
        printf("computations successfully completed in %d cycles\n\r", cycles);
    }

    return 0;
}

int32_t load_weights(char *stdinput) {

    weight_addr_t weight_addr;
    weight_addr.wide = 0;

    if(strncmp(WEIGHTS, stdinput, sizeof(WEIGHTS)) == 0) {

        while(1) {
        // if stdinput starts with "weights = {" (or whatever WEIGHTS is) then keep doing:

            scanf("%s", stdinput);
        
            // leave loop if END character is entered
            if(strncmp(END, stdinput, sizeof(END)) == 0) {
                break;
            }

            tpusv_vector_t vector;

            // save the entered values into int array vector.vector_in_bytes
            uint32_t i = 0;
            char *str = strtok(stdinput, DELIMITERS);
            while(NULL != str) {
                if(i >= TPUSV_SYSTOLICARRAY_WIDTH) {
                    fprintf(stderr, "vector out of bounds: (vector size: %d, systolic array width: %d)\n\r", i, TPUSV_SYSTOLICARRAY_WIDTH);
                    return EFAULT;
                }
                
                vector.vector_in_bytes[i++] = atoi(str);
                str = strtok(NULL, DELIMITERS);
            }

            // user maybe did not enter enough values
            if(i < TPUSV_SYSTOLICARRAY_WIDTH) {
                fprintf(stderr, "vector too small: (vector size: %d, systolic array width: %d)\n\r", i, TPUSV_SYSTOLICARRAY_WIDTH);
                return EINVAL;
            }

            if(write_weight_vector(&vector, weight_addr)) {
            // if write_weight_vector fails then do:
                fprintf(stderr, "write_weight_vector failed\n\r");
                return EIO;
            }

            printf("load_weights wrote 0x%04x%08x%08x%08x to weight buffer address 0x%010" PRIx64 "\n\r", vector.vector_in_words[3],
                                                                                                          vector.vector_in_words[2],
                                                                                                          vector.vector_in_words[1],
                                                                                                          vector.vector_in_words[0], 
                                                                                                          GET_WEIGHT_ADDR(weight_addr)
            );
            weight_addr.wide++;
        }
    }

    return 0;
}

int setup_interrupt(void) {
    
    int32_t status;

    XScuGic *intc_instance_ptr = &INTCInst;
    XScuGic_Config *intc_config;
    
    intc_config = XScuGic_LookupConfig(XPAR_SCUGIC_DIST_BASEADDR);
    if(NULL == intc_config) {
        return XST_FAILURE;
    }

	status = XScuGic_CfgInitialize(intc_instance_ptr, intc_config, intc_config->CpuBaseAddress);
	if(XST_SUCCESS != status) {
        return status;
    }

	// set interrupt priority
	XScuGic_SetPriorityTriggerType(intc_instance_ptr, XPS_FPGA0_INT_ID, 0x00, 0x3);

    // initialize the exception table
	Xil_ExceptionInit();

    // initialize exception register handler
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, intc_instance_ptr);

    // enable non-critical exceptions
	Xil_ExceptionEnable();

	// connect interrupt controller to PS interrupt service routine
	status = XScuGic_Connect(intc_instance_ptr, XPS_FPGA0_INT_ID, (Xil_ExceptionHandler) isr, (void*) &is_synchronized);
	if(XST_SUCCESS != status) {
        return status;
    }
    
	// enable PS interrupts
	XScuGic_Enable(intc_instance_ptr, XPS_FPGA0_INT_ID);

	return XST_SUCCESS;
}
