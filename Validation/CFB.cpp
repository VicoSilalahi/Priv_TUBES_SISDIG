#include <stdio.h>
#include <string.h>
#include "lea.h"

#define BLOCK_SIZE 16

// Function to write ciphertext to a file
void WriteCipherTextToFile(const char *filename, BYTE *ciphertext, int length)
{
    FILE *file = fopen(filename, "a");
    if (file == NULL)
    {
        printf("Error: Unable to open file %s\n", filename);
        return;
    }

    for (int i = 0; i < length; i++)
    {
        fprintf(file, "%02x", ciphertext[i]);
    }
    fprintf(file, "\n");
    fclose(file);
}

// Function to print a BYTE array in binary format
void PrintBinary(BYTE *data, int length)
{
    for (int i = 0; i < length; i++)
    {
        for (int j = 7; j >= 0; j--)
        {
            printf("%d", (data[i] >> j) & 1);
        }
        printf(" ");
    }
}

int main()
{
    BYTE K[BLOCK_SIZE] = {0};
    BYTE IV[BLOCK_SIZE] = {0}; // Initialization Vector: 128'b0
    WORD RoundKey[144] = {0};
    BYTE Feedback[BLOCK_SIZE] = {0};
    BYTE CipherText[BLOCK_SIZE] = {0};

    const char *outputFile = "ciphertext.txt";

    // Prompt user for the key
    printf("Enter the encryption key (16 bytes in hexadecimal, e.g., 0f1e2d3c4b5a69788796a5b4c3d2e1f0):\n");
    char keyInput[33];
    printf("Key: ");
    if (scanf("%32s", keyInput) != 1)
    {
        printf("Error: Invalid key input.\n");
        return 1;
    }

    // Convert key input string to BYTE array
    for (int i = 0; i < BLOCK_SIZE; i++)
    {
        if (sscanf(&keyInput[i * 2], "%2hhx", &K[i]) != 1)
        {
            printf("Error: Invalid key format.\n");
            return 1;
        }
    }

    // Initialize key schedule
    KeySchedule_128(K, RoundKey);
    memcpy(Feedback, IV, BLOCK_SIZE); // Set initial feedback to IV

    printf("Enter plaintext (16 bytes in hexadecimal, e.g., 101112131415161718191a1b1c1d1e1f):\n");
    while (1)
    {
        char input[33];
        printf("Plaintext: ");
        if (scanf("%32s", input) != 1)
        {
            printf("Error: Invalid plaintext input.\n");
            return 1;
        }

        // Convert input string to BYTE array
        BYTE PlainText[BLOCK_SIZE] = {0};
        for (int i = 0; i < BLOCK_SIZE; i++)
        {
            if (sscanf(&input[i * 2], "%2hhx", &PlainText[i]) != 1)
            {
                printf("Error: Invalid plaintext format.\n");
                return 1;
            }
        }

        // Encrypt using CFB mode
        BYTE EncryptedFeedback[BLOCK_SIZE] = {0};
        Encrypt(24, RoundKey, Feedback, EncryptedFeedback); // Encrypt feedback
        for (int i = 0; i < BLOCK_SIZE; i++)
        {
            CipherText[i] = PlainText[i] ^ EncryptedFeedback[i]; // XOR plaintext with encrypted feedback
        }
        memcpy(Feedback, CipherText, BLOCK_SIZE); // Update feedback with ciphertext

        // Print ciphertext in hexadecimal
        printf("Ciphertext (hex): ");
        for (int i = 0; i < BLOCK_SIZE; i++)
        {
            printf("%02x ", CipherText[i]);
        }
        printf("\n");

        // Print ciphertext in binary
        printf("Ciphertext (binary): ");
        PrintBinary(CipherText, BLOCK_SIZE);
        printf("\n");

        // Write ciphertext to file
        WriteCipherTextToFile(outputFile, CipherText, BLOCK_SIZE);
    }

    return 0;
}
