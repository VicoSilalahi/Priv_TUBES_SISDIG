ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -a --std=02 --work=work UART_RX_tb.vhd
# ghdl -e --std=02 --work=work TOP
# ghdl -a --std=02 --work=work TOP_tb.vhd
# ghdl -e --std=02 --work=work TOP_tb
ghdl -r --std=02 --work=work UART_RX_tb --wave=wave.ghw
gtkwave .\wave.ghw &