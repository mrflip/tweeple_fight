Fight = Struct.new(:topic_a, :topic_b) do
  BIEBER_UNIT     = 197071

  def self.from_hash hsh
    new(* hsh.values_at(*members))
  end

  def success?
    result_a.present? && result_b.present? && result_a['total'].present? && result_b['total'].present?
  end

  def result_a
    @result_a ||= infochimps_request 'social/network/tw/search/people_search', :q => topic_a
  end
  def result_b
    @result_b ||= infochimps_request 'social/network/tw/search/people_search', :q => topic_b
  end

  def winner
    [topic_a, topic_b][winner_idx]
  end
  def winner_idx
    (number_hits[0].to_i >= number_hits[1].to_i) ? 0 : 1
  end

  def number_hits
    # [10_0, 1970710 ] 
    [ result_a['total'], result_b['total'] ]
  end

  def micro_biebers
    number_hits.map{|hit| hit.is_a?(String) ? hit : (1_000_000.0 * hit.to_f / BIEBER_UNIT).round }
  end

  def bieberosity
    number_hits.map{|bb| 100 * Math.log10(bb) / Math.log10(BIEBER_UNIT) rescue -1 }
  end


protected
  
  def conn
    @conn = Faraday.new(:url => 'http://api.infochimps.com') do |builder|
      builder.request   :url_encoded
      builder.request   :json
      builder.response  :logger
      builder.adapter   :patron
    end
  end

  def infochimps_request path, params
    params = params.merge :_apikey => Settings.infochimps_apikey
    p params
    resp = conn.get do |req|
      req.url     path
      req[:timeout] = 0.5
      params.each{|k,v| req.params[k] = v }
    end
    begin
      results = JSON.parse(resp.body)
    rescue
      results = {}
    end
    results
  end

end

