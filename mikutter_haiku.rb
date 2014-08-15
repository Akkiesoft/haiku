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
  def reload_haiku
    (UserConfig[:haiku_url]|| []).select{|m|!m.empty?}.each do |url|
      begin
        now = Time.now.to_i
        if @@haiku_lastupdate == 0 then
          timeline = "&reftime=-#{now},0"
        else
          timeline = "&reftime=+#{@@haiku_lastupdate},0"
        end
        uri = URI.parse("#{url}?body_formats=haiku#{timeline}")
        json = Net::HTTP.get(uri)
        items = JSON.parse(json)
      rescue => ee
        # パースに失敗した場合は例外引っ掛けてスルー
        activity :mikutter_haiku, "JSONのパースに失敗しました\n#{url}?body_formats=haiku\n#{ee}"
      else
        parse(items)
        # 最後に実行した時間を記録
        @@haiku_lastupdate = now
        if (UserConfig[:haiku_auto]) then
          Reserver.new(60) {
            reload_haiku
          }
        end
      end
    end
  end

  ########################################
  ## Reader :: パース処理
  ##
  def parse(items)
    items.each do |item|
      msgs = Messages.new
      keyword	= item['target']['title']
      body		= item['haiku_text']
      link		= item['link']
      source	= item['source']
      time		= Time.parse(item['created_at']).localtime

      # はてなフォトライフ
      sintaxes = body.scan(/f:id:([-_a-zA-Z0-9]+):([0-9]{8})([0-9]{6})(j|g|p|f)?(:image|:movie)?/i) {|match|
        foto_id			= match[0];
        foto_initial	= foto_id.slice(0, 1);
        foto_date		= match[1];
        foto_time		= match[2];
        foto_type		= (defined?(match[3])) ? match[3] : '';
        foto_mode		= (defined?(match[4])) ? match[4] : '';
        foto_ext		= 'jpg';
        foto_ext		= 'gif' if foto_type == 'g'
        foto_ext		= 'png' if foto_type == 'p'
        foto_org		= "f:id:#{foto_id}:#{foto_date}#{foto_time}"
        foto_org		+= foto_type if foto_type
        foto_org		+= foto_mode if foto_mode
        foto_img		= "http://cdn-ak.f.st-hatena.com/images/fotolife/#{foto_initial}/#{foto_id}/#{foto_date}/#{foto_date}#{foto_time}.#{foto_ext}"
        foto_link		= "http://f.hatena.ne.jp/#{foto_id}/#{foto_date}#{foto_time}"
        if foto_type == "f" && foto_mode == ":movie" then
          body = body.sub("#{foto_org}", "#{foto_link}")
        else
          body = body.sub("#{foto_org}", "#{foto_img}")
        end
      }

      # Entitiesの作成
      message_head = "#{item['user']['screen_name']} (Permalink)\n\n"
      message_text = "#{message_head}<#{keyword}>\n#{body}"
      entities = {
        urls: [
          {
            url: item['user']['screen_name'],
            expanded_url: item['user']['url'],
            display_url: item['user']['screen_name'],
            indices: [0, message_head.length]
          },
          {
            url: "(Permalink)",
            expanded_url: link,
            display_url: "(Permalink)",
            indices: [0, message_head.length]
          },
          {
            url: "<#{keyword}>",
            expanded_url: "http://h.hatena.ne.jp/target?word=#{keyword}",
            display_url: "<#{keyword}>",
            indices: [message_head.length, message_head.length + "<#{keyword}>".length + 2]
          },
        ],
        symbols: [],
        hashtags: [],
        user_mentions: []
      }

      # URL記法対応
      sintaxes = body.split('[')
      if sintaxes[0] != body then
        sintaxes.each do |sintax|
          pos = sintax.index(']')
          if pos.nil? then
            next		# これは記法ではない
          end
          sintax = sintax.slice(0, pos);
          sintaxUrl = sintax.gsub(/(https?:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)\:title=(.+)/, "\\1");
          sintaxTitle = sintax.gsub(/(https?:\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)\:title=(.+)/, "\\2");
          entities[:urls].concat([{
            url: "[#{sintax}]",
            expanded_url: sintaxUrl,
            display_url: sintaxTitle,
            indices: [0, message_text.length]	# てぬき
          }])
        end
      end

      user = User.new({
        # :idはハイクに数値IDが存在しないのでハッシュでごまかす
        :id					=> "#{item['user']['id']}".hash,
        :idname				=> item['user']['screen_name'],
        :name				=> item['user']['name'],
        :nickname			=> item['user']['screen_name'],
        :profile_image_url	=> item['user']['profile_image_url'],
        :url				=> item['user']['url'],
        :detail				=> ""
      })
      msgs << Message.new({
        :id			=> time.to_i,
        :message	=> message_text,
        :user		=> user,
        :source		=> source,
        :created	=> time,
        :entities	=> entities
      })
      Plugin.call(:extract_receive_message, :mikutter_haiku, msgs)
    end
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
    settings "投稿の設定(BASIC認証タイプじゃ)" do
      input("はてなID",:hatena_id)
      input("APIパスワード",:hatena_api_pass)
    end
    settings "タイムライン" do
      boolean('1分毎に自動更新を行う', :haiku_auto)
      multi "ハイクJSON URL", :haiku_url
    end
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
