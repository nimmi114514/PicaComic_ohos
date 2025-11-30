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
import { picker, fileUri } from '@kit.CoreFileKit';
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
      options.pickerMode = picker.DocumentPickerMode.FILE;
      options.maxSelectNumber = 1;
      options.fileExtensionFilter = ['picadata'];
      const uris: Array<string> = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        result.success(null);
        return;
      }
      const filePath = new fileUri.FileUri(uris[0]).path;
      result.success(filePath);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      result.error('pick_error', message, null);
    }
  }
}
