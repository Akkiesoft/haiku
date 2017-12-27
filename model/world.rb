# -*- coding: utf-8 -*-

module Plugin::Haiku
  class World < Diva::Model

    register :haiku, name: "はてなハイクアカウント"

    field.string :hatena_id, required: true
    field.string :api_password, required: true
    field.string :slug, required: true
    alias_method :name, :slug

    def self.build(credential)
      world = new(
        hatena_id: credential[:hatena_id],
        api_password: credential[:api_password]
      )
      Delayer::Deferred.when(
        # ここでユーザー名とかアイコンとかの情報を取るAPIを叩いて取得
        Thread.new{ world.api.auth_test },
        world.api.users.dict
      ).next{|auth, user_map|
        # 取得したものをworldに詰め込む
        world.slug = 
        # worldを返す
        world
      }
    end
  end
end
