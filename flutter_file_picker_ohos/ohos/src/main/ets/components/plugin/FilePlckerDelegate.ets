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
import { util } from '@kit.ArkTS';
import FilePickerPlugin from "./FilePickerPlugin"
import { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { pasteboard } from '@kit.BasicServicesKit';
import {
  Ability,
  abilityAccessCtrl,
  bundleManager,
  common,
  PermissionRequestResult,
  Permissions,
  StartOptions,
  UIAbility,
  Want
} from '@kit.AbilityKit';
import decodeURIComponent from '@ohos.util';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { EventChannel, Log, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { FileInfo } from './FileInfo'
import { FileInfoBuilder } from './FileInfo'
import { FileUtils } from './FileUtils'
import List from '@ohos.util.List'
import { picker, WriteOptions } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';

const timestamp = Date.now();
const TAG: string = "FilePickerDelegate";

export class FilePickerDelegate {
  private permissionManager: PermissionManager | null = null;
  private eventSink: EventSink | null = null;
  private pendingResult: MethodResult | null = null;
  private isMultipleSelection: boolean = false;
  private loadDataToMemory: boolean = false;
  private type: string = "";
  private allowedExtensions: string[] = new Array;
  private ability: UIAbility | null = null;
  private context: common.UIAbilityContext | null = null;
  private audioSelectedUris: Array<string> = new Array
  private savaFilePath: Array<string> = new Array();

  constructor(uiAbility: UIAbility) {
    this.ability = uiAbility;
  }

  async startFileExplorer(type: string, isMultipleSelection: boolean, withData: boolean,
    allowedExtensions: string[] | null | undefined,
    result: MethodResult) {
    if (!this.setPendingMethodCallAndResult(result)) {
      this.finishWithAlreadyActiveError(result as MethodResult);
      return;
    }
    this.type = type;
    this.isMultipleSelection = isMultipleSelection;
    this.loadDataToMemory = withData;
    if (allowedExtensions) {
      this.allowedExtensions = allowedExtensions;
    }
    this.startFileExplorerA();
  }

  async startFileExplorerA() {
    let want: Want | null = null;
    switch (this.type) {
      case "image": {
        let commonContext = this.ability?.context as common.UIAbilityContext;
        let photoPicker = new picker.PhotoViewPicker(commonContext);
        let photoSelectOptions = new picker.PhotoSelectOptions();
        photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
        photoSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        await photoPicker.select(photoSelectOptions).then((photoSelectResult) => {

          this.savaFilePath = photoSelectResult.photoUris
          if (photoSelectResult == null || photoSelectResult.photoUris.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(photoSelectResult.photoUris)
          } else {
            this.handleSingleResult(photoSelectResult.photoUris[0]);
          }
        }).catch((error: BusinessError) => {
          this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        })
        break;
      }
      case "video": {
        let photoPicker = new picker.PhotoViewPicker();
        let photoSelectOptions = new picker.PhotoSelectOptions();
        photoSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.VIDEO_TYPE;
        photoPicker.select(photoSelectOptions).then((photoSelectResult) => {
          this.savaFilePath = photoSelectResult.photoUris
          if (photoSelectResult == null || photoSelectResult.photoUris.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          let selectedUris: Array<string> = photoSelectResult.photoUris;
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(selectedUris)
          } else {
            this.handleSingleResult(selectedUris[0]);
          }
        }).catch((error: BusinessError) => {
          this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        })
        break;
      }
      case "audio": {
        let context = getContext(this) as common.UIAbilityContext;
        let audioPicker: picker.AudioViewPicker = new picker.AudioViewPicker(context);
        let audioSelectOptions = new picker.AudioSelectOptions();
        audioSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        audioPicker.select(audioSelectOptions).then((audioSelectResult) => {
          this.savaFilePath = audioSelectResult
          if (audioSelectResult == null || audioSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(audioSelectResult);
          } else {
            this.handleSingleResult(audioSelectResult[0]);
          }
        }).catch((error: BusinessError) => {
          this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        })
        break
      }
      case "media": {
        let photoPicker = new photoAccessHelper.PhotoViewPicker();
        let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
        photoSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        photoSelectOptions.MIMEType = this.resolveType(this.type) as photoAccessHelper.PhotoViewMIMETypes;
        photoPicker.select(photoSelectOptions).then((photoSelectResult) => {
          this.savaFilePath = photoSelectResult.photoUris
          let selectedUris: Array<string> = photoSelectResult.photoUris;
          if (selectedUris == null || selectedUris.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(selectedUris)
          } else {
            this.handleSingleResult(selectedUris[0]);
          }
        }).catch((error: BusinessError) => {
          this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        })
        break;
      }
      case "any": {
        let commonContext = this.ability?.context as common.UIAbilityContext;
        let documentPicker = new picker.DocumentViewPicker(commonContext);
        let documentSelectOptions = new picker.DocumentSelectOptions();
        documentSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
          this.savaFilePath = documentSelectResult
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          let anySelectUris: Array<string> = documentSelectResult;
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(anySelectUris)
          } else {
            this.handleSingleResult(anySelectUris[0]);
          }
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
        }).catch((err: BusinessError) => {
          console.error('DocumentViewPicker.select failed with err: ' + JSON.stringify(err));
          this.finishWithError("DocumentViewPicker.select(type=any)", 'DocumentViewPicker.select(type=any) failed with err: ' + JSON.stringify(err));
        });
        break
      }
      case "custom": {
        let commonContext = this.ability?.context as common.UIAbilityContext;
        let documentSelectOptions = new picker.DocumentSelectOptions();
        let documentPicker = new picker.DocumentViewPicker(commonContext);
        documentSelectOptions.maxSelectNumber = this.isMultipleSelection ? 9 : 1;
        documentSelectOptions.fileSuffixFilters = this.allowedExtensions;
        documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
          this.savaFilePath = documentSelectResult;
          let anySelectUris: Array<string> = documentSelectResult;
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(anySelectUris)
          } else {
            this.handleSingleResult(anySelectUris[0]);
          }
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
        }).catch((err: BusinessError) => {
          console.error('DocumentViewPicker.select failed with err: ' + JSON.stringify(err));
          this.finishWithError("DocumentViewPicker.select(type=custom)", 'DocumentViewPicker.select(type=custom) failed with err: ' + JSON.stringify(err));
        });
        break
      }
      case "dir": {
        let context = getContext(this) as common.UIAbilityContext;
        let documentPicker = new picker.DocumentViewPicker(context);
        let documentSelectOptions: picker.DocumentSelectOptions = {
          selectMode: 1
        }
        documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
          let anySelectUris: Array<string> = documentSelectResult;
          if (this.isMultipleSelection) {
            this.handlingMultipleResults(anySelectUris)
          } else {
            this.handleSingleResult(anySelectUris[0]);
          }
          if (documentSelectResult == null || documentSelectResult.length == 0) {
            this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
          }
        }).catch((err: BusinessError) => {
          console.error('DocumentViewPicker.select failed with err: ' + JSON.stringify(err));
          this.finishWithError("DocumentViewPicker.select(type=dir)", 'DocumentViewPicker.select(type=dir) failed with err: ' + JSON.stringify(err));
        });
        break
      }
    }
  }

  async handlingMultipleResults(uris: string[]) {
    let files: List<FileInfo> = new List();
    let count: number = uris.length;
    let currentItem = 0;
    while (currentItem < count) {
      let currentUri: string = uris[currentItem];
      if (this.ability?.context) {
        let file: FileInfo =
          await FileUtils.openFileStream(this.ability?.context, currentUri, this.loadDataToMemory) as FileInfo;
        if (file != null) {
          files.add(file);
          Log.d(TAG, "[MultiFilePick] File #" + currentItem + " - URI: " + currentUri);
        }
        currentItem++;
      }
    }
    this.finishWithSuccess(files);
  }

  async handleSingleResult(uris: string): Promise<void> {
    let files: List<FileInfo> = new List();
    if (this.ability?.context) {
      let file: FileInfo =
        await FileUtils.openFileStream(this.ability?.context, uris, this.loadDataToMemory) as FileInfo;
      if (file != null) {
        files.add(file);
      }
      if (!files.isEmpty()) {
        Log.d(TAG, "File path:" + files.toString())
        this.finishWithSuccess(files);
      } else {
        this.finishWithError("unknown_path", "Failed to retrieve path.");
      }
    }
  }

  saveFinishWithSuccess(data: string) {
    this.dispatchEventStatus(false);
    this.pendingResult?.success(data);
    this.clearPendingResult();
  }

  finishWithSuccess(data: List<FileInfo>) {
    this.dispatchEventStatus(false);
    let result: List<Map<string, Object>> | null = null;
    if (this.pendingResult != null) {
      if (data != null && !(data instanceof String)) {
        let files: List<Map<string, Object>> = new List();
        data.forEach((file) => {
          files.add(file.toMap());
        })
        result = files
      }
    }
    this.pendingResult?.success(result);
    this.clearPendingResult();
  }

  saveFile(fileNameArray: Array<string>, type: string, initialDirectory: string, allowedExtensions: Array<string>,
    bytes: Uint8Array | null, result: MethodResult) {
    if (!this.setPendingMethodCallAndResult(result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    let documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    if (initialDirectory) {
      documentSaveOptions.defaultFilePathUri = initialDirectory;
    }
    if (allowedExtensions && allowedExtensions.length > 0) {
      documentSaveOptions.fileSuffixChoices = allowedExtensions;
    }
    if (fileNameArray && fileNameArray.length > 0) {
      documentSaveOptions.newFileNames = fileNameArray;
    }

    let commonContext = this.ability?.context as common.UIAbilityContext;
    let documentPicker = new picker.DocumentViewPicker(commonContext);
    documentPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
      if (documentSaveResult == null || documentSaveResult.length == 0) {
        this.finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        return;
      }
      let saveUri: string = documentSaveResult[0];
      let originFileName = FileUtils.getFileName(saveUri);
      let newSavePath: string = saveUri;
      if (originFileName != null) {
        let newFileName = FileUtils.urlDecodeManual(originFileName);
        newSavePath = FileUtils.replaceFileName(saveUri, originFileName, newFileName);
      }
      if (bytes != null && bytes.length > 0) {
        try {
          this.persistBytesToUri(newSavePath, bytes);
        } catch (err) {
          this.finishWithError("write_failed", "Failed to write file: " + JSON.stringify(err));
          return;
        }
      }
      this.saveFinishWithSuccess(newSavePath);
    }).catch((err: BusinessError) => {
      if (err.code == 13900001) {
        this.finishWithError(err.code.toString(), err.message + ", 此文件路径无权访问，只接受应用沙箱路径");
      } else {
        this.finishWithError(err.code.toString(), err.message);
      }
    });
  }

  writeFile(uri: string, bytes: Uint8Array, result: MethodResult) {
    if (!this.setPendingMethodCallAndResult(result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    try {
      this.persistBytesToUri(uri, bytes);
      this.dispatchEventStatus(false);
      this.pendingResult?.success(true);
      this.clearPendingResult();
    } catch (err) {
      this.finishWithError("write_failed", "Failed to write file: " + JSON.stringify(err));
    }
  }

  private persistBytesToUri(uri: string, bytes: Uint8Array) {
    let file = fs.openSync(uri, fs.OpenMode.READ_WRITE);
    fs.writeSync(file.fd, bytes.buffer);
    fs.closeSync(file);
  }

  finishWithError(errorCode: string, errorMessage: string) {
    if (this.pendingResult == null) {
      return;
    }
    this.dispatchEventStatus(false);
    this.pendingResult.error(errorCode, errorMessage, null);
    this.clearPendingResult();
  }

  dispatchEventStatus(status: boolean) {
    if (this.eventSink == null || this.type === ("dir")) {
      return;
    }
    this.eventSink.success(status)
  }

  setEventHandler(eventSink: EventSink) {
    this.eventSink = eventSink;
  }

  setPendingMethodCallAndResult(result: MethodResult): boolean {
/*
    if (this.pendingResult != null) {
      return false;
    }
*/
    this.pendingResult = result;
    return true;
  }

  finishWithAlreadyActiveError(result: MethodResult) {
    result.error("already_active", "File picker is already active", null)
  }

  clearPendingResult() {
    this.pendingResult = null;
  }

  resolveType(type: string) {
    switch (type) {
      case "image":
        return photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      case "video":
        return photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      case "media":
        return photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE;
      case "any":
      default:
        return null;
    }
  }

  async isPermissionGranted(permission: Permissions): Promise<boolean> {
    let tokenId: number = 0;
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    return grantStatus == -1;
  }

  askForPermission(permissionName: Permissions) {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let context: Context = this.ability?.context as Context
    atManager.requestPermissionsFromUser(context, [permissionName]).then((data: PermissionRequestResult) => {
    }).catch((err: BusinessError) => {
      console.error('data:' + JSON.stringify(err));
    });
  }
}

export interface PermissionManager {
  ability: UIAbility | null

  isPermissionGranted(permission: Permissions): Promise<boolean>;

  askForPermission(permissionName: Permissions, requestCode: number): void;
}

class PermissionManagerClass implements PermissionManager {
  public ability: UIAbility | null = null;

  constructor(ability: UIAbility) {
    this.ability = ability
  }

  async isPermissionGranted(permission: Permissions): Promise<boolean> {
    let tokenId: number = 0;
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    return grantStatus == -1;
  }

  askForPermission(permissionName: Permissions, requestCode: number) {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let context: Context = this.ability?.context as Context
    atManager.requestPermissionsFromUser(context, [permissionName]).then((data: PermissionRequestResult) => {
    }).catch((err: BusinessError) => {
      console.error('data:' + JSON.stringify(err));
    });
  }
}
