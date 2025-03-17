/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { AsyncCallback, BusinessError } from '@ohos.base';
import { Log } from '../utils/utils';
import commonEventManager from '@ohos.commonEventManager';

export class EventObserver {
  private events: string[];
  private subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: []
  };

  constructor(events: string[]) {
    this.events = events;
  }

  /**
   * 注册监听资源变化事件
   * @param callback
   * return
   */
  public register(callback: AsyncCallback<commonEventManager.CommonEventData>): void {
    if (callback === undefined || callback === null) {
      Log.error(`callback is undefined.`);
      return;
    }
    try {
      if (this.events === undefined || !this.events.length) {
        Log.error(`event is undefined.`);
        return;
      }
      this.subscribeInfo.events = this.events;
      commonEventManager.createSubscriber(this.subscribeInfo).then(subscriber => {
        if (subscriber === undefined) {
          Log.error(`subscriber is undefined.`);
          return;
        }
        this.subscriber = subscriber;
        try {
          commonEventManager.subscribe(this.subscriber, callback);
          Log.info(`subscribe success.`);
        } catch (err) {
          Log.error(`subscribe faild, code: ${err.code}, message: ${err.message}.`);
        }
      }).catch((err: BusinessError) => {
        Log.error(`createSubscriber faild, code: ${err.code}, message: ${err.message}.`);
      })
    } catch (error) {
      Log.error(`create subscriber faild, code: ${error.code}, message: ${error.message}.`);
    }
  }

  /**
   * 注销监听
   * return
   */
  public unregister(): void {
    if (this.subscriber === undefined) {
      Log.error(`subscriber is undefined.`);
      return;
    }
    try {
      commonEventManager.unsubscribe(this.subscriber, err => {
        if (err) {
          Log.error(`unsubscriber faild, code: ${err.code}, message: ${err.message}.`);
        } else {
          Log.info(`unsubscriber success.`);
        }
      })
    } catch (error) {
      Log.error(`unsubscriber faild, code: ${error.code}, message: ${error.message}.`);
    }
  }

}