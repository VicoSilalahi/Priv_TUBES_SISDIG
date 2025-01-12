ghdl --remove
ghdl -a --std=02 --work=work *.vhd
ghdl -e --std=02 --work=work LEA_128_tb
ghdl -r --std=02 --work=work LEA_128_tb --wave=wave.ghw