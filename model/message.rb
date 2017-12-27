# -*- coding: utf-8 -*-

module Plugin::Haiku
  class Entry < Retriever::Model
    include Retriever::Model::MessageMixin

    register :hatenahaiku_entry, name: "HatenaHaiku::Entry"
    entity_class Retriever::Entity::URLEntity

    field.string :id
    field.string :message
    field.has    :user, Plugin::Haiku::User
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
