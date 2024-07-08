require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"

if Rails.env == 'test'
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"),
  }
end


Shrine.plugin :activerecord
Shrine.plugin :restore_cached_data
Shrine.plugin :cached_attachment_data
Shrine.plugin :derivatives, create_on_promote: true
Shrine.plugin :validation_helpers
