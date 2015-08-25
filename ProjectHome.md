The goal is to have a working Snes 100% coded in VHDL.
There are 4 part to make :
- CPU : The cpu itself.
- PPU : The graphic chip.
- APU : The audio chip, which is made of 3 modules.
(Cpu, A-DSP,S-DSP)
- CPU related : DMA, joystick reading, etc...

My focus is primarily the PPU for now.

I have grabbed the A-DSP,S-DSP from another project.

And it seems that there is a working CPU 65c816 core on the net floating around.