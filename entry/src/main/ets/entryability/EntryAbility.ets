import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('ComicReader EntryAbility onCreate');
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
