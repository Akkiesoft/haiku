# -*- coding:utf-8 -*-

require 'rss'

Plugin.create(:mikutter_rss) do

  UserConfig[:rss_str]||="%t%n%n%d%n%n%l"
  
  def reload
    #更新を行う
    #ただし これだと複数のRSSが別々で並ぶので，完全な時系列にならなく見にくい可能性がある
    timeline(:mikutter_rss).clear
    (UserConfig[:rss_url]|| []).select{|m|!m.empty?}.each do |url|
      #パースに失敗する場合がある 失敗した場合は例外引っ掛けてスルー
      begin
        rss = RSS::Parser.parse(url,true)
      rescue
        timeline(:mikutter_rss) << Message.new(:message => "RSSのパースに失敗しました\n#{url}", :system => true)
      else
        #逆順にTLに入ってしまうので配列に代入してあとからTLに挿入
        #汚い
        n=rss.items.size
        i=0
        while i<n do
          #文章を整形
          #フォーマットはユーザーが設定できる
          title=rss.items[n-i-1].title.gsub(/<\/?[^>]*>/, "")
          description=rss.items[n-i-1].description.gsub(/<\/?[^>]*>/, "")
          if(UserConfig[:rss_rm_n])
            title=title.gsub(/\n+/,"")
            description=description.gsub(/\n+/,"")
          end
          link=rss.items[n-i-1].link
          str=UserConfig[:rss_str].gsub("%t",title).gsub("%d",description).gsub("%l",link).gsub("%n","\n")
          timeline(:mikutter_rss) << Message.new(:message => str, :system => true)
          i+=1
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
