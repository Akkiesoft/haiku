# -*- coding:utf-8 -*-

require 'rss'

Plugin.create(:mikutter_rss) do
  
  def reload
    #更新を行う
    #ただし これだと複数のRSSが別々で並ぶので，完全な時系列にならなく見にくい可能性がある
    timeline(:mikutter_rss).clear
    (UserConfig[:rss_url]|| []).select{|m|!m.empty?}.each do |url|
      rss = RSS::Parser.parse(url)
      rss.items.each{|item|
        timeline(:mikutter_rss) << Message.new(:message => "#{item.title.gsub(/<\/?[^>]*>/, "").gsub("\n\n","\n")}\n#{item.description.gsub(/<\/?[^>]*>/, "").gsub("\n\n","\n")}\n#{item.link}", :system => true)
      }
    end
  end

  btn = Gtk::Button.new('更新')
  tab(:mikutter_rss, '') do
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
  def onperiod(watch)
    reload
  end

  reload
  
  settings "mikutter rss" do
    multi "RSS URL", :rss_url
  end

end
