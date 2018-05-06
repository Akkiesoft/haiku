# -*- coding: utf-8 -*-

module Plugin::Haiku

  def postToHaiku(message, hatena_id, hatena_api_pass, reply_to = nil)
    begin
      params = {'keyword'=>"id:#{hatena_id}", 'status'=>message, 'source'=>'mikutter/haiku'}
      if reply_to
        params['in_reply_to_status_id'] = reply_to
      end
      Thread.new {
        res = Net::HTTP.post_form(
          URI.parse("http://#{hatena_id}:#{hatena_api_pass}@h.hatena.ne.jp/api/statuses/update.json"),
          params
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

  module_function :postToHaiku
end
