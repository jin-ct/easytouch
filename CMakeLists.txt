cmake_minimum_required(VERSION 3.16)

set(CMAKE_EXE_LINKER_FLAGS "-static -s")

add_library(WMF::WMF INTERFACE IMPORTED)

project(easytouch VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Concurrent)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
find_package(Qt6 REQUIRED COMPONENTS Network)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appeasytouch
    main.cpp res.qrc app.rc
)

qt_add_qml_module(appeasytouch
    URI easytouch
    VERSION 1.0
    RESOURCES res.qrc app.rc
    SOURCES functions/fullscreenwatcher.h functions/fullscreenwatcher.cpp
    SOURCES functions/notificationhelper.h functions/notificationhelper.cpp
    SOURCES functions/whiteboarditem.h functions/whiteboarditem.cpp
    SOURCES functions/functions.cpp functions/functions.h
    SOURCES functions/updatehelper.h functions/updatehelper.cpp
    SOURCES QtLogger.cpp QtLogger.h
    SOURCES functions/filehelper.h functions/filehelper.cpp
    SOURCES functions/wechathelper.h functions/wechathelper.cpp
    SOURCES functions/windowfocushelper.h functions/windowfocushelper.cpp
    SOURCES functions/screenmovement.h functions/screenmovement.cpp
    QML_FILES Main.qml
    QML_FILES views/SettingsPage.qml
    QML_FILES views/Whileboard.qml
    QML_FILES views/RandomGenerator.qml
    QML_FILES components/ToolWindowContent.qml
    QML_FILES components/WindowTitleBar.qml
    QML_FILES components/Popup/VolumePopup.qml
    QML_FILES components/Popup/PopupWindow.qml
    QML_FILES components/Popup/PenPopup.qml
    QML_FILES components/Popup/EraserPopup.qml
    QML_FILES components/Popup/ScrMoveSaveList.qml
    QML_FILES components/Card/SettingsButtonCard.qml
    QML_FILES components/Card/SettingsCard.qml
    QML_FILES components/Card/SettingsComboCard.qml
    QML_FILES components/Card/SettingsSliderCard.qml
    QML_FILES components/Card/SettingsSwitchCard.qml
    QML_FILES components/Card/SettingsTextFieldCard.qml
    QML_FILES components/Dialog/ScrMoveSaveDialog.qml
    QML_FILES components/Dialog/MessageBoxDialog.qml
    RESOURCES qtquickcontrols2.conf
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
)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)
target_link_libraries(appeasytouch PRIVATE Qt6::Concurrent)
target_link_libraries(appeasytouch PRIVATE Qt6::Network)
target_link_libraries(appeasytouch PRIVATE dwmapi)
target_link_libraries(appeasytouch PRIVATE Qt6::Widgets)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)
target_link_libraries(appeasytouch PRIVATE Qt6::Core)

include(GNUInstallDirs)
install(TARGETS appeasytouch
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
