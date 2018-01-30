# -*- coding:utf-8 -*-
################################################################################
##  haiku
##    https://github.com/Akkiesoft/haiku
##

## haikuはご覧のスポンサーでお送りします
require 'net/http'
require 'uri'
require 'json'
require 'time'

require_relative 'model'
require_relative 'entry_parse'
require_relative 'api/get_user'
require_relative 'api/post'
require_relative 'api/destroy'

## START
Plugin.create(:haiku) do
  defactivity "haiku", "はてなハイク"

  ########################################
  ## Reader :: リロード処理
  ##
# TODO:
# JSONごとにlastupdateを持たせるようにする
# {["url":"<URL>", "lastupdate":"<time>"],...}みたいなのを作って管理？
  def reload_haiku(haiku_lastupdate, mode)
    (UserConfig[:haiku_url]|| []).select{|m|!m.empty?}.each do |url|
      begin
        now = Time.now.to_i
        timeline = (haiku_lastupdate) ? "+#{haiku_lastupdate},1" : "-#{now},0"
        json = Net::HTTP.get(
          URI.parse("#{url}?body_formats=haiku&reftime=#{timeline}"))
#DEBUG
#        json = File.open("/Users/akkie/public_html/test.json").read
        items = JSON.parse(json)
      rescue => ee
        # パースに失敗した場合は例外引っ掛けてスルー
        activity :haiku, "JSONのパースに失敗しました\n#{url}?body_formats=haiku\n#{ee}"
      else
        # 最後に実行した時間を記録
        haiku_lastupdate = Plugin::Haiku::parse(items) if items.length
      end
    end
    # mode==1だったらまた1分後にリロード
    Reserver.new(60) { reload_haiku(haiku_lastupdate, 1) } if mode
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
		postToHaiku(message, UserConfig[:hatena_id], UserConfig[:hatena_api_pass])
		activity :haiku, "ハイクに投稿しました"
		Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ''
	end
  end

  defspell(:compose, :haiku,
           condition: -> lambda{ true }
          ) do | haiku, body: |
    Plugin::Haiku::postToHaiku(
      body, haiku.hatena_id, haiku.api_passwd
    )
  end

  defspell(:compose, :haiku, :hatenahaiku_entry,
           condition: -> (haiku, entry){ true }
          ) do | haiku, entry, body:|
    Plugin::Haiku::postToHaiku(
      body, haiku.hatena_id, haiku.api_passwd, 
    )
  end

  defspell(:destroy, :haiku, :hatenahaiku_entry,
           condition: ->(haiku, entry){ entry.from_me?(haiku) }
          ) do |haiku, entry|
    Plugin::Haiku::destroyEntry(
      entry, haiku.hatena_id, haiku.api_passwd, 
    )
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
      datasources[:haiku] = "はてなハイク"
      [datasources]
  end

  ########################################
  ## Reader :: スタート
  ##
  SerialThread.new { reload_haiku(nil, 1) }

  # World
  world_setting(:haiku, 'はてなハイク') do
    label "ログイン情報を入力してください"
    input "はてなID", :hatena_id
    inputpass "APIパスワード", :api_passwd
    label "APIパスワードは以下のURLで確認できます"
    link "http://h.hatena.ne.jp/setting/devices"
    result = await_input

    world = await(Plugin::Haiku::World.build(result))
    label "このアカウントでログインしますか？"
    link world.user
    world
  end

end
