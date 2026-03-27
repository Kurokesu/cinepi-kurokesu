cmake_minimum_required(VERSION 3.16)
project(cinepi VERSION 0.2.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type (Debug or Release)" FORCE)
endif()

# ── Qt6 ──────────────────────────────────────────────────────────────────────
set(CMAKE_FIND_PACKAGE_TARGETS_GLOBAL TRUE)
set(XKB_FIND_QUIETLY TRUE)
find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick QuickControls2 Network Gui)

# ── QDS UI modules ───────────────────────────────────────────────────────────
# CinePiUi (Constants singleton) and CinePiUiContent (all UI components).
# These create static QML module targets that we link into the executable.

add_subdirectory(CinePiUi/CinePiUi)
add_subdirectory(CinePiUi/CinePiUiContent)
target_link_libraries(CinePiUiContent PRIVATE CinePiUi)

# StudioApplication compat shim -- provides the QtQuick.Studio.Application
# QML module that Constants.qml imports. Built as a separate static lib so
# it is NOT compiled with QT_NO_KEYWORDS (which would break the Qt signals
# keyword in the upstream header).
add_library(studio_app_compat STATIC
    CinePiUi/Dependencies/Components/imports/application/quickstudioapplication.cpp
    app/studio_app_compat.cpp
)
target_include_directories(studio_app_compat PRIVATE
    CinePiUi/Dependencies/Components/imports/application
)
target_link_libraries(studio_app_compat PRIVATE Qt6::Core Qt6::Qml Qt6::Gui)
set_target_properties(studio_app_compat PROPERTIES AUTOMOC ON)

# ── System libraries via pkg-config ──────────────────────────────────────────
find_package(PkgConfig REQUIRED)

# Camera / rpicam-apps
pkg_check_modules(LIBCAMERA REQUIRED libcamera)
pkg_check_modules(RPICAM_APP REQUIRED rpicam_app)

# Graphics
pkg_check_modules(EGL REQUIRED egl)
pkg_check_modules(GLES2 REQUIRED glesv2)
pkg_check_modules(DRM REQUIRED libdrm)

# Camera backend dependencies
pkg_check_modules(SPDLOG REQUIRED spdlog)
pkg_check_modules(JPEG REQUIRED libjpeg)
pkg_check_modules(TIFF REQUIRED libtiff-4)
pkg_check_modules(ALSA REQUIRED alsa)
pkg_check_modules(UDEV REQUIRED libudev)

find_package(Boost REQUIRED COMPONENTS program_options)
find_package(Threads REQUIRED)

# ── Sources ──────────────────────────────────────────────────────────────────

set(CAMERA_SOURCES
    app/camera/cinepi_controller.cpp
    app/camera/cinepi_sound.cpp
    app/camera/dng_encoder.cpp
    app/camera/utils.cpp
)

set(UI_SOURCES
    app/ui/CameraController.cpp
    app/ui/DmaBufViewfinder.cpp
    app/ui/FrameProvider.cpp
    app/ui/ConfigManager.cpp
)

set(MAIN_SOURCES
    app/main.cpp
    app/CameraWorker.cpp
    app/logging.cpp
)

set(HEADERS
    app/CameraWorker.h
    app/logging.h
    app/studio_app_compat.h
    app/ui/CameraController.h
    app/ui/DmaBufViewfinder.h
    app/ui/FrameProvider.h
    app/ui/ConfigManager.h
)

qt_add_resources(QRC_SOURCES app.qrc)

# ── Executable ───────────────────────────────────────────────────────────────

add_executable(${PROJECT_NAME}
    ${CAMERA_SOURCES}
    ${UI_SOURCES}
    ${MAIN_SOURCES}
    ${HEADERS}
    ${QRC_SOURCES}
)

target_include_directories(${PROJECT_NAME} PRIVATE
    app
    app/camera
    ${LIBCAMERA_INCLUDE_DIRS}
    ${RPICAM_APP_INCLUDE_DIRS}
    /usr/include/rpicam-apps
    ${EGL_INCLUDE_DIRS}
    ${GLES2_INCLUDE_DIRS}
    ${DRM_INCLUDE_DIRS}
    ${SPDLOG_INCLUDE_DIRS}
    ${JPEG_INCLUDE_DIRS}
    ${TIFF_INCLUDE_DIRS}
    ${ALSA_INCLUDE_DIRS}
    ${UDEV_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Gui
    CinePiUi
    CinePiUiplugin
    CinePiUiContent
    CinePiUiContentplugin
    studio_app_compat
    ${LIBCAMERA_LIBRARIES}
    ${RPICAM_APP_LIBRARIES}
    ${EGL_LIBRARIES}
    ${GLES2_LIBRARIES}
    ${DRM_LIBRARIES}
    ${SPDLOG_LIBRARIES}
    ${JPEG_LIBRARIES}
    ${TIFF_LIBRARIES}
    ${ALSA_LIBRARIES}
    ${UDEV_LIBRARIES}
    Boost::program_options
    Threads::Threads
)

# Prevent Qt's emit/signals/slots macros from clashing with libcamera
target_compile_definitions(${PROJECT_NAME} PRIVATE QT_NO_KEYWORDS)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    PROJECT_VERSION="${PROJECT_VERSION}"
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        CINEPI_DEBUG
        SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_DEBUG
    )
    message(STATUS "CinePI: Debug build (CINEPI_DEBUG, log level >= debug)")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_INFO
    )
    message(STATUS "CinePI: Release build (log level >= info)")
endif()

install(TARGETS ${PROJECT_NAME} DESTINATION bin)
