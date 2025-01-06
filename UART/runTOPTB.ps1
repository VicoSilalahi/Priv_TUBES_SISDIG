ghdl --remove
ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -e --std=02 --work=work UART_TOP
ghdl -a --std=02 --work=work TOP_tb.vhd
ghdl -e --std=02 --work=work UART_TOP_tb
ghdl -r --std=02 --work=work UART_TOP_tb --wave=wave.ghw
# gtkwave .\wave.ghw &
