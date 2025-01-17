
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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

// Function to compare files for validation
int CompareFiles(const char *file1, const char *file2)
{
    FILE *f1 = fopen(file1, "r");
    FILE *f2 = fopen(file2, "r");
    if (f1 == NULL || f2 == NULL)
    {
        printf("Error: Unable to open one of the files for comparison.\n");
        if (f1) fclose(f1);
        if (f2) fclose(f2);
        return 0;
    }

    char line1[BLOCK_SIZE * 2 + 1];
    char line2[BLOCK_SIZE * 2 + 1];

    int lineCount = 0;
    while (fgets(line1, sizeof(line1), f1) && fgets(line2, sizeof(line2), f2))
    {
        lineCount++;
        // Remove trailing newline or carriage return
        line1[strcspn(line1, "\r\n")] = '\0';
        line2[strcspn(line2, "\r\n")] = '\0';

        if (strcmp(line1, line2) != 0)
        {
            printf("Mismatch on line %d:\nFPGA Output: %s\nSoftware Output: %s\n", lineCount, line2, line1);
            fclose(f1);
            fclose(f2);
            return 0; // Files do not match
        }
    }

    if (!feof(f1) || !feof(f2))
    {
        printf("Files have different lengths.\n");
        fclose(f1);
        fclose(f2);
        return 0;
    }

    fclose(f1);
    fclose(f2);
    return 1; // Files match
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: %s <master_key>\n", argv[0]);
        return 1;
    }

    const char *masterKeyInput = argv[1];
    if (strlen(masterKeyInput) != BLOCK_SIZE * 2)
    {
        printf("Error: Master key must be 16 bytes (32 hexadecimal characters).\n");
        return 1;
    }

    BYTE K[BLOCK_SIZE] = {0};
    BYTE IV[BLOCK_SIZE] = {0}; // Initialization Vector: 128'b0
    WORD RoundKey[144] = {0};
    BYTE Feedback[BLOCK_SIZE] = {0};
    BYTE CipherText[BLOCK_SIZE] = {0};

    const char *inputFile = "output_hex_comma.txt";
    const char *outputFile = "output_ciphertext.txt";
    const char *fpgaFile = "capture_hex.txt";

    // Convert master key input to BYTE array
    for (int i = 0; i < BLOCK_SIZE; i++)
    {
        if (sscanf(&masterKeyInput[i * 2], "%2hhx", &K[i]) != 1)
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

    // Clear output file
    FILE *truncateFile = fopen(outputFile, "w");
    if (truncateFile != NULL)
    {
        fclose(truncateFile);
    }
    else
    {
        printf("Error: Unable to open file %s for writing.\n", outputFile);
        fclose(file);
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
        for (int i = 0; i < BLOCK_SIZE; i++)
        {
            if (sscanf(&inputLine[i * 2], "%2hhx", &PlainText[i]) != 1)
            {
                printf("Error: Invalid plaintext format on line: %s\n", inputLine);
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

        // Write ciphertext to file
        WriteCipherTextToFile(outputFile, CipherText, BLOCK_SIZE);
    }
    fclose(file);

    return 0;
}
