# ez-bsp-xlnx
Makefile for building device-tree, fsbl, pmufw and combining it with prebuilt images to BOOT.bin

Need Vitis 2020.2+, device-tree-compiler, u-boot-tools

Path to ``xsct`` must be added to ``PATH`` variable.

Need board with ZynqMP supported by Xilinx

Tested for ZCU106 board.

# How to use
Edit Makefile:

``TOOLCHAIN_XLNX_PATH`` - path where 'linux-xlnx' repository is stored

``TOOLCHAIN_XLNX_OUT_PATH`` - path where 'Image' 'u-boot.elf' 'bl31.elf' are stored

``MY_XSA_PATH`` - path to your project hardware description '.xsa' file

``BOARD_VERSION`` -- name of board version ( check .dtb files at /linux-xlnx/arch/arm64/boot/dts/xilinx/ )

Run:

    make