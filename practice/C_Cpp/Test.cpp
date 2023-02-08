#include "Test.h"

int Test::show() {
    return this->keep;
}

Test::Test() {
    keep = 0;
}

Test::Test(int num) {
    this->keep = num;
}

void Test::add() {
    this->keep++;
}
