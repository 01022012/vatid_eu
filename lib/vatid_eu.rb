require 'addressable/uri'
require 'xmlsimple'
require 'net/http'

module VatidEu

  extend self

  BASE_URL        = 'http://vatid.eu/check/'
  DEFAULT_TIMEOUT = 10
  VALID_COUNTRIES = ['AT','BE','BG','CY','CZ','DK','EE','FI','FR','DE','EL','HU','IE','IT','LV','LT','LU','MT','NL','PL','PT','RO','SK','SI','ES','SE','GB']

  @@requester = nil
  def requester=(data)
    @@requester = data
  end
  def requester
    @@requester
  end

  @@timeout = nil
  def timeout=(new_timeout)
    @@timeout = new_timeout
  end
  def timeout
    @@timeout || DEFAULT_TIMEOUT
  end

  def valid?(country_or_id, id=nil)
    if id.nil?
      country = country_or_id[0..1].upcase
      id      = country_or_id[2..-1]
    else
      country = country_or_id.upcase
    end
    return false  unless VALID_COUNTRIES.include?(country)
    response = check(country, id)
    if response['error']
      raise response['error'].first['text'].first
    else
      if response['response'].first['valid'].first == 'true'
        if requester
          {
            :request_identifier => response['response'].first['request-identifier'].first,
            :request_date       => response['response'].first['request-date'].first
          }
        else
          true
        end
      else
        false
      end
    end
  end



 private

  def check(country, id)
    url = Addressable::URI.parse BASE_URL
    url.path += "#{country}/"
    url.path += "#{id}/"
    url.path += "#{requester[:country]}/#{requester[:id]}" if requester
    body = get_url(url)
    XmlSimple.xml_in(body, { 'KeepRoot' => true })
  end

  def get_url(url)
    http = Net::HTTP.new(url.host, 80)
    http.read_timeout = timeout
    response = http.get url.request_uri, 'User-agent' => 'vatid_eu ruby client'
    case response
    when Net::HTTPSuccess, Net::HTTPOK
      response.body
    else
      response.error!
    end
  end

end