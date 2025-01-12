
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
        fprintf(file, "%02X", ciphertext[i]);
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
    printf("\n");
}

int main()
{

    BYTE K[BLOCK_SIZE] = {0};
    BYTE IV[BLOCK_SIZE] = {0}; // Initialization Vector: 128'b0
    WORD RoundKey[144] = {0};
    BYTE Feedback[BLOCK_SIZE] = {0};
    BYTE CipherText[BLOCK_SIZE] = {0};

    const char *outputFile = "ciphertext.txt";
    const char *inputFile = "plaintext.txt";

    // Prompt user for the key
    printf("Enter the encryption key (16 bytes in hexadecimal, e.g., 0f1e2d3c4b5a69788796a5b4c3d2e1f0):\n");
    char keyInput[33];
    printf("Key: ");
    if (scanf("%32s", keyInput) != 1)
    {
        printf("Error: Invalid key input.\n");
        return 1;
    }

    FILE *truncateFile = fopen(outputFile, "w");
    if (truncateFile != NULL)
    {
        fclose(truncateFile);
    }
    else
    {
        printf("Error: Unable to open file %s for writing.\n", outputFile);
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

    // Open input file for reading
    FILE *file = fopen(inputFile, "r");
    if (file == NULL)
    {
        printf("Error: Unable to open file %s\n", inputFile);
        return 1;
    }


    char inputLine[33];
    int lineCount = 0;
    while (fgets(inputLine, sizeof(inputLine), file))
    {
        // Remove trailing newline or carriage return
        size_t len = strlen(inputLine);
        while (len > 0 && (inputLine[len - 1] == '\n' || inputLine[len - 1] == '\r'))
        {
            inputLine[--len] = '\0';
        }

        // Skip empty lines or lines with invalid length
        if (len == 0)
        {
            continue;
        }
        if (len != 32)
        {
            printf("Error: Invalid plaintext format on line: %s\n", inputLine);
            continue;
        }

        lineCount++;

        // Convert input string to BYTE array
        BYTE PlainText[BLOCK_SIZE] = {0};
        int isValid = 1;
        for (int i = 0; i < BLOCK_SIZE; i++)
        {
            if (sscanf(&inputLine[i * 2], "%2hhx", &PlainText[i]) != 1)
            {
                printf("Error: Invalid plaintext format on line: %s\n", inputLine);
                isValid = 0;
                break;
            }
        }
        if (!isValid)
        {
            continue; // Skip processing for this line
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
        /*printf("Ciphertext (hex): ");*/
        /*for (int i = 0; i < BLOCK_SIZE; i++)*/
        /*{*/
        /*    printf("%02X ", CipherText[i]);*/
        /*}*/
        /*printf("\n");*/

        // Print ciphertext in binary
        /*printf("Ciphertext (binary): ");*/
        /*PrintBinary(CipherText, BLOCK_SIZE);*/

        // Write ciphertext to file
        WriteCipherTextToFile(outputFile, CipherText, BLOCK_SIZE);
    }
    fclose(file);
    printf("Encryption complete. Ciphertext written to %s\n", outputFile);
    printf("Processed lines: %d\n", lineCount);

    return 0;
}
