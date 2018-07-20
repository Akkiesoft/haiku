# -*- coding: utf-8 -*-

module Plugin::Haiku

  def favToHaiku(hatena_id, hatena_api_pass, id)
    begin
      Thread.new {
        res = Net::HTTP.post_form(
          URI.parse("http://#{hatena_id}:#{hatena_api_pass}@h.hatena.ne.jp/api/favorites/create/#{id}.json"), {}
        )
        # TODO: ホントはこういうのをやりたいけどうまく差し込めていない
        #items = [ JSON.parse(res.body) ]
        #parse(items)
      }
    rescue => ee
      # ファイル分けたせいで動いてない
      # activity :haiku, "投稿に失敗しました。\n#{ee}"
      puts ee
    end
  end

  module_function :favToHaiku
end
