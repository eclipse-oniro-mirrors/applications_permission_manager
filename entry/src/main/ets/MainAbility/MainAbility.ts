import UIAbility from '@ohos.app.ability.UIAbility';

export default class MainAbility extends UIAbility {
  onCreate(want, launchParam): void {}

  onDestroy(): void {}

  onWindowStageCreate(windowStage): void {
    windowStage.setUIContent(this.context, 'pages/index', null);
  }

  onWindowStageDestroy(): void {}

  onForeground(): void {}

  onBackground(): void {}
};
