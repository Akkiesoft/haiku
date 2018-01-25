# -*- coding:utf-8 -*-

module Plugin::Haiku

  def parse(items)
    messages = items.each do |item|
      id		= item['id']
      keyword	= item['target']['title']
      keyword_url = URI.encode_www_form_component(keyword)
      body		= item['haiku_text']
      link		= item['link']
      source	= item['source']
      time		= Time.parse(item['created_at']).localtime

      # はてなフォトライフ
      body.scan(/f:id:([-_a-zA-Z0-9]+):([0-9]{8})([0-9]{6})(j|g|p|f)?(:image|:movie)?/i) {
        match = Regexp.last_match
        body = body.sub(
          "#{match.to_s}",
          "http://f.hatena.ne.jp/#{match[1]}/#{match[2]}#{match[3]}"
        )
      }

      user = Plugin::Haiku::User.new({
        # :idはハイクに数値IDが存在しないのでハッシュでごまかす
        id: "#{item['user']['id']}".hash,
        idname: item['user']['screen_name'],
        name: item['user']['name'],
        nickname: item['user']['screen_name'],
        profile_image_url: item['user']['profile_image_url'],
        link: item['user']['url'],
        detail: ""
      })

      message_text = "<#{keyword}>\n#{body}"

      message = Plugin::Haiku::Entry.new({
        id: id,
        message: message_text,
        user: user,
        link: link,
        source: source,
        created: time
      })

      # Entitiesの作成
      message.entity.add(slug: :urls,
                         url: "http://h.hatena.ne.jp/target?word=#{keyword_url}",
                         face: "<#{keyword}>",
                         range: 0...("<#{keyword}>".length))

      # URL記法対応
      message_text.gsub(/\[(https?:\/\/[-_.!~*\'\(\)a-zA-Z0-9;\/?:\@&=+\$,%#]+)\:title=(.+)\]/) do
        match = Regexp.last_match
        pos = match.begin(0)
        message.entity.add(slug: :urls,
                           url: match[1],
                           face: match[2],
                           range: pos...(pos + match.to_s.size))
      end

    #  msgs << message
      Plugin.call(:extract_receive_message, :haiku, [message])
    end
    return Time.parse(items[0]['created_at']).to_i
  end

  module_function :parse
end
