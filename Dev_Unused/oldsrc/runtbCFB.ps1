ghdl --remove
ghdl -a --std=02 --work=work *.vhd
ghdl -e --std=02 --work=work CFB_tb
ghdl -r --std=02 --work=work CFB_tb --wave=wave.ghw
#gtkwave .\wave.ghw &
