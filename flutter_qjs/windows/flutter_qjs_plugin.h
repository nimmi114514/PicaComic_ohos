#ifndef FLUTTER_PLUGIN_FLUTTER_QJS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_QJS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_qjs {

class FlutterQjsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterQjsPlugin();

  virtual ~FlutterQjsPlugin();

  // Disallow copy and assign.
  FlutterQjsPlugin(const FlutterQjsPlugin&) = delete;
  FlutterQjsPlugin& operator=(const FlutterQjsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_qjs

#endif  // FLUTTER_PLUGIN_FLUTTER_QJS_PLUGIN_H_
