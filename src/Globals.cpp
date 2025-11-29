
#include <atomic>

std::atomic<bool> isShuttingDown{false};
std::atomic<bool> running{true};