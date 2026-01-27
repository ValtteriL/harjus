#pragma once

#include "IApplication.h"
#include <gmock/gmock.h>

class MockApplication : public IApplication
{
public:
    virtual ~MockApplication() = default;
    MOCK_METHOD(void, submitOrder,
                (const std::string &id, const std::string &symbol,
                 PreciseNumber qty, PreciseNumber price, Position position),
                (override));
};
