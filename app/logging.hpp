/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * logging.hpp - application logging setup.
 */

#pragma once

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <string>
#include <memory>

namespace cinepi {

/* Call once at startup, before creating any loggers.
 * Reads CINEPI_LOG_LEVEL and CINEPI_LOG_FILE env vars. */
void initLogging();

/* Get or create a named logger that shares the global sinks. */
std::shared_ptr<spdlog::logger> getLogger(const std::string &name);

} // namespace cinepi
