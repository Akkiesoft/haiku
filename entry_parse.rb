# -*- coding:utf-8 -*-

module Plugin::Haiku

  def parse(items)
    messages = items.each do |item|
      id		= item['id']
      keyword	= item['target']['title']
      keyword_url = "http://h.hatena.ne.jp/target?word=" + URI.encode_www_form_component(keyword)
      body		= "<#{keyword}>\n#{item['haiku_text']}"
      link		= item['link']
      source	= item['source']
      time		= Time.parse(item['created_at']).localtime

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

      message = Plugin::Haiku::Entry.new({
        id: id,
        message: body,
        user: user,
        link: link,
        source: source,
        created: time
      })

      # キーワードのEntity作成
      message.entity.add(
        slug: :urls,
        url: "",
        open: keyword_url,
        face: "<#{keyword}>",
        range: 0...("<#{keyword}>".length))

      # はてなフォトライフ記法対応
      body.gsub(/f:id:([-_a-zA-Z0-9]+):([0-9]{8})([0-9]{6})(j|g|p|f)?(:image|:movie)?/i) do
        match = Regexp.last_match
        pos = match.begin(0)
        url = "http://f.hatena.ne.jp/#{match[1]}/#{match[2]}#{match[3]}"
        ext = ""
        case match[4]
        when "j" then
          ext = "jpg"
        when "g" then
          ext = "gif"
        when "p" then
          ext = "png"
        end
        expanded_url = ext ? "https://cdn-ak.f.st-hatena.com/images/fotolife/#{match[1][0]}/#{match[1]}/#{match[2]}/#{match[2]}#{match[3]}.#{ext}" : url
        message.entity.add(
          slug: :hatenafotolife,
          open: url,
          url: url,
          expanded_url: expanded_url,
          face: match[0],
          range: pos...(pos + match.to_s.size))
      end

      # URL記法対応
      body.gsub(/\[(https?:\/\/[-_.!~*\'\(\)a-zA-Z0-9;\/?:\@&=+\$,%#]+)\:title=(.+)\]/) do
        match = Regexp.last_match
        pos = match.begin(0)
        message.entity.add(
          slug: :urls,
          open: match[1],
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
