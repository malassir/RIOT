/*
 * Copyright 2013, Freie Universitaet Berlin (FUB). All rights reserved.
 *
 * This file is subject to the terms and conditions of the GNU Lesser
 * General Public License v2.1. See the file LICENSE in the top level
 * directory for more details.
 */

/* specify the LPC2387 memory areas (see LPC2387 datasheet page 15)  */
MEMORY
{
    rom (rx)            : ORIGIN = 0,          LENGTH = 504K    /* FLASH ROM 512kByte without ISP bootloader*/
    infomem             : ORIGIN = 0x0007D000, LENGTH = 4K      /* Last sector in FLASH ROM for config data */
    ram_battery         : ORIGIN = 0xE0084000, LENGTH = 2K      /* Battery RAM                              */
    ram (w!rx)          : ORIGIN = 0x40000000, LENGTH = 64K     /* LOCAL ON-CHIP STATIC RAM                 */
    ram_usb             : ORIGIN = 0x7FD00000, LENGTH = 16K     /* USB RAM  !!! first 1024 bytes are occupied from GPDMA for MCI */
    ram_ethernet        : ORIGIN = 0x7FE00000, LENGTH = 16K     /* ethernet RAM                             */
}

__stack_und_size = 4;           /* stack for "undefined instruction" interrupts             */
__stack_abt_size = 4;           /* stack for "abort" interrupts                             */
__stack_fiq_size = 64;          /* stack for "FIQ" interrupts                               */
__stack_irq_size = 400;         /* stack for "IRQ" normal interrupts                        */
__stack_svc_size = 400;         /* stack for "SVC" supervisor mode                          */
__stack_usr_size = 4096;        /* stack for user operation (kernel init)                   */
__stack_size = __stack_und_size + __stack_abt_size + __stack_fiq_size + __stack_irq_size + __stack_svc_size + __stack_usr_size;

/* now define the output sections  */
SECTIONS
{
    .text :                             /* collect all sections that should go into FLASH after startup  */
    {
        KEEP(*(.vectors))               /* Exception Vectors and branch table >= 64 bytes */
        . = ALIGN(64);
        KEEP(*(.init))
        KEEP(*(.init0))                 /* Start here after reset.  */
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)

        /* Support C constructors, and C destructors in both user code
           and the C library. This also provides support for C++ code. */
        . = ALIGN(4);
        KEEP(*(.init))
        . = ALIGN(4);
        __preinit_array_start = .;
        KEEP (*(.preinit_array))
        __preinit_array_end = .;

        . = ALIGN(4);
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = .;

        . = ALIGN(0x4);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))

        . = ALIGN(4);
        KEEP(*(.fini))

        . = ALIGN(4);
        __fini_array_start = .;
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        __fini_array_end = .;

        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        . = ALIGN(4);
        _efixed = .;            /* End of text section */
    } > rom

    /* .ARM.exidx is sorted, so has to go in its own output section.  */
    PROVIDE_HIDDEN (__exidx_start = .);
    .ARM.exidx :
    {
      *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > rom
    PROVIDE_HIDDEN (__exidx_end = .);

    /* exception handling */
    . = ALIGN(4);
    .eh_frame :
    {
        KEEP (*(.eh_frame))
    } > rom

    . = ALIGN(4);
    _etext = .;

    .config :
    {
        *(.configmem)
        . = ALIGN(256);
    } > infomem

/**************************************************************************
 * RAM
 **************************************************************************/

    /*
     * Stacks
     */
    .stack (NOLOAD) :
    {
        PROVIDE(__stack_start = .);

        . = . + __stack_usr_size;
        __stack_usr_start = .;
        . = . + __stack_und_size;
        __stack_und_start = .;
        . = . + __stack_fiq_size;
        __stack_fiq_start = .;
        . = . + __stack_irq_size;
        __stack_irq_start = .;
        . = . + __stack_abt_size;
        __stack_abt_start = .;
        . = . + __stack_svc_size;
        __stack_svc_start = .;

        PROVIDE(__stack_end = .);
    } > ram

    .relocate :
    {
        . = ALIGN(4);
        _srelocate = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        KEEP (*(.openocd .openocd.*))
        . = ALIGN(4);
        _erelocate = .;
    } > ram AT> rom

    /* .bss section which is used for uninitialized data */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = . ;
        _szero = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
        _ezero = .;
    } > ram

    /*
     * collect all uninitialized sections that go into RAM
     */
    .noinit (NOLOAD) :
    {
        __noinit_start = .;
        PROVIDE(__fiq_handler = .);
        *(.fiq)
        *(.noinit)
        . = ALIGN(4);
        __noinit_end = .;
    }  > ram

    /* heap section */
    . = ALIGN(4);
    _sheap = . ;
    _eheap = ORIGIN(ram) + LENGTH(ram);

    /* Populate information about ram size */
    _sram = ORIGIN(ram);
    _eram = ORIGIN(ram) + LENGTH(ram);

    __heap2_size = LENGTH(ram_ethernet);
    .heap2 (NOLOAD) :
    {
        PROVIDE(__heap2_start = . );
    } > ram_ethernet

    . = ORIGIN(ram_usb);
    .usbdata (NOLOAD) :                 /* USB RAM section, may be used otherwise if USB is disabled */
    {
        *(.usbdata)
    } > ram_usb

    .heap3 ALIGN(0x1000) (NOLOAD) :
    {
        __heap3_size = ORIGIN(ram_usb) + LENGTH(ram_usb) - ABSOLUTE(.);
        PROVIDE(__heap3_start = . );
    } > ram_usb
    __heap_size = SIZEOF(.heap3);

    _sbackup_data_load = LOADADDR(.backup.data);
    .backup.data :  ALIGN(4) {
        _sbackup_data = .;
        *(.backup.data)
        _ebackup_data = .;
        /* Round size so that we can use 4 byte copy in init */
        . = ALIGN(4);
    } > ram_battery AT> rom

    .backup.bss (NOLOAD) : ALIGN(4) {
        _sbackup_bss = .;
        *(.backup.bss)
        _ebackup_bss = .;
        /* Round size so that we can use 4 byte copy in init */
        . = ALIGN(4);
    } > ram_battery
}
