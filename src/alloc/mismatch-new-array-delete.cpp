#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = new int[argc];

    for (int i = 0; i != argc; ++i)
        value[i] = i;

    // Intentionally use the wrong delete version.
    delete value;

    return 0;
}
