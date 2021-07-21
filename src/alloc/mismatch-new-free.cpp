#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = new int(argc);

    // delete should be used to release the memory.
    free(value);

    return 0;
}
