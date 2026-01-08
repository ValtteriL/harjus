include(CTest)

set (ut_SOURCES
  catch_amalgamated.cpp
  ut.cpp
  DataDictionaryTestCase.cpp
  DataDictionaryProviderTestCase.cpp
  DictionaryTestCase.cpp
  FieldBaseTestCase.cpp
  FieldConvertorsTestCase.cpp
  FieldMapTestCase.cpp
  FieldTypesTestCase.cpp
  FileLogTestCase.cpp
  FileStoreFactoryTestCase.cpp
  FileStoreTestCase.cpp
  FileUtilitiesTestCase.cpp
  GroupTestCase.cpp
  HostDetailsProviderTestCase.cpp
  MemoryStoreTestCase.cpp
  MessageSortersTestCase.cpp
  MessagesTestCase.cpp
  NullStoreTestCase.cpp
  ParserTestCase.cpp
  SessionFactoryTestCase.cpp
  SessionIDTestCase.cpp
  SessionSettingsTestCase.cpp
  SessionStateTestCase.cpp
  SessionTestCase.cpp
  SettingsTestCase.cpp
  SharedArrayTestCase.cpp
  StringUtilitiesTestCase.cpp
  TestHelper.cpp
  TimeRangeTestCase.cpp
  UtcTimeOnlyTestCase.cpp
  UtcTimeStampTestCase.cpp
  UtilityTestCase.cpp
)

add_definitions(-DCATCH_AMALGAMATED_CUSTOM_MAIN)
  
add_executable(FlashfixTest ${ut_SOURCES})
  
target_include_directories(FlashfixTest 
  PRIVATE include
)

target_link_libraries(FlashfixTest
  PRIVATE
    flashfix_objs
)

# Register with CTest so it runs with `just test`
add_test(
  NAME FlashfixTest
  COMMAND FlashfixTest --flashfix-spec-path ${CMAKE_CURRENT_SOURCE_DIR}/../spec
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

# Disable leak detection for FlashfixTest due to pre-existing memory leaks in the library.
# The F-Stack socket tests are also skipped because they require F-Stack to be initialized.
set_tests_properties(FlashfixTest PROPERTIES ENVIRONMENT "ASAN_OPTIONS=detect_leaks=0")
