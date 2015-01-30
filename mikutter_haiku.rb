# -*- coding:utf-8 -*-
################################################################################
##  mikutter_haiku
##    https://github.com/Akkiesoft/mikutter_haiku
##

## mikutter_haikuはご覧のスポンサーでお送りします
require 'net/http'
require 'uri'
require 'json'
require 'time'


## START
Plugin.create(:mikutter_haiku) do

  defactivity "mikutter_haiku", "はてなハイク"

  # TODO: warning: class variable access from toplevelなので対処する
  @@haiku_lastupdate = 0;

  ########################################
  ## Writer :: 投稿処理
  ##
  def postToHaiku(message)
    # 設定が入ってるかチェック
    cant_post = 0
    hatena_id = UserConfig[:hatena_id]
    if hatena_id=='' then
      cant_post = 1
    end
    hatena_api_pass = UserConfig[:hatena_api_pass]
    if hatena_api_pass=='' then
      cant_post = 1
    end

    if cant_post == 1 then
      activity :mikutter_haiku, "投稿に必要な設定がありません。設定画面でIDとパスワードを設定してください('ω`)"
    else
      begin
        res = Net::HTTP.post_form(
          URI.parse("http://#{hatena_id}:#{hatena_api_pass}@h.hatena.ne.jp/api/statuses/update.json"),
          {'keyword'=>"id:#{hatena_id}", 'status'=>message, 'source'=>'mikutter_haiku'}
        )
      rescue => ee
        activity :mikutter_haiku, "投稿に失敗しました。\n#{ee}"
      end
	end
  end

  ########################################
  ## Reader :: リロード処理
  ##
