#include "include/flutter_qjs/flutter_qjs_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_qjs_plugin.h"

void FlutterQjsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_qjs::FlutterQjsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
