all:
	iverilog -g2012 -o sim.vvp rtl/*.sv tb/*.sv && vvp sim.vvp
