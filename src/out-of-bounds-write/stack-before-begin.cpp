#include <cstdio>

// Run the program with no argument to trigger an out of bounds read.
int main(int argc, char** argv)
{
    int values[5] = {1, 2, 3, 4, 5};
    values[-argc] = argc;
    return 0;
}
