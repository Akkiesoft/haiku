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

    def id
      # :idはハイクに数値IDが存在しないのでハッシュでごまかす
      self[:id].hash
    end

    def perma_link
      link
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
      profile_image_url
    end

    def verified?
      false
    end

    def protected?
      false
    end
  end
end
