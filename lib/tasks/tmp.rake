namespace :tmp do
  namespace :sessions do
    task :clear => :environment do
      FileUtils.rm(Dir['tmp/sessions/[^.]*'])
      Rails.application.config.session_store.clear
    end
  end

  namespace :cache do
    task :clear => :environment do
      FileUtils.rm_rf(Dir['tmp/cache/[^.]*'])
      Rails.cache.clear
    end
  end
end
