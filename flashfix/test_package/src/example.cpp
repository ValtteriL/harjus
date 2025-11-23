#include "flashfix.h"
#include <vector>
#include <string>

int main() {
    flashfix();

    std::vector<std::string> vec;
    vec.push_back("test_package");

    flashfix_print_vector(vec);
}
