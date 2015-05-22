module CampfireExport
  class Room
    include CampfireExport::IO
    attr_accessor :id, :name, :created_at, :last_update

    def initialize(room_xml)
      @id         = room_xml.xpath('id').text
      @name       = room_xml.xpath('name').text
      created_utc = DateTime.parse(room_xml.xpath('created-at').text)
      @created_at = Account.timezone.utc_to_local(created_utc)
    end

    def export(start_date=nil, end_date=nil)
      # Figure out how to do the least amount of work while still conforming
      # to the requester's boundary dates.
      find_last_update
      start_date.nil? ? date = created_at      : date = [start_date, created_at].max
      end_date.nil?   ? end_date = last_update : end_date = [end_date, last_update].min

      while date <= end_date
        transcript = Transcript.new(self, date)
        transcript.export

        # Ensure that we stay well below the 37signals API limits.
        sleep(1.0/10.0)
        date = date.next
      end
    end

    private
      def find_last_update
        begin
          last_message = Nokogiri::XML get("/room/#{id}/recent.xml?limit=1").body
          update_utc   = DateTime.parse(last_message.xpath('/messages/message[1]/created-at').text)
          @last_update = Account.timezone.utc_to_local(update_utc)
        rescue => e
          log(:error,
              "couldn't get last update in #{name} (defaulting to today)",
              e)
          @last_update = Date.new()
        end
      end
  end
end
