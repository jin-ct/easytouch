cmake_minimum_required(VERSION 3.16)

add_library(WMF::WMF INTERFACE IMPORTED)

project(easytouch VERSION 0.1 LANGUAGES CXX)

# 获取版本号
execute_process(
    COMMAND git describe --tags --abbrev=0
    OUTPUT_VARIABLE GIT_TAG
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(NOT GIT_TAG)
    set(GIT_TAG "1.0.0")
endif()

string(REGEX REPLACE "^v" "" GIT_TAG ${GIT_TAG})

string(REPLACE "-beta" "" GIT_TAG ${GIT_TAG})

string(REPLACE "." ";" VERSION_LIST ${GIT_TAG})
list(GET VERSION_LIST 0 MAJOR)
list(GET VERSION_LIST 1 MINOR)
list(GET VERSION_LIST 2 PATCH)

set(APP_VERSION_STR ${GIT_TAG})
set(APP_VERSION_NUM "${MAJOR},${MINOR},${PATCH},0")

configure_file(
    ${CMAKE_SOURCE_DIR}/app.rc.in
    ${CMAKE_BINARY_DIR}/app.rc
)

set(CMAKE_EXE_LINKER_FLAGS "-static -s")

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTORCC ON)

set(FLUENTUI_BUILD_EXAMPLES OFF)
set(FLUENTUI_BUILD_STATIC_LIB ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Concurrent)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
find_package(Qt6 REQUIRED COMPONENTS Network)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appeasytouch
    main.cpp res.qrc ${CMAKE_BINARY_DIR}/app.rc
)

qt_add_qml_module(appeasytouch
    URI easytouch
    VERSION 1.0
    RESOURCES res.qrc
    SOURCES src/GlobalManager.h src/GlobalManager.cpp
    SOURCES src/ConfigManager.h src/ConfigManager.cpp
    SOURCES src/QtLogger.h src/QtLogger.cpp
    SOURCES src/app_dmp.h
    SOURCES stdafx.h
    SOURCES src/components/Functions.h src/components/Functions.cpp
    SOURCES src/components/ConfigFileManager.h src/components/ConfigFileManager.cpp
    SOURCES src/components/UpdateHelper.h src/components/UpdateHelper.cpp
    SOURCES src/components/FullScreenWatcher.h src/components/FullScreenWatcher.cpp
    SOURCES src/components/NotificationHelper.h src/components/NotificationHelper.cpp
    SOURCES src/components/FileHelper.h src/components/FileHelper.cpp
    SOURCES src/components/MouseHook.h src/components/MouseHook.cpp
    SOURCES src/components/QmlImageProvider.h src/components/QmlImageProvider.cpp
    SOURCES src/components/CircularReveal.h src/components/CircularReveal.cpp
    SOURCES src/components/FileWatcher.h src/components/FileWatcher.cpp
    SOURCES src/components/WindowMonitor.h src/components/WindowMonitor.cpp
    SOURCES src/functions/WhiteBoardItem.h src/functions/WhiteBoardItem.cpp
    SOURCES src/functions/WeChatHelper.h src/functions/WeChatHelper.cpp
    SOURCES src/functions/WindowFocusHelper.h src/functions/WindowFocusHelper.cpp
    SOURCES src/functions/ScreenMovement.h src/functions/ScreenMovement.cpp
    SOURCES src/functions/LaunchingHelper.h src/functions/LaunchingHelper.cpp
    QML_FILES Main.qml
    QML_FILES qml/connections/Connect_Notification.qml
    QML_FILES qml/connections/Connect_UpdateHelper.qml
    QML_FILES qml/connections/Connect_FocusHelper.qml
    QML_FILES qml/connections/Connect_LaunchingHelper.qml
    QML_FILES qml/views/ToolWindows.qml
    QML_FILES qml/views/SettingsPage.qml
    QML_FILES qml/views/Whileboard.qml
    QML_FILES qml/views/RandomGenerator.qml
    QML_FILES qml/views/SplashWindow.qml
    QML_FILES qml/views/HotloadWindow.qml
    QML_FILES qml/views/CrashWindow.qml
    QML_FILES qml/components/ToolWindowContent.qml
    QML_FILES qml/components/WindowTitleBar.qml
    QML_FILES qml/components/Popup/VolumePopup.qml
    QML_FILES qml/components/Popup/PopupWindow.qml
    QML_FILES qml/components/Popup/PenPopup.qml
    QML_FILES qml/components/Popup/EraserPopup.qml
    QML_FILES qml/components/Popup/ScrMoveSaveList.qml
    QML_FILES qml/components/Popup/SystemTrayMenu.qml
    QML_FILES qml/components/Dialog/ScrMoveSaveDialog.qml
    QML_FILES qml/components/Dialog/MessageBoxDialog.qml
    QML_FILES qml/components/Control/SettingItem.qml
    QML_FILES qml/components/Control/SettingItemExpander.qml
    QML_FILES qml/components/Control/ExpandedItem.qml
    QML_FILES qml/components/Control/MDropDownButton.qml
    QML_FILES qml/components/Control/ShowMoreItem.qml
    QML_FILES qml/components/SettingPages/Basic.qml
    QML_FILES qml/components/SettingPages/About.qml
    QML_FILES qml/components/SettingPages/ToolBar.qml
    QML_FILES qml/components/SettingPages/Functions.qml
    QML_FILES qml/components/SettingPages/Advanced.qml
    QML_FILES qml/components/SettingPages/TouchPromote.qml
    QML_FILES qml/components/SettingPages/Components/WindowStyleSelectItem.qml
    QML_FILES qml/components/SettingPages/Components/TouchPromoteRuleList.qml
    QML_FILES qml/components/SettingPages/Components/TouchPromoteRuleEditor.qml
    RESOURCES qtquickcontrols2.conf
    RESOURCES app.rc.in
    QML_FILES Splash.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appeasytouch PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appeasytouch
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appeasytouch
    PRIVATE Qt6::Quick
    fluentuiplugin
)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)
target_link_libraries(appeasytouch PRIVATE Qt6::Concurrent)
target_link_libraries(appeasytouch PRIVATE Qt6::Network)
target_link_libraries(appeasytouch PRIVATE dwmapi)
target_link_libraries(appeasytouch PRIVATE Qt6::Widgets)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)

if(CMAKE_INSTALL_BINDIR STREQUAL ".")
    set(_INSTALL_DEST "")
else()
    set(_INSTALL_DEST ${CMAKE_INSTALL_BINDIR})
endif()

include(GNUInstallDirs)
install(TARGETS appeasytouch
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

add_subdirectory(3rdparty/FluentUI)

target_include_directories(appeasytouch PRIVATE
    3rdparty/FluentUI/src
)

#Release也支持日志打印代码位置
target_compile_definitions(appeasytouch
    PRIVATE
    QT_MESSAGELOGCONTEXT
)
