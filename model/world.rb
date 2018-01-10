# -*- coding: utf-8 -*-

module Plugin::Haiku
  class World < Diva::Model

    register :haiku, name: "はてなハイクアカウント"

    field.string :haiku_hatena_id, required: true
    field.string :haiku_api_passwd, required: true
    field.string :slug, required: true

    def self.build(credential)
      world = new(
        haiku_hatena_id: credential[:haiku_hatena_id],
        haiku_api_passwd: credential[:haiku_api_passwd],
        slug: ''
      )
      Delayer::Deferred.when(
        Thread.new{
          Plugin::Haiku.get_user(
            credential[:haiku_hatena_id],
            credential[:haiku_api_passwd], 1
          )
        }
      ).next{|user_info|
        world.user = Plugin::Haiku::User.new({
          name: user_info[0]['name'],
          idname: user_info[0]['screen_name'],
          nickname: user_info[0]['screen_name'],
          profile_image_url: user_info[0]['profile_image_url'].split("?")[0],
          link: user_info[0]['url']
        })
        world.slug = "haiku-#{world.user.id}".to_sym
        world
      }
    end

    def user
      @user || Plugin::Haiku::User.new(self[:user])
    end

    def user=(new_user)
      @user = new_user
    end

    def icon
      user.icon
    end

    def title
      "#{user.name}(id:#{user.idname})"
    end

    def initialize(hash)
      super(hash)
      user_info = Plugin::Haiku.get_user(
        hash[:haiku_hatena_id],
        hash[:haiku_api_passwd], 1
      )
      @user = Plugin::Haiku::User.new({
        name: user_info['name'],
        idname: user_info['screen_name'],
        nickname: user_info['screen_name'],
        profile_image_url: user_info['profile_image_url'].split("?")[0],
        link: user_info['url']
      })
    end

  end
end
