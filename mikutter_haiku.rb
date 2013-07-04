# -*- coding:utf-8 -*-

require 'net/http'
require 'uri'
require 'json'
require 'time'

Plugin.create(:mikutter_haiku) do
  
  def reload
    #更新を行う
    timeline(:mikutter_haiku).clear
    (UserConfig[:haiku_url]|| []).select{|m|!m.empty?}.each do |url|
      #パースに失敗する場合がある 失敗した場合は例外引っ掛けてスルー
      begin
        uri = URI.parse("#{url}?body_formats=haiku")
        json = Net::HTTP.get(uri)
        items = JSON.parse(json)
      rescue => ee
        timeline(:mikutter_haiku) << Message.new({
          :message => "JSONのパースに失敗しました\n#{url}?body_formats=haiku\n#{ee}",
          :system => true
        })
      else
        #逆順にTLに入ってしまうので配列に代入してあとからTLに挿入
        #汚い
        n=items.size
        i=0
        allcnt=1
        while i<n do
          #文章を整形
          keyword=items[i]['keyword']
          body   =items[i]['haiku_text']
          link   =items[i]['link']
          source =items[i]['source']
          user = User.new({
            :id => allcnt,
            :idname => items[i]['user']['screen_name'],
            :name => items[i]['user']['name'],
            :profile_image_url => items[i]['user']['profile_image_url'],
            :url => items[i]['user']['url']
          })
          time = Time.parse(items[i]['created_at'])
          timeline(:mikutter_haiku) << Message.new({
            :id => allcnt,
            :message => "<#{keyword}>\n#{body}\n#{link}",
            :user => user,
            :source => source,
            :created => time
          })
          i+=1
          allcnt+=1
        end
      end
    end
  end
  
  btn = Gtk::Button.new('更新')
  
  tab(:mikutter_haiku, 'はてなハイク') do
    set_icon File.expand_path(File.join(File.dirname(__FILE__), 'logo.png'))
    shrink
    nativewidget Gtk::HBox.new(false, 0).closeup(btn)
    expand
    timeline :mikutter_haiku
  end
  
  #更新ボタン
  btn.signal_connect('clicked'){ |elm|
    reload
  }
  
  #1分に1度 自動で更新
  on_period do
    if(UserConfig[:haiku_auto])
      reload
    end
  end
  
  if(UserConfig[:haiku_exec])
    reload
  end
  
  settings "mikutter haiku" do
    boolean('起動時に更新する', :haiku_exec)
    boolean('1分毎に自動更新を行う', :haiku_auto)
    multi "ハイクJSON URL", :haiku_url
  end
  
end
