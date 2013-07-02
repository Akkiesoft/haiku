# -*- coding:utf-8 -*-

require 'rss'

Plugin.create(:mikutter_rss) do

  def reload
    #更新を行う
    #ただし これだと複数のRSSが別々で並ぶので，完全な時系列にならなく見にくい可能性がある
    timeline(:mikutter_rss).clear
    (UserConfig[:rss_url]|| []).select{|m|!m.empty?}.each do |url|
      rss = RSS::Parser.parse(url)
      #逆順にTLに入ってしまうので配列に代入してあとからTLに挿入
      #汚い
      n=rss.items.size
      i=0
      while i<n do 
        timeline(:mikutter_rss) << Message.new(:message => "#{rss.items[n-i-1].title.gsub(/<\/?[^>]*>/, "")}\n#{rss.items[n-i-1].description.gsub(/<\/?[^>]*>/, "")}\n#{rss.items[n-i-1].link}", :system => true)
        i+=1
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
  
  reload
  
  settings "mikutter rss" do
    boolean('1分毎に自動更新を行う', :rss_auto)
    multi "RSS URL", :rss_url
  end
  
end
