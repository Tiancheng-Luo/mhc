require "yaml"
require "uri"

################################################################
## load config

module Mhc
  class Builder
    def initialize(mhc_config)
      @mhc_config    = mhc_config
      @sync_channels = @mhc_config.sync_channels
      @calendars     = @mhc_config.calendars
    end

    def calendar(calname)
      calendar = @calendars[calname]
      raise "calendar '#{calname}' not found" unless calendar

      case calendar.type
      when "caldav"
        db = Mhc::CalDav::Client.new(calendar.url).set_basic_auth(calendar.user, calendar.password)
      when "directory"
        db = Mhc::CalDav::Cache.new(calendar.top_directory)
      when "lastnote"
        db = Mhc::LastNote::Client.new(calendar.name)
      when "mhc"
        db = Mhc::Calendar.new(Mhc::DataStore.new)
      end
      return db
    end

    def sync_driver(channel_name, strategy = :sync)
      channel = @sync_channels[channel_name]
      raise "sync channel '#{channel_name}' not found" unless channel

      directory1, directory2 = cache_directory_pair(channel)
      strategy ||= channel.strategy.to_s.downcase.to_sym

      db1 = calendar_with_etag_track(calendar(channel.calendar1), directory1)
      db2 = calendar_with_etag_track(calendar(channel.calendar2), directory2)

      return Mhc::Sync::Driver.new(db1, db2, strategy)
    end

    ################################################################
    private

    def calendar_with_etag_track(calendar, etag_store_directory)
      etag_db = Mhc::EtagStore.new(etag_store_directory)
      return Mhc::Sync::StatusManager.new(calendar, etag_db)
    end

    def cache_directory_pair(channel, top_directory = "#{ENV['HOME']}/tmp/mhc-etag-cache")
      base = File.expand_path(channel.name, top_directory)

      directory1 = File.join(base, channel.calendar1)
      directory2 = File.join(base, channel.calendar2)

      FileUtils.mkdir_p(directory1) unless FileTest.exist?(directory1)
      FileUtils.mkdir_p(directory2) unless FileTest.exist?(directory2)

      return [directory1, directory2]
    end
  end # class Builder
end # module Mhc
