# Needed to build examples

add_custom_target(QUICKFIX_HEADERS_COPY ALL 
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Application.h ${PROJECT_SOURCE_DIR}/include/quickfix/Application.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/config-all.h ${PROJECT_SOURCE_DIR}/include/quickfix/config-all.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/DataDictionary.h ${PROJECT_SOURCE_DIR}/include/quickfix/DataDictionary.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/DataDictionaryProvider.h ${PROJECT_SOURCE_DIR}/include/quickfix/DataDictionaryProvider.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Dictionary.h ${PROJECT_SOURCE_DIR}/include/quickfix/Dictionary.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/DOMDocument.h ${PROJECT_SOURCE_DIR}/include/quickfix/DOMDocument.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Event.h ${PROJECT_SOURCE_DIR}/include/quickfix/Event.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Except.h ${PROJECT_SOURCE_DIR}/include/quickfix/Except.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Exceptions.h ${PROJECT_SOURCE_DIR}/include/quickfix/Exceptions.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Field.h ${PROJECT_SOURCE_DIR}/include/quickfix/Field.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FieldConvertors.h ${PROJECT_SOURCE_DIR}/include/quickfix/FieldConvertors.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FieldMap.h ${PROJECT_SOURCE_DIR}/include/quickfix/FieldMap.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FieldNumbers.h ${PROJECT_SOURCE_DIR}/include/quickfix/FieldNumbers.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Fields.h ${PROJECT_SOURCE_DIR}/include/quickfix/Fields.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FieldTypes.h ${PROJECT_SOURCE_DIR}/include/quickfix/FieldTypes.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FileLog.h ${PROJECT_SOURCE_DIR}/include/quickfix/FileLog.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FileStore.h ${PROJECT_SOURCE_DIR}/include/quickfix/FileStore.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FixFieldNumbers.h ${PROJECT_SOURCE_DIR}/include/quickfix/FixFieldNumbers.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FixFields.h ${PROJECT_SOURCE_DIR}/include/quickfix/FixFields.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FixCommonFields.h ${PROJECT_SOURCE_DIR}/include/quickfix/FixCommonFields.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/FixValues.h ${PROJECT_SOURCE_DIR}/include/quickfix/FixValues.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Group.h ${PROJECT_SOURCE_DIR}/include/quickfix/Group.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/HostDetailsProvider.h ${PROJECT_SOURCE_DIR}/include/quickfix/HostDetailsProvider.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/index.h ${PROJECT_SOURCE_DIR}/include/quickfix/index.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Initiator.h ${PROJECT_SOURCE_DIR}/include/quickfix/Initiator.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Log.h ${PROJECT_SOURCE_DIR}/include/quickfix/Log.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Message.h ${PROJECT_SOURCE_DIR}/include/quickfix/Message.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/MessageCracker.h ${PROJECT_SOURCE_DIR}/include/quickfix/MessageCracker.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/MessageSorters.h ${PROJECT_SOURCE_DIR}/include/quickfix/MessageSorters.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/MessageStore.h ${PROJECT_SOURCE_DIR}/include/quickfix/MessageStore.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Mutex.h ${PROJECT_SOURCE_DIR}/include/quickfix/Mutex.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/NullStore.h ${PROJECT_SOURCE_DIR}/include/quickfix/NullStore.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Parser.h ${PROJECT_SOURCE_DIR}/include/quickfix/Parser.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/PUGIXML_DOMDocument.h ${PROJECT_SOURCE_DIR}/include/quickfix/PUGIXML_DOMDocument.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Queue.h ${PROJECT_SOURCE_DIR}/include/quickfix/Queue.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Responder.h ${PROJECT_SOURCE_DIR}/include/quickfix/Responder.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Session.h ${PROJECT_SOURCE_DIR}/include/quickfix/Session.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SessionFactory.h ${PROJECT_SOURCE_DIR}/include/quickfix/SessionFactory.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SessionID.h ${PROJECT_SOURCE_DIR}/include/quickfix/SessionID.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SessionSettings.h ${PROJECT_SOURCE_DIR}/include/quickfix/SessionSettings.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SessionState.h ${PROJECT_SOURCE_DIR}/include/quickfix/SessionState.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Settings.h ${PROJECT_SOURCE_DIR}/include/quickfix/Settings.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SharedArray.h ${PROJECT_SOURCE_DIR}/include/quickfix/SharedArray.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SocketMonitor.h ${PROJECT_SOURCE_DIR}/include/quickfix/SocketMonitor.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/SocketMonitor_UNIX.h ${PROJECT_SOURCE_DIR}/include/quickfix/SocketMonitor_UNIX.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/stdafx.h ${PROJECT_SOURCE_DIR}/include/quickfix/stdafx.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/TimeRange.h ${PROJECT_SOURCE_DIR}/include/quickfix/TimeRange.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Utility.h ${PROJECT_SOURCE_DIR}/include/quickfix/Utility.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/UtilitySSL.h ${PROJECT_SOURCE_DIR}/include/quickfix/UtilitySSL.h
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Values.h ${PROJECT_SOURCE_DIR}/include/quickfix/Values.h

COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix40
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix40 ${PROJECT_SOURCE_DIR}/include/quickfix/fix40/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix41
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix41 ${PROJECT_SOURCE_DIR}/include/quickfix/fix41/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix42
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix42 ${PROJECT_SOURCE_DIR}/include/quickfix/fix42/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix43
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix43 ${PROJECT_SOURCE_DIR}/include/quickfix/fix43/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix44
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix44 ${PROJECT_SOURCE_DIR}/include/quickfix/fix44/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix50
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix50 ${PROJECT_SOURCE_DIR}/include/quickfix/fix50/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix50sp1
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix50sp1 ${PROJECT_SOURCE_DIR}/include/quickfix/fix50sp1/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fix50sp2
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fix50sp2 ${PROJECT_SOURCE_DIR}/include/quickfix/fix50sp2/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/fixt11
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fixt11 ${PROJECT_SOURCE_DIR}/include/quickfix/fixt11/
COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_SOURCE_DIR}/include/quickfix/wx
COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/src/C++/fixt11 ${PROJECT_SOURCE_DIR}/include/quickfix/wx/
)

if (EXISTS ${PROJECT_SOURCE_DIR}/src/C++/Allocator.h)
add_custom_target(QUICKFIX_ALLOCATOR_HEADERS_COPY ALL
COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PROJECT_SOURCE_DIR}/src/C++/Allocator.h ${PROJECT_SOURCE_DIR}/include/quickfix/Allocator.h
)
endif()