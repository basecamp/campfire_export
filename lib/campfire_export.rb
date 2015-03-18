#!/usr/bin/env ruby

# Portions copyright 2011 Marc Hedlund <marc@precipice.org>.
# Adapted from https://gist.github.com/821553 and ancestors.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# campfire_export.rb -- export Campfire transcripts and uploaded files.
#
# Since Campfire (www.campfirenow.com) doesn't provide an export feature,
# this script implements one via the Campfire API.

require 'rubygems'

require 'cgi'
require 'fileutils'
require 'httparty'
require 'nokogiri'
require 'retryable'
require 'time'
require 'yaml'

module CampfireExport
  module IO
    MAX_RETRIES = 5

    def api_url(path)
      "#{CampfireExport::Account.base_url}#{path}"
    end

    def get(path, params = {})
      url = api_url(path)

      response = Retryable.retryable(:tries => MAX_RETRIES) do |retries, exception|
        if retries > 0
          msg = "Attempt ##{retries} to fetch #{path} failed, " +
                "#{MAX_RETRIES - retries} attempts remaining."
          log :error, msg, exception
        end

        HTTParty.get(url, :query => params, :basic_auth =>
          {:username => CampfireExport::Account.api_token, :password => 'X'})
      end

      if response.code >= 400
        raise CampfireExport::Exception.new(url, response.message, response.code)
      end
      response
    end

    def zero_pad(number)
      "%02d" % number
    end

    # Requires that room and date be defined in the calling object.
    def export_dir
      "campfire/#{Account.subdomain}/#{room.name}/" +
        "#{date.year}/#{zero_pad(date.mon)}/#{zero_pad(date.day)}"
    end

    # Requires that room_name and date be defined in the calling object.
    def export_file(content, filename, mode='w')
      # Check to make sure we're writing into the target directory tree.
      true_path = File.expand_path(File.join(export_dir, filename))

      unless true_path.start_with?(File.expand_path(export_dir))
        raise CampfireExport::Exception.new("#{export_dir}/#{filename}",
          "can't export file to a directory higher than target directory; " +
          "expected: #{File.expand_path(export_dir)}, actual: #{true_path}.")
      end

      if File.exists?("#{export_dir}/#{filename}")
        log(:error, "#{export_dir}/#{filename} failed: file already exists")
      else
        open("#{export_dir}/#{filename}", mode) do |file|
          file.write content
        end
      end
    end

    def verify_export(filename, expected_size)
      full_path = "#{export_dir}/#{filename}"
      unless File.exists?(full_path)
        raise CampfireExport::Exception.new(full_path,
          "file should have been exported but did not make it to disk")
      end
      unless File.size(full_path) == expected_size
        raise CampfireExport::Exception.new(full_path,
          "exported file exists but is not the right size " +
          "(expected: #{expected_size}, actual: #{File.size(full_path)})")
      end
    end

    def log(level, message, exception=nil)
      case level
      when :error
        short_error = ["*** Error: #{message}", exception].compact.join(": ")
        $stderr.puts short_error
        open("campfire/export_errors.txt", 'a') do |log|
          log.write short_error
          unless exception.nil?
            log.write %Q{\n\t#{exception.backtrace.join("\n\t")}}
          end
          log.write "\n"
        end
      else
        print message
        $stdout.flush
      end
    end
  end

end

require 'campfire_export/timezone'

require 'campfire_export/account'
require 'campfire_export/exception'
require 'campfire_export/message'
require 'campfire_export/room'
require 'campfire_export/transcript'
require 'campfire_export/upload'
require 'campfire_export/version'
