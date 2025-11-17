import {
  AbilityPluginBinding,
  BinaryMessenger,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import {
  abilityAccessCtrl,
  common,
  Permissions,
  UIAbility,
} from '@kit.AbilityKit';
import { picker, fileUri } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const CHANNEL: string = 'pica_comic/ohos_downloads';
const TAG: string = 'DownloadBridgePlugin';
const DOMAIN: number = 0xD005101;
const DOWNLOAD_SUBDIR: string = 'picacomic';
const PROBE_NAME: string = '.pica_probe';
const STORAGE_PERMISSIONS: Array<Permissions> = [
  'ohos.permission.READ_MEDIA' as Permissions,
  'ohos.permission.WRITE_MEDIA' as Permissions,
  'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY' as Permissions,
];

export default class DownloadBridgePlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private ability: UIAbility | null = null;
  private cachedPath: string | null = null;

  getUniqueClassName(): string {
    return 'DownloadBridgePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger: BinaryMessenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(messenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityBinding = binding;
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(binding: AbilityPluginBinding): void {
    if (this.abilityBinding === binding) {
      this.abilityBinding = null;
    }
    this.ability = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'ensureDownloadDir':
        this.handleEnsureDownloadDir(result);
        break;
      case 'resetCachedPath':
        this.cachedPath = null;
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  private async handleEnsureDownloadDir(result: MethodResult): Promise<void> {
    try {
      await this.ensurePermissions();
      const path = await this.ensureDownloadDir();
      result.success(path);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `ensureDownloadDir failed: ${message}`);
      result.error('download_error', message, null);
    }
  }

  private async ensurePermissions(): Promise<void> {
    if (!this.ability) {
      return;
    }
    const context = this.ability.context as common.UIAbilityContext;
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(context, STORAGE_PERMISSIONS);
  }

  private async ensureDownloadDir(): Promise<string> {
    if (this.cachedPath) {
      return this.cachedPath;
    }
    if (!this.ability) {
      throw new Error('UIAbility not attached');
    }
    const abilityContext = this.ability.context as common.UIAbilityContext;
    const documentPicker = new picker.DocumentViewPicker(abilityContext);
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    const uris: Array<string> = await documentPicker.save(saveOptions);
    if (!uris || uris.length === 0) {
      throw new Error('Download mode returned empty uri');
    }
    const targetDir = this.resolveDownloadPath(uris[0]);
    await this.ensureDirectory(targetDir);
    this.cachedPath = targetDir;
    return targetDir;
  }

  private resolveDownloadPath(baseUri: string): string {
    const normalizedUri = `${baseUri}/${PROBE_NAME}`;
    const resolvedProbePath = new fileUri.FileUri(normalizedUri).path;
    if (!resolvedProbePath) {
      throw new Error('Unable to resolve download uri');
    }
    const separatorIndex = resolvedProbePath.lastIndexOf('/');
    if (separatorIndex === -1) {
      throw new Error('Invalid resolved path');
    }
    const directoryPath = resolvedProbePath.substring(0, separatorIndex);
    return `${directoryPath}/${DOWNLOAD_SUBDIR}`;
  }

  private async ensureDirectory(path: string): Promise<void> {
    try {
      const exists = await fs.access(path);
      if (!exists) {
        fs.mkdirSync(path, true);
      }
    } catch (_) {
      fs.mkdirSync(path, true);
    }
  }
}
