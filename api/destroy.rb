# -*- coding: utf-8 -*-

module Plugin::Haiku

  def destroyEntry(entry, hatena_id, hatena_api_pass)
    p entry
    begin
      Thread.new {
        res = Net::HTTP.post_form(
          URI.parse("http://#{hatena_id}:#{hatena_api_pass}@h.hatena.ne.jp/api/statuses/destroy/#{entry.id}.json"),
          { 'author_url_name' => hatena_id }
        )
      }
    rescue => ee
      activity :haiku, "削除に失敗しました。\n#{ee}"
    end
  end

  module_function :destroyEntry
end
