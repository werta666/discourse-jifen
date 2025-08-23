import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";

export default class QdController extends Controller {
  // 界面状态
  @tracked isLoading = false;

  // 数据集合
  @tracked records = [];
  @tracked missingDays = [];

  // 奖励提示文本（基于设置中的 JSON 连续奖励与当前连续天数）
  get rewardText() {
    const rewards = this.model?.rewards || {};
    const streak = Number(this.model?.consecutive_days || 0);

    const entries = Object.keys(rewards)
      .map((k) => [parseInt(k, 10), parseInt(rewards[k], 10)])
      .filter(([d, p]) => Number.isFinite(d) && Number.isFinite(p))
      .sort((a, b) => a[0] - b[0]);

    for (const [days, pts] of entries) {
      if (days > streak) {
        const remain = days - streak;
        return `再签到 ${remain} 天可获得额外 ${pts} 积分奖励`;
      }
    }
    return "继续保持签到，可解锁更高奖励";
  }

  // 加载签到记录（倒序）
  async loadRecords() {
    try {
      const data = await ajax("/qd/records.json");
      this.records = data.records || [];
      this.missingDays = this._computeRecentMissingDays(this.records);
    } catch {
      this.records = [];
      this.missingDays = [];
    }
  }

  // 计算最近 7 天缺勤（不含今天），用于“补签功能”占位展示
  _computeRecentMissingDays(records) {
    try {
      const signedSet = new Set((records || []).map((r) => r.date));
      const result = [];
      const today = new Date();

      for (let i = 1; i <= 7; i++) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        const s = d.toISOString().slice(0, 10);
        if (!signedSet.has(s)) {
          result.push({ date: s, formatted_date: s });
        }
      }
      return result;
    } catch {
      return [];
    }
  }

  // 今日签到
  @action
  async signIn() {
    if (this.isLoading) return;
    this.isLoading = true;
    try {
      const data = await ajax("/qd/signin.json", { type: "POST" });
      // 后端返回最新 summary，直接替换 model
      this.model = data;
      await this.loadRecords();
    } catch {
      // 保持静默，前端 UI 已有禁用态/提示
    } finally {
      this.isLoading = false;
    }
  }

  // 补签（占位：后端当前返回未开放）
  @action
  async makeupSign(date) {
    try {
      await ajax("/qd/makeup.json", { type: "POST", data: { date } });
      await this.loadRecords();
    } catch {
      // 占位
    }
  }

  // 购买补签卡（占位）
  @action
  async buyMakeupCard() {
    try {
      await ajax("/qd/buy_makeup_card.json", { type: "POST" });
      await this.loadRecords();
    } catch {
      // 占位
    }
  }

  // 管理员调试：同步
  @action
  async syncAllScores() {
    try {
      await ajax("/qd/admin/sync.json", { type: "POST" });
    } catch {
      // 占位
    }
  }
}