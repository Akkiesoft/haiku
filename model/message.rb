# -*- coding: utf-8 -*-

module Plugin::Haiku
  class Entry < Diva::Model
    include Diva::Model::MessageMixin

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
      Diva::URI(self[:link])
    end

    def from_me?(world = Enumerator.new{|y| Plugin.filtering(:worlds, y) })
      case world
      when Enumerable
        world.any?(&method(:from_me?))
      when Diva::Model
        world.class.slug == :haiku && world.user == self.user
      end
    end

  end
end
