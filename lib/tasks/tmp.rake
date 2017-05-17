namespace :tmp do
  namespace :cache do
    task clear: :environment do
      FileUtils.rm_rf(Dir['tmp/cache/[^.]*'])
      Rails.cache.clear
    end
  end
end
