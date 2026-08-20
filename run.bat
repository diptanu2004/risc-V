@echo off
setlocal
cd /d "%~dp0"
if not exist sim mkdir sim
iverilog -g2012 -o sim\cpu_sim.exe alu.v control.v regfile.v forwarding_unit.v hazard_unit.v rv32i_cpu.v tb.v
if errorlevel 1 (
  echo.
  echo Compilation failed. Make sure Icarus Verilog is installed and in PATH.
  pause
  exit /b 1
)
vvp sim\cpu_sim.exe
if exist cpu.vcd gtkwave cpu.vcd
pause
