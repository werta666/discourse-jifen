# frozen_string_literal: true

module ::MyPluginModule
  class QdController < ::ApplicationController
    requires_plugin MyPluginModule::PLUGIN_NAME

    before_action :ensure_logged_in, except: [:index]

    # Ember 引导页
    def index
      render "default/empty"
    end

    # 概览数据（/qd 页面所需）
    def summary
      render_json_dump MyPluginModule::JifenService.summary_for(current_user)
    end

    # 签到记录（按时间倒序）
    def records
      recs = MyPluginModule::JifenSignin
        .where(user_id: current_user.id)
        .order(date: :desc)
        .limit(200)

      render_json_dump(
        records: recs.map do |r|
          {
            date: r.date.to_s,
            signed_at: r.signed_at&.iso8601,
            makeup: r.makeup,
            points: r.points,
            streak_count: r.streak_count
          }
        end
      )
    end

    # 今日签到
    def signin
      render_json_dump MyPluginModule::JifenService.signin!(current_user)
    rescue ActiveRecord::RecordNotUnique
      render_json_error("今日已签到", status: 409)
    rescue => e
      render_json_error(e.message)
    end

    # 占位：补签与购买补签卡（后续可实现）
    def makeup
      render_json_dump(ok: false, message: "补签功能暂未开放")
    end

    def buy_makeup_card
      render_json_dump(ok: false, message: "购买补签卡暂未开放")
    end
  end
end