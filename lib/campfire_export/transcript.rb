module CampfireExport
  class Transcript
    include CampfireExport::IO
    attr_accessor :room, :date, :xml, :messages

    def initialize(room, date)
      @room     = room
      @date     = date
    end

    def transcript_path
      "/room/#{room.id}/transcript/#{date.year}/#{date.mon}/#{date.mday}"
    end

    def export
      begin
        log(:info, "#{export_dir} ... ")
        @xml = Nokogiri::XML get("#{transcript_path}.xml").body
      rescue => e
        log(:error, "transcript export for #{export_dir} failed", e)
      else
        @messages = xml.xpath('/messages/message').map do |message|
          CampfireExport::Message.new(message, room, date)
        end

        # Only export transcripts that contain at least one message.
        if messages.length > 0
          log(:info, "exporting transcripts\n")
          begin
            FileUtils.mkdir_p export_dir
          rescue => e
            log(:error, "Unable to create #{export_dir}", e)
          else
            export_xml
            export_plaintext
            export_html
            export_uploads
          end
        else
          log(:info, "no messages\n")
        end
      end
    end

    def export_xml
      begin
        export_file(xml, 'transcript.xml')
        verify_export('transcript.xml', xml.to_s.bytesize)
      rescue => e
        log(:error, "XML transcript export for #{export_dir} failed", e)
      end
    end

    def export_plaintext
      begin
        date_header = date.strftime('%A, %B %e, %Y').squeeze(" ")
        plaintext = "#{CampfireExport::Account.subdomain.upcase} CAMPFIRE\n"
        plaintext << "#{room.name}: #{date_header}\n\n"
        messages.each {|message| plaintext << message.to_s }
        export_file(plaintext, 'transcript.txt')
        verify_export('transcript.txt', plaintext.bytesize)
      rescue => e
        log(:error, "Plaintext transcript export for #{export_dir} failed", e)
      end
    end

    def export_html
      begin
        transcript_html = get(transcript_path).to_s

        # Make the upload links in the transcript clickable from the exported
        # directory layout.
        transcript_html.gsub!(%Q{href="/room/#{room.id}/uploads/},
                              %Q{href="uploads/})
        # Likewise, make the image thumbnails embeddable from the exported
        # directory layout.
        transcript_html.gsub!(%Q{src="/room/#{room.id}/thumb/},
                              %Q{src="thumbs/})

        export_file(transcript_html, 'transcript.html')
        verify_export('transcript.html', transcript_html.bytesize)
      rescue => e
        log(:error, "HTML transcript export for #{export_dir} failed", e)
      end
    end

    def export_uploads
      messages.each do |message|
        if message.is_upload?
          begin
            message.upload.export
          rescue => e
            path = "#{message.upload.export_dir}/#{message.upload.filename}"
            log(:error, "Upload export for #{path} failed", e)
          end
        end
      end
    end
  end
end
