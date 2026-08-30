import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import Configuration from '@ohos.app.ability.Configuration';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('ComicReader EntryAbility onCreate');
    this.pushColorModeToAppStorage();
  }

  onConfigurationUpdated(newConfig: Configuration): void {
    this.pushColorModeToAppStorage();
  }

  private pushColorModeToAppStorage(): void {
    try {
      const config: Record<string, Object> = this.context.config as Record<string, Object>;
      const colorMode: number = (config['colorMode'] as number) ?? 1;
      const isDark = colorMode === 0;
      AppStorage.setOrCreate<string>('systemColorMode', isDark ? 'dark' : 'light');
      AppStorage.setOrCreate<number>('uiVersion', Date.now());
    } catch (e) {
      AppStorage.setOrCreate<string>('systemColorMode', 'light');
    }
  }

  onDestroy(): void {
    console.info('ComicReader EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error(`Failed to load Index. code=${err.code}, message=${err.message}`);
        return;
      }
      console.info('Succeeded in loading Index.');
      try {
        const mainWindow = windowStage.getMainWindowSync();
        mainWindow.setWindowLayoutFullScreen(true);
        const sysBarProps: window.SystemBarProperties = {
          statusBarColor: '#00000000',
          statusBarContentColor: '#000000',
          navigationBarColor: '#00000000',
          navigationBarContentColor: '#000000'
        };
        mainWindow.setWindowSystemBarProperties(sysBarProps);
      } catch (e) {
        console.error('Failed to set fullscreen mode: ' + JSON.stringify(e));
      }
    });
  }

  onWindowStageDestroy(): void {
    console.info('ComicReader EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('ComicReader EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('ComicReader EntryAbility onBackground');
  }
}
