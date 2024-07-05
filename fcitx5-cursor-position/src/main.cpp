#include <chrono>
#include <fcitx/addonfactory.h>
#include <fcitx/addonmanager.h>
#include <fcitx/instance.h>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <thread>
#include <unistd.h>

class PositionReporter : public fcitx::AddonInstance {
public:
  PositionReporter(fcitx::Instance *instance) {
    this->work_thread = new std::thread([instance]() {
      if (access("/tmp/pos-request", F_OK) == -1) {
        int p = mkfifo("/tmp/pos-request", 0777);
      }
      if (access("/tmp/pos-response", F_OK) == -1) {
        mkfifo("/tmp/pos-response", 0777);
      }
      std::ifstream input = std::ifstream();
      while (true) {
        input.open("/tmp/pos-request");
        std::string line;
        std::getline(input, line);
        auto ctx = instance->lastFocusedInputContext();
        if (ctx == nullptr) {
          ctx = instance->mostRecentInputContext();
        }
        std::ofstream out = std::ofstream("/tmp/pos-response");
        if (ctx != nullptr) {
          auto rect = ctx->cursorRect();
          out << rect.left() << "," << rect.top() << "\n";
        } else {
          out << "unknow\n";
        }
        out.close();
        input.close();
      }
    });
  }
  ~PositionReporter() { delete this->work_thread; }

private:
  std::thread *work_thread;
};

class PositionReporterAddonFactory : public fcitx::AddonFactory {
  fcitx::AddonInstance *create(fcitx::AddonManager *manager) override {
    return new PositionReporter(manager->instance());
  }
};

FCITX_ADDON_FACTORY(PositionReporterAddonFactory);
