require 'rubygems'

default_run_options[:pty] = true
set :use_sudo, true

set :keep_releases, 2

set :application_name, "nodestat"

set :user, Capistrano::CLI.ui.ask("User for deploy:")
set :password, Capistrano::CLI.ui.ask("Password for user #{user}:"){|q|q.echo = false}
set :ssh_options, {:user => user, :password => password, :forward_agent => true }
set :scm, "git"
set :user, "#{user}"
set :scm_passphrase, "#{password}"
set :repository, "https://github.com/n0needt0/nodestat"

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
    set :web_root, "/var/www/#{application}"
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
  run "content=`cat #{deploy_to}/current/REVISION`;ip=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`; sed -i \"s/MY_REVISION/$content-$ip/g\" #{deploy_to}/current/code/var/nodestat/views/index.jade"
  end
  
  desc "clean up old releases"
    task :remove_old do
    run "for f in $( ls -t #{deploy_to}/releases | tail -n +10 ); do  rm -rf #{deploy_to}/releases/$f;  done"
  end
  
  desc "get correct config"
  task :get_correct_config do
    run "mv #{deploy_to}/current/code/var/nodestat/settings.#{stage} #{deploy_to}/current/code/var/nodestat/settings.json"
  end
  
  desc "get correct nginx"
   task :get_correct_nginx_conf do
   sudo "mv #{deploy_to}/current/code/etc/nginx/sites-enabled/#{application_name}.#{stage} /etc/nginx/sites-enabled/#{application_name}"
  end

  desc "Reload Nginx"
  task :reload_nginx do
    unless remote_file_exists?(web_root)
      sudo "ln -sf #{deploy_to}/current/code/var/nodestat #{web_root}"
    end
    
    sudo "/etc/init.d/nginx reload"
  end

  desc "get correct upstart"
   task :get_correct_upstart_conf do
   sudo "mv #{deploy_to}/current/code/etc/init/nodestat.#{stage} /etc/init/nodestat.conf"
  end

  desc "get correct monit"
   task :get_correct_monit_conf do
   sudo "mv #{deploy_to}/current/code/etc/monit/conf.d/nodestat.#{stage} /etc/monit/conf.d/nodestat"
  end

  desc "Reload Monit"
   task :reload_monit do
   sudo "/etc/init.d/monit restart"
  end

  desc "Start Node"
   task :reload_node do
   sudo "start nodestat"
  end


end

before 'deploy', 'setup:me'

#change directory permissions to current user
before 'deploy', 'deploy:chown_to_user'

#get correct config version
after 'deploy','deploy:get_correct_config'

#get correct deploy apache conf version
after 'deploy','deploy:get_correct_nginx_conf'

#change permission to www-data user
after 'deploy', 'deploy:publish_revision'

#remove old code
after 'deploy', 'deploy:remove_old'

#change permission to www-data user
after 'deploy', 'deploy:chown_to_www_data'

after 'deploy', 'deploy:get_correct_upstart_conf'
after 'deploy', 'deploy:get_correct_monit_conf'

#restart app
after 'deploy', 'deploy:reload_node'
after 'deploy', 'deploy:reload_monit'
after 'deploy', 'deploy:reload_nginx'
