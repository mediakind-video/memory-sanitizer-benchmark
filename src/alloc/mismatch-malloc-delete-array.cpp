#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = (int*)malloc(sizeof(int));

    *value = argc;

    // free() should be used to release the memory.
    delete[] value;

    return 0;
}
