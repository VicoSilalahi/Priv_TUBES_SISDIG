ghdl --remove
ghdl -a --std=02 --work=work .\UART_RX.vhd .\UART_TX.vhd .\TOP.vhd
ghdl -e --std=02 --work=work UART_RX
ghdl -e --std=02 --work=work UART_TX
ghdl -a --std=02 --work=work UART_TX_tb.vhd
ghdl -r --std=02 --work=work UART_TX_tb --wave=wave.ghw
# gtkwave .\wave.ghw &
