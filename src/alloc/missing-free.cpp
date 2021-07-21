#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = (int*)malloc(argc * sizeof(int));

    // The value variable is intentionally not freed.

    return 0;
}
