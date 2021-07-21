#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

int main(int argc, char** argv)
{
    // The test creates a buffer of 4 * 4 + 4 = 20 bytes, where only the
    // 16 first bytes are valid and set to their index:
    //
    // 0123 4567 89ab cdef xxxx
    //
    // Then the argc-th byte is removed by moving the following bytes one cell
    // to the left. The move is done four bytes at once, so the first
    // indeterminate byte becomes the 16th. E.g. by removing the byte at
    // index 2:
    //
    //                   + New indeterminate value.
    //                   |
    //                   v
    // 0134 5678 9abc defx xxxx
    //
    // Unless this 16th byte is used in computations, the move is not an issue.
    // More explicitly, the sanitizer should not trigger an error.

    constexpr int n = 4 * sizeof(uint32_t);

    // Add one extra uint32_t to allow reading after the last element.
    uint8_t* values = (uint8_t*)malloc(n + sizeof(uint32_t));

    // Leave the padding uninitialized.
    for (int i = 0; i != n; ++i)
        values[i] = i;

    // Now move everything after the argc-th element down by one, effectively
    // removing the element. We switch to uint32_t to move the values four by
    // four.
    uint32_t* dst = (uint32_t*)(values + argc);
    uint32_t* src = (uint32_t*)(values + argc + 1);

    while ((uint8_t*)src <= values + n)
    {
        *dst = *src;
        ++dst;
        ++src;
    }

    assert((uint8_t*)(src - 1) <= values + n);
    assert((uint8_t*)src >= values + n);

    // At this point value[n-1] is indeterminate, so we display only the values
    // before it.
    for (int i = 0; i != n - 1; ++i)
        printf(" %d", values[i]);
    printf("\n");

    free(values);
    return 0;
}
