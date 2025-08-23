import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class QdRoute extends Route {
  async model() {
    try {
      // 加载概览数据
      return await ajax("/qd/summary.json");
    } catch (e) {
      // 未登录或接口不可用时，返回占位数据以渲染未登录分支
      return {
        user_logged_in: false,
        signed: false,
        consecutive_days: 0,
        total_score: 0,
        today_score: 0,
        points: 0,
        makeup_cards: 0,
        makeup_card_price: 0,
        install_date: new Date().toISOString().slice(0, 10),
        rewards: {}
      };
    }
  }

  async setupController(controller, model) {
    super.setupController(controller, model);
    controller.model = model;

    // 已登录则加载签到记录并计算缺勤天
    if (model.user_logged_in) {
      await controller.loadRecords();
    } else {
      controller.records = [];
      controller.missingDays = [];
    }
  }
}