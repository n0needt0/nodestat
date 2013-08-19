require 'rubygems'

default_run_options[:pty] = true
set :use_sudo, true

set :keep_releases, 2

set :application_name, "help"

set :user, Capistrano::CLI.ui.ask("User for deploy:")
set :password, Capistrano::CLI.ui.ask("Password for user #{user}:"){|q|q.echo = false}
set :ssh_options, {:user => user, :password => password, :forward_agent => true }
set :scm, "git"
set :user, "#{user}"
set :scm_passphrase, "#{password}"
set :repository, "https://github.com/n0needt0/mobile"

#set :scm_command, "git_umask"
set :branch, "master"
set :deploy_via, :remote_cache
set :scm_auth_cache, false


#don't copy .svn directories from the cache to production
#set :copy_exclude, [".svn" "conf"]

set :stages, %w(production)
set :default_stage, "production"

require 'capistrano/ext/multistage'

namespace :setup do
  desc "Set env"
  task :me do
    set :application, "#{application_name}.#{stage}"
    set :deploy_to, "/srv/#{application}"
    set :apache_root, "/var/www/#{application}"
  end
end


namespace :show do
  desc "Show some internal Capistrano State"
  task :me do
    set :task_name, task_call_frames.first.task.fully_qualified_name
    #puts "Running #{task_name} task"
  end
end

namespace :deploy do
  desc "Send email notification of deployment (only send variables you want to be in the email)"
  task :notify, :roles => :app do
    show.me
  end
  
  def remote_file_exists?(full_path)
    'true' ==  top.capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  desc "Change group to www-data"
  task :chown_to_www_data, :roles => [ :app ] do
  sudo "chown -R www-data:root #{deploy_to}"
  end

  desc "Change group to user"
     task :chown_to_user, :roles => [ :app ] do
         unless remote_file_exists?(deploy_to)
           sudo "mkdir #{deploy_to}"
         end
         
         unless remote_file_exists?(deploy_to + "/releases")
           sudo "mkdir #{deploy_to}/releases"
         end
         
         sudo "chown -R #{user}:root #{deploy_to}"
  end

  desc "Write current revision to "
  task :publish_revision do
  run "content=`cat #{deploy_to}/current/REVISION`;ip=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`; sed -i \"s/MY_REVISION/$content-$ip/g\" #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/views/templates/mobile.php"
  run "content=`cat #{deploy_to}/current/REVISION`;ip=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`; sed -i \"s/MY_REVISION/$content-$ip/g\" #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/views/templates/rapport.php"
  end
  
  desc "clean up old releases"
    task :remove_old do
    run "for f in $( ls -t #{deploy_to}/releases | tail -n +10 ); do  rm -rf #{deploy_to}/releases/$f;  done"
  end
  
  desc "get correct config"
  task :get_correct_config do
    run "mv #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/config.#{stage}.php #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/config.php"
    
    run "mv #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/constants.#{stage}.php #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/constants.php"
    
    run "mv #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/database.#{stage}.php #{deploy_to}/current/net.helppain.mobile/code/var/help/web_apps/help/config/database.php"
    
  end
  
  desc "get correct apache"
   task :get_correct_apache_conf do
   sudo "mv #{deploy_to}/current/net.helppain.mobile/code/etc/apache2/sites-enabled/#{application_name}.#{stage} /etc/apache2/sites-enabled/#{application_name}"
  end

  desc "Reload Apache"
  task :reload_apache do
    unless remote_file_exists?(apache_root)
      sudo "ln -sf #{deploy_to}/current/net.helppain.mobile/code/var/help #{apache_root}"
    end
    
    sudo "/etc/init.d/apache2 reload"
  end
end

before 'deploy', 'setup:me'

#change directory permissions to current user
before 'deploy', 'deploy:chown_to_user'

#get correct config version
after 'deploy','deploy:get_correct_config'

#get correct deploy apache conf version
after 'deploy','deploy:get_correct_apache_conf'

#change permission to www-data user
after 'deploy', 'deploy:publish_revision'

#remove old code
after 'deploy', 'deploy:remove_old'

#change permission to www-data user
after 'deploy', 'deploy:chown_to_www_data'

#restart apache
after 'deploy', 'deploy:reload_apache'
