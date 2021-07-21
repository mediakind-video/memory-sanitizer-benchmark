#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = new int[argc];

    for (int i = 0; i != argc; ++i)
        value[i] = i;

    // delete[] should be used to release the memory.
    free(value);

    return 0;
}
