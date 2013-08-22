namespace :tmp do
  namespace :sessions do
    # desc "Clears all files in tmp/sessions"
    task :clear => :environment do
      FileUtils.rm(Dir['tmp/sessions/[^.]*'])
      Rails.application.config.session_store.clear
    end
  end

  namespace :cache do
    # desc "Clears all files and directories in tmp/cache"
    task :clear => :environment do
      FileUtils.rm_rf(Dir['tmp/cache/[^.]*'])
      Rails.cache.clear
    end
  end
end
