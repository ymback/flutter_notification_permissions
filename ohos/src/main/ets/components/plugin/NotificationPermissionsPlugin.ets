import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { common, Want } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/** NotificationPermissionsPlugin **/
export default class NotificationPermissionsPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "NotificationPermissionsPlugin"
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context
  }

  onDetachedFromAbility(): void {
    this.context = null
  }


  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "notification_permissions");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "getNotificationPermissionStatus":
        this.getNotificationPermissionStatus(call, result)
        break
      case "requestNotificationPermissions":
        this.requestNotificationPermissions(call, result)
        break
      default:
        result.notImplemented()
    }
  }

  async getNotificationPermissionStatus(call: MethodCall, result: MethodResult) {
    result.success(await notificationManager.isNotificationEnabled())
  }

  async requestNotificationPermissions(call: MethodCall, result: MethodResult) {
    if (this.context == null) {
      result.error("context is null", "context is null", null)
      return
    }
    notificationManager.requestEnableNotification(this.context).then(async () => {
      result.success(await notificationManager.isNotificationEnabled())
    }).catch((err: BusinessError) => {
      result.success(false)
      if (1600004 === err.code) {
        const context = getContext(this) as common.UIAbilityContext;
        let want: Want = {
          bundleName: "com.huawei.hmos.settings",
          abilityName: "com.huawei.hmos.settings.MainAbility",
          uri: 'application_info_entry',
          parameters: {
            settingsParamBundleName: context.abilityInfo.bundleName
          }
        }
        context.startAbility(want)
      }
    });
  }
}