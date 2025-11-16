/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  AbilityPluginBinding,
  BinaryMessenger,
} from '@ohos/flutter_ohos';
import { UIAbility } from '@kit.AbilityKit';
import { FilePickerDelegate } from './FilePlckerDelegate'
import List from '@ohos.util.List'
import { FileUtils } from './FileUtils'

/** FilePickerPlugin **/
const CHANNEL: string = "miguelruivo.flutter.plugins.filepicker";
const TAG: string = "FilePicker"
const EVENT_CHANNEL: string = "miguelruivo.flutter.plugins.filepickerevent"

export default class FilePickerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private pluginBinding: FlutterPluginBinding | null = null;
  private ability: UIAbility | null = null;
  private fileType: string | null = null;
  private isMultipleSelection: boolean = false;
  private withData: boolean = false;
  private delegate: FilePickerDelegate | null = null;
  private allowedExtensions: Array<string> = new Array<string>();

  constructor() {
  }

  getUniqueClassName(): string {
    return "FilePickerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.abilityBinding = null
    this.pluginBinding = binding
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityBinding = binding;
    this.setup(this.pluginBinding?.getBinaryMessenger() as BinaryMessenger, binding.getAbility(), binding);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (this.ability == null) {
      result.error("no_activity", "file picker plugin requires a foreground activity", null);
      return;
    }
    let args: Map<string, Object> = call.args;
    this.fileType = call.method;
    if (call.method != null && call.method === ("clear")) {
      result.success(FileUtils.clearCache(this.ability));
      return;
    }
    if (call.method != null && call.method === ("save")) {
      let fileName: string = args.get("fileName") as string;
      let type: string = args.get("fileType") as string;
      let initialDirectory: string = args.get("initialDirectory") as string;
      let allowedExtensionsArgs: List<string> = args.get("allowedExtensions") as List<string>;
      let bytes: Uint8Array | null = args.get("bytes") as Uint8Array;
      let extensionsForSave: Array<string> = new Array();
      if (allowedExtensionsArgs != null && allowedExtensionsArgs.length != 0) {
        allowedExtensionsArgs.forEach((item) => {
          if (item != null) {
            if (item.startsWith(".")) {
              extensionsForSave.push(item);
            } else {
              extensionsForSave.push(`.${item}`);
            }
          }
        })
      }
      this.delegate?.saveFile([fileName], type, initialDirectory, extensionsForSave, bytes, result)
      return;
    }
    if (call.method != null && call.method === ("write")) {
      let uri: string = args.get("uri") as string;
      let bytes: Uint8Array = args.get("bytes") as Uint8Array;
      this.delegate?.writeFile(uri, bytes, result)
      return;
    }
    if (this.fileType == null) {
      result.notImplemented();
    } else if (this.fileType) {
      this.isMultipleSelection = args.get("allowMultipleSelection") as boolean;
      let allowedExtensions: List<string> = args.get("allowedExtensions") as List<string>;
      this.withData = args.get("withData") as boolean;
      if (allowedExtensions != null && allowedExtensions.length != 0) {
        allowedExtensions.forEach((item) => {
          if (this.allowedExtensions) {
            this.allowedExtensions.push(`.${item}`);
          }
        })
      }
    }
    if (this.delegate) {
      this.delegate.startFileExplorer(this.fileType, this.isMultipleSelection, this.withData,
        this.allowedExtensions as string[], result);
      this.allowedExtensions = new Array<string>();
    }
  }

  static generateUniqueRequestCode(): number {
    const timestamp = Date.now(); // 获取当前时间戳
    const randomOffset = Math.floor(Math.random() * 1000); // 生成一个0到999之间的随机数
    return (timestamp + randomOffset) & 0xFFFF; // 结合时间戳和随机数，并确保结果是一个16位的整数
  }

  setup(messenger: BinaryMessenger, ability: UIAbility, activityBinding: AbilityPluginBinding) {
    this.ability = ability;
    this.delegate = new FilePickerDelegate(ability);
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
  }
}
