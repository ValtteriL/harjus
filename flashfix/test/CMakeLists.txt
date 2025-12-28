add_definitions(-DCATCH_AMALGAMATED_CUSTOM_MAIN)

set (ut_SOURCES
  catch_amalgamated.cpp
  ut.cpp
  DataDictionaryTestCase.cpp
  DataDictionaryTestCase.cpp
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
  
add_executable(ut ${ut_SOURCES})
  
target_include_directories(ut 
  PRIVATE include
)

target_link_libraries(ut
  PRIVATE
    flashfix_objs
)
