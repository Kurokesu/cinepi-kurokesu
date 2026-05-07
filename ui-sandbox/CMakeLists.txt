# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, UAB Kurokesu

cmake_minimum_required(VERSION 3.21)
project(ui-sandbox LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(STUDIO_APP_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../CinePiUi/Dependencies/Components/imports/application")

qt_add_executable(ui-sandbox
    main.cpp
    ${STUDIO_APP_DIR}/quickstudioapplication.cpp
    ${STUDIO_APP_DIR}/quickstudioapplication.h
)

target_include_directories(ui-sandbox PRIVATE ${STUDIO_APP_DIR})
target_link_libraries(ui-sandbox PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
