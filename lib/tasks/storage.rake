namespace :storage do
  desc "Purge unattached Active Storage blobs older than 2 days"
  task purge_unattached: :environment do
    count = 0
    ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago).find_each do |blob|
      blob.purge
      count += 1
    end
    puts "Purged #{count} unattached blob(s)"
  end
end
