cmake_minimum_required(VERSION 3.16)
project(cinepi VERSION 0.2.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Qt6 ──────────────────────────────────────────────────────────────────────
find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Network Gui)

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
pkg_check_modules(JSONCPP REQUIRED jsoncpp)
pkg_check_modules(JPEG REQUIRED libjpeg)
pkg_check_modules(TIFF REQUIRED libtiff-4)
pkg_check_modules(ALSA REQUIRED alsa)
pkg_check_modules(UDEV REQUIRED libudev)

find_package(Boost REQUIRED COMPONENTS program_options)
find_package(Threads REQUIRED)

# ── Sources ──────────────────────────────────────────────────────────────────

set(CAMERA_SOURCES
    src/camera/cinepi_controller.cpp
    src/camera/cinepi_sound.cpp
    src/camera/cinepi_state.cpp
    src/camera/dng_encoder.cpp
    src/camera/utils.cpp
)

set(UI_SOURCES
    src/ui/CameraController.cpp
    src/ui/DmaBufPreview.cpp
    src/ui/FrameProvider.cpp
    src/ui/ConfigManager.cpp
)

set(MAIN_SOURCES
    src/main.cpp
    src/CameraWorker.cpp
)

set(HEADERS
    src/CameraWorker.h
    src/ui/CameraController.h
    src/ui/DmaBufPreview.h
    src/ui/FrameProvider.h
    src/ui/ConfigManager.h
)

qt_add_resources(QRC_SOURCES qml.qrc)

# ── Executable ───────────────────────────────────────────────────────────────

add_executable(${PROJECT_NAME}
    ${CAMERA_SOURCES}
    ${UI_SOURCES}
    ${MAIN_SOURCES}
    ${HEADERS}
    ${QRC_SOURCES}
)

target_include_directories(${PROJECT_NAME} PRIVATE
    src
    src/camera
    ${LIBCAMERA_INCLUDE_DIRS}
    ${RPICAM_APP_INCLUDE_DIRS}
    /usr/include/rpicam-apps
    ${EGL_INCLUDE_DIRS}
    ${GLES2_INCLUDE_DIRS}
    ${DRM_INCLUDE_DIRS}
    ${SPDLOG_INCLUDE_DIRS}
    ${JSONCPP_INCLUDE_DIRS}
    ${JPEG_INCLUDE_DIRS}
    ${TIFF_INCLUDE_DIRS}
    ${ALSA_INCLUDE_DIRS}
    ${UDEV_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Gui
    ${LIBCAMERA_LIBRARIES}
    ${RPICAM_APP_LIBRARIES}
    ${EGL_LIBRARIES}
    ${GLES2_LIBRARIES}
    ${DRM_LIBRARIES}
    ${SPDLOG_LIBRARIES}
    ${JSONCPP_LIBRARIES}
    ${JPEG_LIBRARIES}
    ${TIFF_LIBRARIES}
    ${ALSA_LIBRARIES}
    ${UDEV_LIBRARIES}
    Boost::program_options
    Threads::Threads
)

# Prevent Qt's emit/signals/slots macros from clashing with libcamera
target_compile_definitions(${PROJECT_NAME} PRIVATE QT_NO_KEYWORDS)

install(TARGETS ${PROJECT_NAME} DESTINATION bin)
