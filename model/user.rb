# -*- coding: utf-8 -*-

module Plugin::Haiku
  class User < Diva::Model

    include Diva::Model::UserMixin

    field.string :name, required: true
    field.string :idname, required: true
    field.string :nickname, required: true
    field.string :profile_image_url, required: true
    field.string :description
    field.string :link

    alias to_s idname

    def id
      # :idはハイクに数値IDが存在しないのでハッシュでごまかす
      self[:id].hash
    end

    def perma_link
      Diva::URI(self[:link])
    end

    def user
      self
    end

    def icon
      _, photos = Plugin.filtering(:photo_filter, self[:profile_image_url], [])
      photos.first
    rescue => err
      Skin['notfound.png']
    end

    def profile_image_url_large
      # どれがね゛え！　どれが同じアイゴン返ジデモ゛
      # オンナジヤ、オンナジヤ思っでえ！　ウーハッフッハーン！！　ッウーン！
      self.icon
    end

    def verified?
      false
    end

    def protected?
      false
    end

    def inspect
      "HaikuUser(#{@value[:idname]})"
    end

  end
end
