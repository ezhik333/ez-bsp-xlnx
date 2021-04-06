# need Vitis 2020.2+, device-tree-compiler, u-boot-tools
# need board with ZynqMP supported by Xilinx

# Path where 'linux-xlnx' repository is stored
TOOLCHAIN_XLNX_PATH=EDIT_THIS_IN_MAKEFILE

# Path where 'Image' 'u-boot.elf' 'bl31.elf' are stored
TOOLCHAIN_XLNX_OUT_PATH=EDIT_THIS_IN_MAKEFILE

# Project .xsa
MY_XSA_PATH=EDIT_THIS_IN_MAKEFILE

# Board version ( check .dtb files at /linux-xlnx/arch/arm64/boot/dts/xilinx/ )
BOARD_VERSION=zynqmp-zcu106-revA

# Architecture (for future makefile modifications)
ARCH=arm64

all: image boot

clean:
	rm -rf ./dt/ ./zynqmp_*/ ./.Xil/ image.ub BOOT.BIN *.elf *.dtb *.dts *.tcl ./Image

image: image.ub

boot: BOOT.BIN

# make FIT image
image.ub: Image system.dtb
	mkimage -f fitImage.its image.ub

# make BIN
BOOT.BIN: u-boot.elf bl31.elf zynqmp_fsbl.elf zynqmp_pmufw.elf
	bootgen -w -image boot.bif -o i BOOT.BIN -arch zynqmp

fsbl: zynqmp_fsbl.elf

pmufw: zynqmp_pmufw.elf

dtb: system.dtb

Image:
	cp -u ${TOOLCHAIN_XLNX_OUT_PATH}/Image ./

u-boot.elf:
	cp -u ${TOOLCHAIN_XLNX_OUT_PATH}/u-boot.elf ./

bl31.elf:
	cp -u ${TOOLCHAIN_XLNX_OUT_PATH}/bl31.elf ./

zynqmp_fsbl.elf:
	echo "hsi::open_hw_design ${MY_XSA_PATH}" > generate_fsbl.tcl
	echo "hsi::create_sw_design fsbl -proc psu_cortexa53_0" >> generate_fsbl.tcl
	echo "hsi::report_property [hsi::current_hw_design]" >> generate_fsbl.tcl
	echo "hsi::generate_app -app zynqmp_fsbl -proc psu_cortexa53_0 -dir ./zynqmp_fsbl -compile" >> generate_fsbl.tcl
	echo "exit" >> generate_fsbl.tcl
	xsct generate_fsbl.tcl
	cp -u ./zynqmp_fsbl/executable.elf ./zynqmp_fsbl.elf

zynqmp_pmufw.elf:
	echo "hsi::open_hw_design ${MY_XSA_PATH}" > generate_pmufw.tcl
	echo "hsi::create_sw_design fsbl -proc psu_cortexa53_0" >> generate_pmufw.tcl
	echo "hsi::generate_app -app zynqmp_pmufw -proc psu_pmu_0 -dir ./zynqmp_pmufw -compile" >> generate_pmufw.tcl
	echo "exit" >> generate_pmufw.tcl
	xsct generate_pmufw.tcl
	cp -u ./zynqmp_pmufw/executable.elf ./zynqmp_pmufw.elf

# Not easy to correct build device tree with PL logic
system.dtb:
	echo "hsi::open_hw_design ${MY_XSA_PATH}" > generate_dtsi.tcl
	echo "hsi::set_repo_path ${TOOLCHAIN_XLNX_PATH}" >> generate_dtsi.tcl
	echo "hsi::generate_bsp -proc psu_cortexa53_0 -dir ./dt -os device_tree"  >> generate_dtsi.tcl
	echo "exit" >> generate_dtsi.tcl
	xsct generate_dtsi.tcl    

	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/arch/${ARCH}/boot/dts/xilinx/${BOARD_VERSION}.dts	 ./dt/${BOARD_VERSION}.dts
	mkdir -p ./dt/include/dt-bindings/input/
	mkdir -p ./dt/include/dt-bindings/gpio/
	mkdir -p ./dt/include/dt-bindings/pinctrl/
	mkdir -p ./dt/include/dt-bindings/phy/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/power/xlnx-zynqmp-power.h  ./dt/include/dt-bindings/power/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/reset/xlnx-zynqmp-resets.h  ./dt/include/dt-bindings/reset/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/clock/xlnx-zynqmp-clk.h  ./dt/include/dt-bindings/clock/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/input/input.h  ./dt/include/dt-bindings/input/input.h
	cp -H ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/input/linux-event-codes.h  ./dt/include/dt-bindings/input/linux-event-codes.h
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/gpio/gpio.h  ./dt/include/dt-bindings/gpio/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/pinctrl/pinctrl-zynqmp.h  ./dt/include/dt-bindings/pinctrl/
	cp ${TOOLCHAIN_XLNX_PATH}/linux-xlnx/scripts/dtc/include-prefixes/dt-bindings/phy/phy.h  ./dt/include/dt-bindings/phy/
	echo "/ {" > ./dt/system-top.dtsi
	sed '1,/\/ {/ d' < ./dt/system-top.dts >> ./dt/system-top.dtsi
	sed '0,/\/ {/s/\/ {/#include "pl.dtsi" \n#include "pcw.dtsi"\n\/ {/' < ./dt/${BOARD_VERSION}.dts > ./dt/${BOARD_VERSION}_out.dts;
	cp -u ./user.dtsi ./dt/
	echo "#include \"user.dtsi\"" >> ./dt/${BOARD_VERSION}_out.dts;
	gcc -I./dt -I./dt/include -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o ./dt/${BOARD_VERSION}_out.dts.tmp ./dt/${BOARD_VERSION}_out.dts
	dtc -I dts -O dtb -o ./dt/system.dtb ./dt/${BOARD_VERSION}_out.dts.tmp
	dtc -O dts -I dtb -o ./dt/system.dts ./dt/system.dtb
	cp -u ./dt/system.dts ./
	cp -u ./dt/system.dtb ./








