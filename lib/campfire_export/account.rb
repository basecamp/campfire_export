module CampfireExport
  class Account
    include CampfireExport::IO
    include CampfireExport::TimeZone

    @subdomain = ""
    @api_token = ""
    @base_url  = ""
    @timezone  = nil

    class << self
      attr_accessor :subdomain, :api_token, :base_url, :timezone
    end

    def initialize(subdomain, api_token)
      Account.subdomain = subdomain
      Account.api_token = api_token
      Account.base_url  = "https://#{subdomain}.campfirenow.com"
    end

    def find_timezone
      settings = Nokogiri::XML get('/account.xml').body
      selected_zone = settings.xpath('/account/time-zone')
      Account.timezone = find_tzinfo(selected_zone.text)
    end

    def rooms
      doc = Nokogiri::XML get('/rooms.xml').body
      doc.xpath('/rooms/room').map {|room_xml| Room.new(room_xml) }
    end
  end
end
