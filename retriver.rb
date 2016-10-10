# -*- coding: utf-8 -*-

module Plugin::Haiku
  class User < Retriever::Model
    include Retriever::Model::UserMixin
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

  class Entry < Retriever::Model
    include Retriever::Model::MessageMixin

    register :hatenahaiku_entry, name: "HatenaHaiku::Entry"
    entity_class Retriever::Entity::URLEntity

    field.string :id
    field.string :message
    field.string :user
    field.string :link
    field.string :source
    field.time   :created

    def to_show
      @to_show ||= self[:message]
    end

    def perma_link
      link
    end

  end
end
