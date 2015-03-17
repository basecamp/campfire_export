module CampfireExport
  class Upload
    include CampfireExport::IO
    attr_accessor :message, :room, :date, :id, :filename, :content_type, :byte_size, :full_url

    def initialize(message)
      @message = message
      @room = message.room
      @date = message.date
      @deleted = false
    end

    def deleted?
      @deleted
    end

    def is_image?
      content_type.start_with?("image/")
    end

    def upload_dir
      "uploads/#{id}"
    end

    # Image thumbnails are used to inline image uploads in HTML transcripts.
    def thumb_dir
      "thumbs/#{id}"
    end

    def export
      begin
        log(:info, "    #{message.body} ... ")

        # Get the upload object corresponding to this message.
        upload_path = "/room/#{room.id}/messages/#{message.id}/upload.xml"
        upload = Nokogiri::XML get(upload_path).body

        # Get the upload itself and export it.
        @id = upload.xpath('/upload/id').text
        @byte_size = upload.xpath('/upload/byte-size').text.to_i
        @content_type = upload.xpath('/upload/content-type').text
        @filename = upload.xpath('/upload/name').text
        @full_url = upload.xpath('/upload/full-url').text

        export_content(upload_dir)
        export_content(thumb_dir, path_component="thumb/#{id}", verify=false) if is_image?

        log(:info, "ok\n")
      rescue CampfireExport::Exception => e
        if e.code == 404
          # If the upload 404s, that should mean it was subsequently deleted.
          @deleted = true
          log(:info, "deleted\n")
        else
          raise e
        end
      end
    end

    def export_content(content_dir, path_component=nil, verify=true)
      # If the export directory name is different than the URL path component,
      # the caller can define the path_component separately.
      path_component ||= content_dir

      # Write uploads to a subdirectory, using the upload ID as a directory
      # name to avoid overwriting multiple uploads of the same file within
      # the same day (for instance, if 'Picture 1.png' is uploaded twice
      # in a day, this will preserve both copies). This path pattern also
      # matches the tail of the upload path in the HTML transcript, making
      # it easier to make downloads functional from the HTML transcripts.
      content_path = "/room/#{room.id}/#{path_component}/#{CGI.escape(filename)}"
      content = get(content_path).body
      FileUtils.mkdir_p(File.join(export_dir, content_dir))
      export_file(content, "#{content_dir}/#{filename}", 'wb')
      verify_export("#{content_dir}/#{filename}", byte_size) if verify
    end
  end
end
