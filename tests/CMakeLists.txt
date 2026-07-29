cmake_minimum_required(VERSION 3.16)

project(easytouch_tests LANGUAGES CXX)

# 单元测试工程。独立于主程序构建，只编译与平台无关的模块，
# 因此可以在 Windows / Linux / macOS 上运行（主程序仅支持 Windows）。

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Qml Test)

enable_testing()

set(EASYTOUCH_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/..)

# 被测模块（与平台无关，可跨平台编译）
set(SUT_SOURCES
    ${EASYTOUCH_ROOT}/functions/configfilemanager.cpp
    ${EASYTOUCH_ROOT}/functions/configfilemanager.h
    ${EASYTOUCH_ROOT}/functions/filehelper.cpp
    ${EASYTOUCH_ROOT}/functions/filehelper.h
)

function(easytouch_add_test test_name test_source)
    qt_add_executable(${test_name} ${test_source} ${SUT_SOURCES})
    target_include_directories(${test_name} PRIVATE ${EASYTOUCH_ROOT})
    target_link_libraries(${test_name} PRIVATE
        Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Qml Qt6::Test)
    add_test(NAME ${test_name} COMMAND ${test_name})
endfunction()

easytouch_add_test(tst_configfilemanager tst_configfilemanager.cpp)
easytouch_add_test(tst_filehelper tst_filehelper.cpp)
