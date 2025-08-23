# frozen_string_literal: true

module ::MyPluginModule
  class AdminController < ::ApplicationController
    requires_plugin MyPluginModule::PLUGIN_NAME
    before_action :ensure_admin

    # 管理员触发的同步任务占位（供“同步积分”按钮调用）
    def sync
      # TODO: 在此加入实际的积分重新聚合逻辑（如有需要）
      render_json_dump(ok: true, message: "已触发同步（占位）")
    end
  end
end