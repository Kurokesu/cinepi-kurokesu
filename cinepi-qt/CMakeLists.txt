cmake_minimum_required(VERSION 3.16)
project(cinepi-qt VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Find Qt5 packages
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Network
    Gui
)

# Find hiredis
find_package(PkgConfig REQUIRED)
pkg_check_modules(HIREDIS REQUIRED hiredis)

# Find EGL/GL/DRM for DMA-BUF zero-copy preview
pkg_check_modules(EGL REQUIRED egl)
pkg_check_modules(GLES2 REQUIRED glesv2)
pkg_check_modules(DRM REQUIRED libdrm)

# Source files
set(SOURCES
    src/main.cpp
    src/redisbridge.cpp
    src/mjpegclient.cpp
    src/frameprovider.cpp
    src/configmanager.cpp
    src/dmabufpreview.cpp
)

# Headers (for MOC)
set(HEADERS
    src/redisbridge.h
    src/mjpegclient.h
    src/frameprovider.h
    src/configmanager.h
    src/dmabufpreview.h
)

# QML resource file
qt5_add_resources(QRC_SOURCES qml.qrc)

# Executable
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
    ${QRC_SOURCES}
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${HIREDIS_INCLUDE_DIRS}
    ${EGL_INCLUDE_DIRS}
    ${GLES2_INCLUDE_DIRS}
    ${DRM_INCLUDE_DIRS}
    src
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Network
    Qt5::Gui
    ${HIREDIS_LIBRARIES}
    ${EGL_LIBRARIES}
    ${GLES2_LIBRARIES}
    ${DRM_LIBRARIES}
)

# Install
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