# TODO:
# JSONごとにlastupdateを持たせるようにする
# {["url":"<URL>", "lastupdate":"<time>"],...}みたいなのを作って管理？
  def reload_haiku
    (UserConfig[:haiku_url]|| []).select{|m|!m.empty?}.each do |url|
      begin
        now = Time.now.to_i
        if @@haiku_lastupdate == 0 then
          timeline = "&reftime=-#{now},0"
        else
          timeline = "&reftime=+#{@@haiku_lastupdate},1"
        end
        uri = URI.parse("#{url}?body_formats=haiku#{timeline}")
        json = Net::HTTP.get(uri)
        items = JSON.parse(json)
      rescue => ee
        # パースに失敗した場合は例外引っ掛けてスルー
        activity :mikutter_haiku, "JSONのパースに失敗しました\n#{url}?body_formats=haiku\n#{ee}"
      else
        if items.length != 0 then
          # 最後に実行した時間を記録
          @@haiku_lastupdate = parse(items)
        end
      end
    end
    # また1分後にリロード
    Reserver.new(60) {
      reload_haiku
    }
  end

  ########################################
  ## Reader :: パース処理
  ##
  def parse(items)
    messages = items.inject(Messages.new) do |msgs, item|
      keyword	= item['target']['title']
      body		= item['haiku_text']
      link		= item['link']
      source	= item['source']
      time		= Time.parse(item['created_at']).localtime
      message_head = "#{item['user']['screen_name']} (Permalink)\n\n"
      message_text = "#{message_head}<#{keyword}>\n#{body}"

      user = User.new({
        # :idはハイクに数値IDが存在しないのでハッシュでごまかす
        id: "#{item['user']['id']}".hash,
        idname: item['user']['screen_name'],
        name: item['user']['name'],
        nickname: item['user']['screen_name'],
        profile_image_url: item['user']['profile_image_url'],
        url: item['user']['url'],
        detail: ""
      })

      message = Message.new({
        id: time.to_i,
        message: message_text,
        user: user,
        source: source,
        created: time
      })

      # はてなフォトライフ
      message_text.scan(/f:id:([-_a-zA-Z0-9]+):([0-9]{8})([0-9]{6})(j|g|p|f)?(:image|:movie)?/i) {
        match = Regexp.last_match
        pos = match.begin(0)
        foto_id			= match[1];
        foto_initial	= foto_id.slice(0, 1);
        foto_date		= match[2];
        foto_time		= match[3];
        foto_type		= (defined?(match[4])) ? match[4] : '';
        foto_mode		= (defined?(match[5])) ? match[5] : '';
        foto_ext		= 'jpg';
        foto_ext		= 'gif' if foto_type == 'g'
        foto_ext		= 'png' if foto_type == 'p'
        foto_org		= match.to_s
        foto_url = if foto_type == "f" && foto_mode == ":movie" then
                     "http://f.hatena.ne.jp/#{foto_id}/#{foto_date}#{foto_time}"
                   else
                     "http://cdn-ak.f.st-hatena.com/images/fotolife/#{foto_initial}/#{foto_id}/#{foto_date}/#{foto_date}#{foto_time}.#{foto_ext}"
                   end
        message.entity.add(slug: :urls,
                           url: foto_url,
                           face: foto_org,
                           range: pos...(pos + foto_org.size))
      }

      # Entitiesの作成
      message.entity.add(slug: :urls,
                         url: item['user']['url'],
                         face: item['user']['screen_name'],
                         range: 0...item['user']['screen_name'].size)
      message.entity.add(slug: :urls,
                         url: link,
                         face: "(Permalink)",
                         range: (item['user']['screen_name'].size+1)...(message_head.size-2))
      message.entity.add(slug: :urls,
                         url: "http://h.hatena.ne.jp/target?word=#{keyword}",
                         face: "<#{keyword}>",
                         range: (message_head.length)...(message_head.length + "<#{keyword}>".length))

      # URL記法対応
      message_text.gsub(/\[(https?:\/\/[-_.!~*\'\(\)a-zA-Z0-9;\/?:\@&=+\$,%#]+)\:title=(.+)\]/) do
        match = Regexp.last_match
        pos = match.begin(0)
        message.entity.add(slug: :urls,
                           url: match[1],
                           face: match[2],
                           range: pos...(pos + match.to_s.size))
      end

      msgs << message
    end
    Plugin.call(:extract_receive_message, :mikutter_haiku, messages)
    return Time.parse(items[0]['created_at']).to_i
  end

  ########################################
  ## Writer :: ハイクに投稿する
  ##
  command(:post_to_haiku,
  		name: 'ハイクに投稿する',
  		condition: lambda{ |opt| true },
  		visible: true,
  		role: :postbox) do |opt|
	begin
		message = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
		postToHaiku(message)
		defactivity "Haiku_post", "Haiku_Post"
		activity :Haiku_Post, "ハイクに投稿しました"
		Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ''
        reload_haiku
	end
  end

  ########################################
  ##  Writer :: ハイクとTwitterに投稿する
  ##
  command(:post_to_haiku_and_twitter,
  		name: 'ハイクとTwitterに投稿する',
  		condition: lambda{ |opt| true },
  		visible: true,
  		role: :postbox) do |opt|
	begin
		message = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text
		Service.primary.update(:message => message)
		postToHaiku(message)
		defactivity "Haiku_post", "Haiku_Post"
		activity :Haiku_Post, "ハイクとTwitterに投稿しました"
		Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ''
        reload_haiku
	end
  end

  ########################################
  ##  Settings :: 設定画面
  ##
  settings "はてなハイク" do
    settings "投稿の設定(BASIC認証タイプ)" do
      input("はてなID",:hatena_id)
      input("APIパスワード",:hatena_api_pass)
    end
    multi "タイムラインに表示するハイクJSON URL", :haiku_url
  end

  ########################################
  ## Reader :: データソース出力の設定
  ##
  filter_extract_datasources do |datasources|
      datasources[:mikutter_haiku] = "はてなハイク"
      [datasources]
  end

  ########################################
  ## Reader :: スタート
  ##
  SerialThread.new {
    reload_haiku
  }

end
