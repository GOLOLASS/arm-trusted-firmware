/*
 * Copyright (c) 2015-2017, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */
#include <asm_macros.S>
#include <platform_def.h>

	.weak	plat_arm_calc_core_pos
	.weak	plat_my_core_pos
	.globl	plat_crash_console_init
	.globl	plat_crash_console_putc
	.globl	plat_crash_console_flush
	.globl	platform_mem_init
	.globl	arm_disable_spe


	/* -----------------------------------------------------
	 *  unsigned int plat_my_core_pos(void)
	 *  This function uses the plat_arm_calc_core_pos()
	 *  definition to get the index of the calling CPU.
	 * -----------------------------------------------------
	 */
func plat_my_core_pos
	mrs	x0, mpidr_el1
	b	plat_arm_calc_core_pos
endfunc plat_my_core_pos

	/* -----------------------------------------------------
	 *  unsigned int plat_arm_calc_core_pos(u_register_t mpidr)
	 *  Helper function to calculate the core position.
	 *  With this function: CorePos = (ClusterId * 4) +
	 *  				  CoreId
	 * -----------------------------------------------------
	 */
func plat_arm_calc_core_pos
	and	x1, x0, #MPIDR_CPU_MASK
	and	x0, x0, #MPIDR_CLUSTER_MASK
	add	x0, x1, x0, LSR #6
	ret
endfunc plat_arm_calc_core_pos

	/* ---------------------------------------------
	 * int plat_crash_console_init(void)
	 * Function to initialize the crash console
	 * without a C Runtime to print crash report.
	 * Clobber list : x0 - x4
	 * ---------------------------------------------
	 */
func plat_crash_console_init
	mov_imm	x0, PLAT_ARM_CRASH_UART_BASE
	mov_imm	x1, PLAT_ARM_CRASH_UART_CLK_IN_HZ
	mov_imm	x2, ARM_CONSOLE_BAUDRATE
	b	console_core_init
endfunc plat_crash_console_init

	/* ---------------------------------------------
	 * int plat_crash_console_putc(int c)
	 * Function to print a character on the crash
	 * console without a C Runtime.
	 * Clobber list : x1, x2
	 * ---------------------------------------------
	 */
func plat_crash_console_putc
	mov_imm	x1, PLAT_ARM_CRASH_UART_BASE
	b	console_core_putc
endfunc plat_crash_console_putc

	/* ---------------------------------------------
	 * int plat_crash_console_flush()
	 * Function to force a write of all buffered
	 * data that hasn't been output.
	 * Out : return -1 on error else return 0.
	 * Clobber list : r0 - r1
	 * ---------------------------------------------
	 */
func plat_crash_console_flush
	mov_imm	x1, PLAT_ARM_CRASH_UART_BASE
	b	console_core_flush
endfunc plat_crash_console_flush

	/* ---------------------------------------------------------------------
	 * We don't need to carry out any memory initialization on ARM
	 * platforms. The Secure RAM is accessible straight away.
	 * ---------------------------------------------------------------------
	 */
func platform_mem_init
	ret
endfunc platform_mem_init

	/* -----------------------------------------------------
	 * void arm_disable_spe (void);
	 * -----------------------------------------------------
	 */
#if ENABLE_SPE_FOR_LOWER_ELS
func arm_disable_spe
	/* Detect if SPE is implemented */
	mrs	x0, id_aa64dfr0_el1
	ubfx	x0, x0, #ID_AA64DFR0_PMS_SHIFT, #ID_AA64DFR0_PMS_LENGTH
	cmp	x0, #0x1
	b.ne	1f

	/* Drain buffered data */
	.arch	armv8.2-a+profile
	psb	csync
	dsb	nsh

	/* Disable Profiling Buffer */
	mrs	x0, pmblimitr_el1
	bic	x0, x0, #1
	msr	pmblimitr_el1, x0
	isb
	.arch	armv8-a
1:
	ret
endfunc arm_disable_spe
#endif
