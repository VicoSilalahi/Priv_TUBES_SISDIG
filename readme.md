# Tugas Besar Sistem Digital 2024
## Kelompok 23

> LEA-128
> Methode of Operation: Ciphertext Feedback (CFB)


# ToDo
## FSM For Top Entity
    Signals:
        S_IV: Controls the multiplexer to select the IV source.
        En_IV, En_Key: Enable signals for the IV and key registers.
        START_LEA: Initiates the encryption process.
        isdone: Indicates the completion of the encryption by the LEA_encrypt component.

Proposed FSM:

States:

    IDLE: The initial state. Waits for the start signal.
    LOAD_KEY: Loads the master key from the UART (not yet implemented).
    ENCRYPT: Initiates the LEA_encrypt process.
    SEND_DATA: Sends the ciphertext to the PC via UART (not yet implemented).
    WAIT_FOR_PLAINTEXT: Waits for the next plaintext input from the PC.

State Transitions:

    IDLE -> LOAD_KEY: Upon receiving the start signal, transition to the LOAD_KEY state.
    LOAD_KEY -> ENCRYPT: After loading the master key, transition to the ENCRYPT state.
    ENCRYPT -> SEND_DATA: When the isdone signal from LEA_encrypt is asserted, transition to the SEND_DATA state.
    SEND_DATA -> WAIT_FOR_PLAINTEXT: After sending the ciphertext, transition to the WAIT_FOR_PLAINTEXT state.
    WAIT_FOR_PLAINTEXT -> ENCRYPT: Upon receiving the next plaintext from the PC, transition back to the ENCRYPT state.

State Actions:

    IDLE:
        Set S_IV to '0' to select the initial IV.
        Enable the key register (En_Key) to load the master key.
        Disable the IV register (En_IV).
        Deassert START_LEA.
    LOAD_KEY:
        Set S_IV to '0'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
    ENCRYPT:
        Set S_IV to '1' to select the calculated next IV.
        Enable the IV register (En_IV).
        Disable the key register (En_Key).
        Assert START_LEA to initiate encryption.
    SEND_DATA:
        Set S_IV to '1'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
        Send the ciphertext to the PC via UART (not yet implemented).
    WAIT_FOR_PLAINTEXT:
        Set S_IV to '0'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
        Wait for the next plaintext input from the PC.

## UART Integration and Improvement
1. UART Receiver Enhancements:
---
    128-bit Block Ready Signal:
        Introduce a flag (r_Block_Ready) in the UART receiver FSM.
        Set r_Block_Ready to '1' only when all 16 bytes (128 bits) are received and stored in the buffer.
        Create a new output signal o_RX_Block_Ready and assign it to the value of r_Block_Ready.
    Buffer Management:
        Consider expanding the buffer size or implementing a circular buffer for handling larger messages or continuous data streams.
    Error Handling:
        Add error detection mechanisms (e.g., parity check) to ensure data integrity.
    Data Validity Check:
        Implement checks to ensure the received data is valid (e.g., check for invalid start/stop bits).


2. Top-Level FSM Modifications:
---
    Wait for Block Ready:
        In the WAIT_FOR_PLAINTEXT state, wait for the o_RX_Block_Ready signal from the UART receiver.
        Upon receiving o_RX_Block_Ready, transition to the ENCRYPT state.
    Data Handling in ENCRYPT:
        Read the 128-bit data from the UART receiver's memory buffer.
        Clear the UART receiver's buffer and reset the r_Block_Ready flag (if necessary).
        Proceed with the CFB encryption using the received plaintext.

3. Simulation Parameters:
---
    Determine g_CLKS_PER_BIT:
        Calculate g_CLKS_PER_BIT based on the desired baud rate (115200 baud) and the internal clock frequency (10 MHz).
        Round the calculated value to the nearest integer.
    Fine-tune g_CLKS_PER_BIT:
        Adjust g_CLKS_PER_BIT as needed to achieve optimal simulation accuracy.

4. Additional Considerations:
---
    Flow Control: Implement flow control mechanisms (e.g., XON/XOFF) to prevent data overflow.
    Interrupt Handling: Utilize interrupts from the UART receiver for improved responsiveness.
    Timing Constraints: Analyze and address timing constraints for the UART and the encryption process.

This list provides a concise summary of the key enhancements and considerations for your UART and CFB encryption system. Remember to thoroughly test and refine your implementation based on your specific requirements and simulation results.