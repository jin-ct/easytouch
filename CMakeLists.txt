cmake_minimum_required(VERSION 3.16)

project(easytouch VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appeasytouch
    main.cpp res.qrc
)

qt_add_qml_module(appeasytouch
    URI easytouch
    VERSION 1.0
    QML_FILES
        Main.qml
        QML_FILES components/FoldBtn.qml components/FunBtn.qml components/MoveBtn.qml components/WindowContent.qml
        SOURCES functions/functions.cpp functions/functions.h
        RESOURCES res.qrc
        QML_FILES components/DialogWindow.qml
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

include(GNUInstallDirs)
install(TARGETS appeasytouch
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
