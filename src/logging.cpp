#include "logging.h"

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <cstdlib>
#include <vector>

namespace cinepi {

static std::vector<spdlog::sink_ptr> s_sinks;

void initLogging()
{
    auto consoleSink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
    s_sinks.push_back(consoleSink);

    const char *logFile = std::getenv("CINEPI_LOG_FILE");
    if (logFile && logFile[0] != '\0') {
        auto fileSink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(logFile, true);
        s_sinks.push_back(fileSink);
    }

    spdlog::level::level_enum level = spdlog::level::info;
#ifdef CINEPI_DEBUG
    level = spdlog::level::debug;
#endif

    const char *envLevel = std::getenv("CINEPI_LOG_LEVEL");
    if (envLevel && envLevel[0] != '\0')
        level = spdlog::level::from_str(envLevel);

    spdlog::set_level(level);
    spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%n] [%^%l%$] %v");

    auto defaultLogger = std::make_shared<spdlog::logger>("cinepi", s_sinks.begin(), s_sinks.end());
    defaultLogger->set_level(level);
    spdlog::set_default_logger(defaultLogger);
}

std::shared_ptr<spdlog::logger> getLogger(const std::string &name)
{
    auto existing = spdlog::get(name);
    if (existing)
        return existing;

    auto logger = std::make_shared<spdlog::logger>(name, s_sinks.begin(), s_sinks.end());
    logger->set_level(spdlog::get_level());
    spdlog::register_logger(logger);
    return logger;
}

} // namespace cinepi
