#include <cstdio>

int values[5] = {1, 2, 3, 4, 5};

// Run the program with four arguments to trigger an out of bounds read.
int main(int argc, char** argv)
{
    printf("%d\n", values[argc]);
    return 0;
}
