# -*- coding: utf-8 -*-

module Plugin::Haiku

  def get_user(hatena_id, hatena_api_pass, count = 20)
    count = "?count=#{count}"
    res = Net::HTTP.start("h.hatena.ne.jp") { |http|
      req = Net::HTTP::Get.new("/api/statuses/user_timeline.json#{count}")
      req.basic_auth(hatena_id, hatena_api_pass)
      http.request(req)
    }
    JSON.parse(res.body)[0]["user"]
  end

  module_function :get_user
end
