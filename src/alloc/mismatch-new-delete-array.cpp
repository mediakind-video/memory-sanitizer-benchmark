#include <cstdlib>

int main(int argc, char** argv)
{
    int* value = new int(argc);

    // Intentionally use the wrong delete version.
    delete[] value;

    return 0;
}
