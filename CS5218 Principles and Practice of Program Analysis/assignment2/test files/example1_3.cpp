#include <cassert>
int main() {
    int x, y=10, z = 5;
    if (y != 10)
        x = z + 5;
    else
        x = z - 5;
    assert (x < 5);
    return x;
}