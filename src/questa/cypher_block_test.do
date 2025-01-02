vsim -voptargs=+acc work.cypher_block
add wave sim:/cypher_block/*
force -freeze sim:/cypher_block/Plaintext 128'b00010000000100010001001000010011000101000001010100010110000101110001100000011001000110100001101100011100000111010001111000011111 0
force -freeze sim:/cypher_block/Master_Key 128'b00001111000111100010110100111100010010110101101001101001011110001000011110010110101001011011010011000011110100101110000111110000 0
force -freeze sim:/cypher_block/Start 0 0
force -freeze sim:/cypher_block/Stop 1 0
force -freeze sim:/cypher_block/Clock 0 0, 1 {25 ns} -r 50
run 100ns
force -freeze sim:/cypher_block/Start 1 0
run 100ns
force -freeze sim:/cypher_block/Start 0 0
run 2000ns