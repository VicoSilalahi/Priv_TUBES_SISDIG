# Tugas Besar Sistem Digital 2024
## Kelompok 23

> LEA-128 Encryption
> Method of Operation: Ciphertext Feedback (CFB)

# USE CLIENT
Windows Only?
```ps
cd .\Client\
python .\main.py
```

# HOW TO SIMULATE
## For src : (in \srrc\\)
```ps
ghdl --remove
ghdl -a --std=02 --work=work *.vhd
ghdl -e --std=02 --work=work top_tb
ghdl -r --std=02 --work=work top_tb --wave=wave.ghw
gtkwave .\wave.ghw &
```
Simulations can be done with running the given PowerShell as well:
```ps
.\runtbtop.ps1
```
## For UART_TOP: (in \UART\\)
```ps
ghdl --remove
ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -e --std=02 --work=work UART_TOP
ghdl -a --std=02 --work=work TOP_tb.vhd
ghdl -e --std=02 --work=work UART_TOP_tb
ghdl -r --std=02 --work=work UART_TOP_tb --wave=wave.ghw
gtkwave .\wave.ghw &
```
## For UART_RX: (in \UART\\)

```ps
ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -a --std=02 --work=work UART_RX_tb.vhd
ghdl -r --std=02 --work=work UART_RX_tb --wave=wave.ghw
gtkwave .\wave.ghw &
```
Simulations can be done with running the given PowerShell as well:
```ps
.\runRXTB.ps1
```
## For UART_TX: (in \UART\\)
```ps
ghdl --remove
ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -a --std=02 --work=work UART_TX_tb.vhd
ghdl -r --std=02 --work=work UART_TX_tb --wave=wave.ghw
gtkwave .\wave.ghw &
```
Simulations can be done with running the given PowerShell as well:
```ps
.\runTXTB.ps1
```