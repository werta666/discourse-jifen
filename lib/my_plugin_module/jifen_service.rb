# frozen_string_literal: true

require "json"

module ::MyPluginModule
  module JifenService
    module_function

    def rewards_map
      raw = SiteSetting.jifen_consecutive_rewards_json.presence || "{}"
      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end

    def base_points
      SiteSetting.jifen_base_points_per_signin.to_i
    end

    def signed_today?(user_id)
      MyPluginModule::JifenSignin.exists?(user_id: user_id, date: Time.zone.today)
    end

    def last_signin(user_id)
      MyPluginModule::JifenSignin.where(user_id: user_id).order(date: :desc).first
    end

    def total_points(user_id)
      MyPluginModule::JifenSignin.where(user_id: user_id).sum(:points)
    end

    def today_points(user_id)
      MyPluginModule::JifenSignin.where(user_id: user_id, date: Time.zone.today).sum(:points)
    end

    # 用于 summary 展示的连续天数（若今天没签，取到昨日为止的连续天数）
    def compute_streak_on_summary(user_id)
      last = last_signin(user_id)
      return 0 unless last
      if last.date == Time.zone.today
        last.streak_count
      elsif last.date == Time.zone.yesterday
        last.streak_count
      else
        0
      end
    end

    def next_reward_info(streak, rewards)
      return nil if rewards.blank?
      entries = rewards.map { |k, v| [k.to_i, v.to_i] }.sort_by(&:first)
      entries.each do |days, pts|
        if days > streak
          return { days: days, points: pts, remain: days - streak }
        end
      end
      nil
    end

    def summary_for(user)
      uid = user.id
      signed = signed_today?(uid)
      streak = compute_streak_on_summary(uid)
      total = total_points(uid)
      today = today_points(uid)
      rewards = rewards_map
      next_rw = next_reward_info(streak, rewards)
      install_date = MyPluginModule::JifenSignin.order(:date).limit(1).pluck(:date).first || Date.today

      data = {
        user_logged_in: true,
        signed: signed,
        consecutive_days: streak,
        total_score: total,
        today_score: today,
        points: base_points,
        makeup_cards: 0,
        makeup_card_price: SiteSetting.jifen_makeup_card_price.to_i,
        install_date: install_date.to_s,
        rewards: rewards
      }
      data[:next_reward] = next_rw if next_rw
      data
    end

    def signin!(user)
      uid = user.id
      return summary_for(user) if signed_today?(uid)

      rewards = rewards_map
      ActiveRecord::Base.transaction do
        prev = MyPluginModule::JifenSignin.where(user_id: uid).order(date: :desc).lock(true).first
        if prev && prev.date == Time.zone.today
          raise ActiveRecord::RecordNotUnique
        end

        new_streak =
          if prev && prev.date == Time.zone.yesterday
            prev.streak_count + 1
          else
            1
          end

        reward_points = rewards[new_streak.to_s].to_i
        pts = base_points + reward_points

        MyPluginModule::JifenSignin.create!(
          user_id: uid,
          date: Time.zone.today,
          signed_at: Time.zone.now,
          makeup: false,
          points: pts,
          streak_count: new_streak
        )
      end

      summary_for(user)
    end
  end
end