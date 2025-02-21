#include "syscall.h"

void printChar(char c, int n)
{
    int i;
    for (i = 0; i < n; i++) {
        PutChar(c + i);
    }
    PutChar('\n');
}

int main()
{
    printChar('a', 6);
    
    PutString("12345678ABCDE funcionou!\n");

    Halt();
}