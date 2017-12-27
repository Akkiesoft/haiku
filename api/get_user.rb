# -*- coding: utf-8 -*-

module Plugin::Haiku

  def get_user(hatena_id, hatena_api_pass)
    res = Net::HTTP.start("h.hatena.ne.jp") { |http|
      req = Net::HTTP::Get.new("/api/statuses/user_timeline.json")
      req.basic_auth(hatena_id, hatena_api_pass)
      http.request(req)
    }
  end

end