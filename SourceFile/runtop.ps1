ghdl --remove
ghdl -a --std=02 --work=work *.vhd
ghdl -e --std=02 --work=work TOP_UART_tb
ghdl -r --std=02 --work=work TOP_UART_tb --wave=wave.ghw
#gtkwave .\wave.ghw &
