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
import Want from '@ohos.app.ability.Want';
import hilog from '@ohos.hilog';
import { BusinessError } from '@ohos.base';

const CHANNEL: string = 'pica_comic/ohos_url_launcher';
const TAG: string = 'UrlLauncherPlugin';
const DOMAIN: number = 0xD005102;
const VIEW_ACTION: string = 'ohos.want.action.viewData';

export default class UrlLauncherPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private ability: UIAbility | null = null;

  getUniqueClassName(): string {
    return 'UrlLauncherPlugin';
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
      case 'launch':
        this.handleLaunch(call, result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async handleLaunch(call: MethodCall, result: MethodResult): Promise<void> {
    const url = this.resolveUrl(call);
    if (!url) {
      result.error('invalid_args', 'URL cannot be empty', null);
      return;
    }
    try {
      await this.launchUrl(url);
      result.success(true);
    } catch (error) {
      const message = (error as BusinessError)?.message ?? JSON.stringify(error);
      hilog.error(DOMAIN, TAG, `launch failed: ${message}`);
      result.error('launch_error', message, null);
    }
  }

  private resolveUrl(call: MethodCall): string | null {
    const urlArg = call.argument('url') as string | null;
    if (this.isValidArgument(urlArg)) {
      return urlArg as string;
    }
    const uriArg = call.argument('uri') as string | null;
    if (this.isValidArgument(uriArg)) {
      return uriArg as string;
    }
    const argsValue = call.args as string | null;
    if (this.isValidArgument(argsValue)) {
      return argsValue as string;
    }
    return null;
  }

  private isValidArgument(value: string | null): boolean {
    return value !== null && value !== undefined && value.length > 0;
  }

  private async launchUrl(url: string): Promise<void> {
    if (!this.ability) {
      throw new Error('UIAbility not attached');
    }
    const context = this.ability.context as common.UIAbilityContext;
    const want: Want = {
      uri: url,
      action: VIEW_ACTION,
    };
    await context.startAbility(want);
  }
}
