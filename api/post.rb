# -*- coding: utf-8 -*-

module Plugin::Haiku

  def postToHaiku(message, hatena_id, hatena_api_pass)
    begin
      Thread.new {
        res = Net::HTTP.post_form(
          URI.parse("http://#{hatena_id}:#{hatena_api_pass}@h.hatena.ne.jp/api/statuses/update.json"),
          {'keyword'=>"id:#{hatena_id}", 'status'=>message, 'source'=>'mikutter/haiku'}
        )
        # TODO: ホントはこういうのをやりたいけどうまく差し込めていない
        #items = [ JSON.parse(res.body) ]
        #parse(items)
      }
    rescue => ee
      activity :haiku, "投稿に失敗しました。\n#{ee}"
    end
  end

  module_function :postToHaiku
end
