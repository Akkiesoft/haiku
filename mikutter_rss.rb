# -*- coding:utf-8 -*-

require 'rss'

Plugin.create(:mikutter_rss) do

  UserConfig[:rss_str]||="%t%n%n%d%n%n%l"
  
  def reload
    #User作ってるけどまだ反映されない 何故？
    user= User.new(:id => 1,:idname => "RSS_reader",:name => "RSSリーダー", :profile_image_url => "target.png")
    
    #更新を行う
    #ただし これだと複数のRSSが別々で並ぶので，完全な時系列にならなく見にくい可能性がある
    timeline(:mikutter_rss).clear
    (UserConfig[:rss_url]|| []).select{|m|!m.empty?}.each do |url|
      #パースに失敗する場合があるので例外
      begin
        rss = RSS::Parser.parse(url,true)
      rescue
        #例外の場合はエラーメッセージを流す
        timeline(:mikutter_rss) << Message.new(:message => "RSSのパースに失敗しました\n#{url}", :system => true, :user => user, :createdat => Time.now)
      else
        #逆順にTLに入ってしまうので後ろ側からTLに挿入
        #汚い 綺麗に書けないかな(eachの逆順みたいなのないかな)
        i=rss.items.size-1
        while 0<=i do
          #各要素を引っ張ってくる
          title=rss.items[i].title.gsub(/<\/?[^>]*>/, "")
          description=rss.items[i].description.gsub(/<\/?[^>]*>/, "")
          link=rss.items[i].link

          #改行を消す設定
          if(UserConfig[:rss_rm_n])
            title=title.gsub(/\n+/,"")
            description=description.gsub(/\n+/,"")
          end
          
          #フォーマットはユーザーが設定できる
          str=UserConfig[:rss_str].gsub("%t",title).gsub("%d",description).gsub("%l",link).gsub("%n","\n")
          
          #実際にtimelineにMessageを流す
          #systemがtrue以外だと落ちる
          #userが反映されない(mikutter_botの投稿になる)
          timeline(:mikutter_rss) << Message.new(:message => str, :system => true, :user => user, :createdat => Time.now)
          i-=1
        end
      end
    end
  end
  
  btn = Gtk::Button.new('更新')
  
  tab(:mikutter_rss, 'RSSリーダー') do
    set_icon File.expand_path(File.join(File.dirname(__FILE__), 'target.png'))
    shrink
    nativewidget Gtk::HBox.new(false, 0).closeup(btn)
    expand
    timeline :mikutter_rss
  end
  
  #更新ボタン
  btn.signal_connect('clicked'){ |elm|
    reload
  }
  
  #1分に1度 自動で更新
  on_period do
    if(UserConfig[:rss_auto])
      reload
    end
  end
  
  if(UserConfig[:rss_exec])
    reload
  end
  
  settings "mikutter rss" do
    boolean('起動時に更新する', :rss_exec)
    boolean('1分毎に自動更新を行う', :rss_auto)
    boolean('タイトルと説明から改行を消す', :rss_rm_n)
    input("表示文字列のフォーマット", :rss_str)
    multi "RSS URL", :rss_url
  end
  
end
