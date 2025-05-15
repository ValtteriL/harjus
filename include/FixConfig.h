#pragma once

#include "IConfiguration.h"
#include <quickfix/SessionSettings.h>
#include <string>

/**
 * @brief FixConfig encapsulates the configuration for the QuickFIX engine.
 * @details Reads the configuration from an IConfiguration object and provides
 * methods to access the session settings. It also handles the creation and
 * cleanup of required files and directories on disk.
 */
class FixConfig {
private:
  std::string _configString;

public:
  /**
   * @brief Constructor
   * @param config The configuration object containing the settings.
   * @details The constructor reads the configuration from the provided
   * IConfiguration object and generates the necessary configuration string.
   * It also creates the required directories and files on disk.
   */
  FixConfig(IConfiguration &config);

  /**
   * @brief Get the session settings.
   * @return The session settings for the QuickFIX engine.
   */
  FIX::SessionSettings sessionSettings() const;
};
