ghdl --remove
ghdl -a --std=02 --work=work *.vhd
ghdl -e --std=02 --work=work cypher_block_tb
ghdl -r --std=02 --work=work cypher_block_tb --wave=wave.ghw
