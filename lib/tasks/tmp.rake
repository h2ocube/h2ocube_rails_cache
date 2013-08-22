namespace :tmp do
  desc "Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)"
  task clear: [ "tmp:sessions:clear",  "tmp:cache:clear", "tmp:sockets:clear"]

  tmp_dirs = [ 'tmp/sessions',
               'tmp/cache',
               'tmp/sockets',
               'tmp/pids',
               'tmp/cache/assets/development',
               'tmp/cache/assets/test',
               'tmp/cache/assets/production' ]

  tmp_dirs.each { |d| directory d }

  desc "Creates tmp directories for sessions, cache, sockets, and pids"
  task create: tmp_dirs

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

  namespace :sockets do
    # desc "Clears all files in tmp/sockets"
    task :clear do
      FileUtils.rm(Dir['tmp/sockets/[^.]*'])
    end
  end

  namespace :pids do
    # desc "Clears all files in tmp/pids"
    task :clear do
      FileUtils.rm(Dir['tmp/pids/[^.]*'])
    end
  end
end
