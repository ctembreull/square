namespace :r2 do
  desc "Export seed data and upload to R2 bucket (production only)"
  task push: :environment do
    # Safety gate: Only allow in production on Fly.io
    unless ENV["FLY_APP_NAME"].present? && Rails.env.production?
      abort "ERROR: r2:push can only be run in production on Fly.io. " \
            "This prevents accidentally overwriting canonical production data from dev/staging."
    end

    puts "Starting R2 backup..."

    # Run all export tasks to generate fresh YAML files
    puts "\n1. Exporting data to YAML files..."
    Rake::Task["structure:export"].invoke
    Rake::Task["seeds:export"].invoke
    Rake::Task["players:export"].invoke
    Rake::Task["affiliations:export"].invoke

    # Initialize S3 client (R2 is S3-compatible)
    require 'aws-sdk-s3'
    s3 = Aws::S3::Client.new(
      region: 'auto',
      endpoint: ENV['R2_ENDPOINT_URL'],
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY']
    )

    bucket = ENV['R2_BUCKET_NAME']
    files = [
      { local: 'db/seeds/structure.yml', remote: 'seeds/structure.yml' },
      { local: 'db/seeds/teams.yml', remote: 'seeds/teams.yml' },
      { local: 'db/seeds/players.yml', remote: 'seeds/players.yml' },
      { local: 'db/seeds/affiliations.yml', remote: 'seeds/affiliations.yml' }
    ]

    # Upload each YAML file to R2
    puts "\n2. Uploading YAML files to R2..."
    files.each do |file|
      local_path = Rails.root.join(file[:local])
      unless File.exist?(local_path)
        puts "  ⚠  Skipping #{file[:remote]} (file not found)"
        next
      end

      content = File.read(local_path)
      s3.put_object(
        bucket: bucket,
        key: file[:remote],
        body: content,
        content_type: 'application/x-yaml'
      )
      file_size = (content.bytesize / 1024.0).round(1)
      puts "  ✓ Uploaded #{file[:remote]} (#{file_size} KB)"
    end

    # Create and upload timestamp metadata
    metadata = {
      synced_at: Time.current.iso8601,
      app_name: ENV['FLY_APP_NAME'],
      files: files.map { |f| f[:remote].split('/').last }
    }

    s3.put_object(
      bucket: bucket,
      key: 'seeds/timestamp.json',
      body: metadata.to_json,
      content_type: 'application/json'
    )
    puts "  ✓ Uploaded seeds/timestamp.json"

    # Future: Log to ActivityLog when that feature is implemented
    # ActivityLog.create!(
    #   action: "r2_push",
    #   record_type: "System",
    #   metadata: metadata.to_json
    # )

    puts "\n✅ Backup complete! Pushed #{files.count} files to R2 at #{metadata[:synced_at]}"
  end

  desc "Download seed data from R2 bucket"
  task pull: :environment do
    puts "Pulling seed data from R2..."

    # Initialize S3 client (R2 is S3-compatible)
    require 'aws-sdk-s3'
    s3 = Aws::S3::Client.new(
      region: 'auto',
      endpoint: ENV['R2_ENDPOINT_URL'],
      access_key_id: ENV['R2_ACCESS_KEY_ID'],
      secret_access_key: ENV['R2_SECRET_ACCESS_KEY']
    )

    bucket = ENV['R2_BUCKET_NAME']
    files = [
      { local: 'db/seeds/structure.yml', remote: 'seeds/structure.yml' },
      { local: 'db/seeds/teams.yml', remote: 'seeds/teams.yml' },
      { local: 'db/seeds/players.yml', remote: 'seeds/players.yml' },
      { local: 'db/seeds/affiliations.yml', remote: 'seeds/affiliations.yml' }
    ]

    # Ensure seeds directory exists
    FileUtils.mkdir_p(Rails.root.join('db', 'seeds'))

    # Download each YAML file from R2
    downloaded = 0
    files.each do |file|
      local_path = Rails.root.join(file[:local])

      begin
        resp = s3.get_object(bucket: bucket, key: file[:remote])
        File.write(local_path, resp.body.read)
        file_size = (File.size(local_path) / 1024.0).round(1)
        puts "  ✓ Downloaded #{file[:remote]} (#{file_size} KB)"
        downloaded += 1
      rescue Aws::S3::Errors::NoSuchKey
        puts "  ⚠  Skipped #{file[:remote]} (not found in R2)"
      end
    end

    # Download and display timestamp metadata
    begin
      resp = s3.get_object(bucket: bucket, key: 'seeds/timestamp.json')
      metadata = JSON.parse(resp.body.read)
      puts "\n📅 Last synced: #{metadata['synced_at']} from #{metadata['app_name']}"
    rescue Aws::S3::Errors::NoSuchKey
      puts "\n⚠  No timestamp metadata found"
    end

    puts "\n✅ Pull complete! Downloaded #{downloaded} files from R2"
    puts "\nNext steps:"
    puts "  rake structure:import     # Import leagues and conferences"
    puts "  rake seeds:import         # Import teams, colors, and styles"
    puts "  rake players:import       # Import players"
    puts "  rake affiliations:import  # Import team affiliations"
  end

  desc "Preview what would be uploaded to R2 (dry run)"
  task push_preview: :environment do
    # Safety gate: Same as push
    unless ENV["FLY_APP_NAME"].present? && Rails.env.production?
      abort "ERROR: r2:push_preview can only be run in production on Fly.io. " \
            "This check ensures preview matches what push would actually do."
    end

    puts "R2 Push Preview (dry run - no actual upload)\n\n"

    bucket = ENV['R2_BUCKET_NAME']
    files = [
      { local: 'db/seeds/structure.yml', remote: 'seeds/structure.yml' },
      { local: 'db/seeds/teams.yml', remote: 'seeds/teams.yml' },
      { local: 'db/seeds/players.yml', remote: 'seeds/players.yml' },
      { local: 'db/seeds/affiliations.yml', remote: 'seeds/affiliations.yml' }
    ]

    puts "Would upload to bucket: #{bucket}\n\n"
    puts "Files that would be uploaded:"

    total_size = 0
    files.each do |file|
      local_path = Rails.root.join(file[:local])
      if File.exist?(local_path)
        file_size = File.size(local_path)
        total_size += file_size
        puts "  #{file[:remote]}"
        puts "    Source: #{file[:local]}"
        puts "    Size:   #{(file_size / 1024.0).round(1)} KB"
      else
        puts "  #{file[:remote]} (MISSING - would be skipped)"
      end
      puts
    end

    puts "Total size: #{(total_size / 1024.0).round(1)} KB"
    puts "\nRun 'rake r2:push' to actually upload these files."
  end
end
