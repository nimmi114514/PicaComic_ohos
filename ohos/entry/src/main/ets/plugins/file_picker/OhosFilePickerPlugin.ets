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
import { common, UIAbility } from '@kit.AbilityKit';
import { picker, fileUri, fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';

const CHANNEL: string = 'pica_comic/ohos_file_picker';

export default class OhosFilePickerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;

  getUniqueClassName(): string {
    return 'OhosFilePickerPlugin';
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
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(binding: AbilityPluginBinding): void {
    if (this.ability === binding.getAbility()) {
      this.ability = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'pickPicadata':
        this.handlePickPicadata(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async handlePickPicadata(result: MethodResult): Promise<void> {
    if (!this.ability) {
      result.error('no_ability', 'UIAbility not attached', null);
      return;
    }
    try {
      const abilityContext = this.ability.context as common.UIAbilityContext;
      const documentPicker = new picker.DocumentViewPicker(abilityContext);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['picadata'];
      const uris: Array<string> = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        result.success(null);
        return;
      }
      const sandboxPath = await this.copyToSandbox(abilityContext, uris[0]);
      result.success(sandboxPath);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      result.error('pick_error', message, null);
    }
  }

  private async copyToSandbox(context: common.UIAbilityContext, uri: string): Promise<string> {
    const targetDir = `${context.filesDir}/imports`;
    await this.ensureDir(targetDir);
    const fileName = this.decodeFileName(this.extractFileName(uri));
    const uniqueName = `${Date.now()}_${fileName}`;
    const targetPath = `${targetDir}/${uniqueName}`;
    const sourcePath = this.resolveFilePath(uri);
    if (sourcePath) {
      try {
        fs.copyFileSync(sourcePath, targetPath);
        return targetPath;
      } catch (error) {
        console.error(`[OhosFilePicker] copyFileSync failed: ${JSON.stringify(error)}`);
      }
    }
    this.copyByStream(uri, targetPath);
    return targetPath;
  }

  private async ensureDir(path: string): Promise<void> {
    try {
      await fs.access(path);
    } catch (_) {
      fs.mkdirSync(path, true);
    }
  }

  private extractFileName(uri: string): string {
    const trimmed = uri.endsWith('/') ? uri.substring(0, uri.length - 1) : uri;
    const idx = trimmed.lastIndexOf('/');
    if (idx >= 0 && idx < trimmed.length - 1) {
      return trimmed.substring(idx + 1);
    }
    return `picked_${Date.now()}`;
  }

  private decodeFileName(name: string): string {
    try {
      return decodeURIComponent(name);
    } catch (_) {
      return name;
    }
  }

  private resolveFilePath(uri: string): string | null {
    if (!uri || uri.length === 0) {
      return null;
    }
    if (uri.startsWith('file://docs')) {
      return this.decodeUri(uri.replace('file://docs', ''));
    }
    if (uri.startsWith('file://')) {
      return new fileUri.FileUri(uri).path;
    }
    return uri;
  }

  private copyByStream(sourceUri: string, target: string): void {
    const resolvedSource = this.resolveFilePath(sourceUri) ?? sourceUri;
    const sourceEntry = fs.openSync(resolvedSource, fs.OpenMode.READ_ONLY);
    const targetEntry = fs.openSync(target, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    try {
      const buffer = new ArrayBuffer(4096);
      while (true) {
        const readSize = fs.readSync(sourceEntry.fd, buffer);
        if (readSize <= 0) {
          break;
        }
        fs.writeSync(targetEntry.fd, buffer, { length: readSize });
      }
    } finally {
      fs.closeSync(sourceEntry);
      fs.closeSync(targetEntry);
    }
  }

  private decodeUri(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch (_) {
      return value;
    }
  }
}
