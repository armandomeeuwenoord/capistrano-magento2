##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

include Capistrano::Magento2::Helpers
include Capistrano::Magento2::Setup
namespace :magento do
  namespace :backups do
      task :db do
        on roles(:app) do
          if test("[ -d #{current_path} ]")
              within current_path do
                 execute :php, 'bin/magento', 'setup:backup', '--db', '-n', '-q'
              end
          end
        end
      end

      task :gzip do
        on roles(:app) do
          if test("[ -d #{current_path} ]")
              within current_path do
                 execute 'gzip', 'var/backups/`ls var/backups -t | head -1`'
              end
          end
        end
      end
  end

  namespace :magedbm do
    desc 'Downloads Magedbm2 tool if it does not exist'
    task :download do
      on roles(:app) do
        within release_path do
          if test "[[ -f ~/.magedbm2/config.yml ]]"
            if test "[[ -f magedbm2.phar ]]"
            else
              execute :wget, "https://itonomy.nl/downloads/magedbm2.phar"
            end
          else
            puts "\e[0;31m    Warning: ~/.magedbm2/config.yml does not exist, skipping this step!\n\e[0m\n"
          end
        end
      end
    end

    desc 'Export database via Magedbm2'
    task :put do
      on roles(:app) do
        within release_path do
          if test "[[ -f ~/.magedbm2/config.yml ]]"
            execute :php, "magedbm2.phar", "put", "--root-dir=#{release_path}", fetch(:magedbm_project_name) + "-shop-data"
          else
            puts "\e[0;31m    Warning: ~/.magedbm2/config.yml does not exist, skipping this step!\n\e[0m\n"
          end
        end
      end
    end

    desc 'Import database via Magedbm2'
    task :get do
      on roles(:app) do
        within release_path do
          if test "[[ -f ~/.magedbm2/config.yml ]]"
            execute :php, "magedbm2.phar", "get", "--root-dir=#{release_path}", fetch(:magedbm_project_name) + "-shop-data"
          else
            puts "\e[0;31m    Warning: ~/.magedbm2/config.yml does not exist, skipping this step!\n\e[0m\n"
          end
        end
      end
    end

    desc 'Export anonymized via Magedbm2'
    task :export do
      on roles(:app) do
        within release_path do
          if test "[[ -f ~/.magedbm2/config.yml ]]"
            execute :php, "magedbm2.phar", "export", "--root-dir=#{release_path}", fetch(:magedbm_project_name) + "-customer-data"
          else
            puts "\e[0;31m    Warning: ~/.magedbm2/config.yml does not exist, skipping this step!\n\e[0m\n"
          end
        end
      end
    end

    desc 'Import anonymized customer data via Magedbm2'
    task :import do
      on roles(:app) do
        within release_path do
          if test "[[ -f ~/.magedbm2/config.yml ]]"
            execute :php, "magedbm2.phar", "import", "--root-dir=#{release_path}", fetch(:magedbm_project_name) + "-customer-data"
          else
            puts "\e[0;31m    Warning: ~/.magedbm2/config.yml does not exist, skipping this step!\n\e[0m\n"
          end
        end
      end
    end
  end

  namespace 'magepack-advanced-bundling' do
    desc 'Generate MagePack Advanced Bundling Config'
    task :generate do
      cms_page_url = fetch(:magepack_advanced_bundling_cms_url)
      cat_page_url = fetch(:magepack_advanced_bundling_category_url)
      pdp_page_url = fetch(:magepack_advanced_bundling_product_url)
      on release_roles :all do
        within release_path do
          execute "cd #{release_path} && magepack generate --cms-url=\"#{cms_page_url}\" --category-url=\"#{cat_page_url}\" --product-url=\"#{pdp_page_url}\""
        end
      end
    end

    desc 'Bundle Generated MagePack Advanced Bundling Config'
    task :bundle do
      on release_roles :all do
        within release_path do
          execute "cd #{release_path} && magepack bundle"
        end
      end
    end

    desc 'Enable MagePack Advanced Bundling'
    task :enable do
      on release_roles :all do
        within release_path do
          execute :magento, 'config:set dev/js/enable_magepack_js_bundling 1'
          execute :magento, 'cache:flush'
        end
      end
    end

    desc 'Disable MagePack Advanced Bundling'
    task :disable do
      on release_roles :all do
        within release_path do
          execute :magento, 'config:set dev/js/enable_magepack_js_bundling 0'
        end
      end
    end
  end

  namespace 'advanced-bundling' do
    desc 'Deploys advanced bundling'
    task :deploy do
      on release_roles :all do
        deploy_themes = fetch(:magento_deploy_themes)
        deploy_languages = fetch(:magento_deploy_languages)
        rjs_executable_path = fetch(:rjs_executable_path)

        within release_path do
          if test "[[ -f #{release_path}/build.js ]]"
            deploy_themes.each do |theme|
              if theme != 'Magento/backend'
                deploy_languages.each do |language|
                  if test "[[ -f #{rjs_executable_path} ]]"
                    execute "mv", "#{release_path}/pub/static/frontend/#{theme}/#{language}/ #{release_path}/pub/static/frontend/#{theme}/#{language}_source/"
                    execute "#{rjs_executable_path}", "-o #{release_path}/build.js dir=pub/static/frontend/#{theme}/#{language}/ baseUrl=#{release_path}/pub/static/frontend/#{theme}/#{language}_source/"
                  else
                    puts "\e[0;31m    Warning: r.js executable not found, you can assign a custom path to rjs_executable_path. Skipping this step!\n\e[0m\n"
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  namespace :cache do

    desc 'Flush Magento cache storage'
    task :flush do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:flush'
        end
      end
    end
    
    desc 'Clean Magento cache by types'
    task :clean do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:clean'
        end
      end
    end
    
    desc 'Enable Magento cache'
    task :enable do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:enable'
        end
      end
    end
    
    desc 'Disable Magento cache'
    task :disable do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:disable'
        end
      end
    end
    
    desc 'Check Magento cache enabled status'
    task :status do
      on cache_hosts do
        within release_path do
          execute :magento, 'cache:status'
        end
      end
    end

    namespace :opcache do
      desc 'clear opcache'
      task :clear do
        on release_roles :all do
          within release_path do
            code = "<?php opcache_reset(); ?>"
            op_file_path = "#{release_path}/pub/opcache_clear.php";
            upload!(StringIO.new(code), op_file_path)
            execute :chmod, '765 "'+ op_file_path +'"'
            additional_websites = fetch(:magento_deploy_clear_opcache_additional_websites)
            opcache_urls = []
            opcache_urls.push(capture(:magento, 'config:show web/unsecure/base_url', verbosity: Logger::INFO))
            for additional_website in additional_websites do
              opcache_urls.push(capture(:magento, "config:show --scope=websites --scope-code=#{additional_website} web/unsecure/base_url", verbosity: Logger::INFO))
            end
            for opcache_url in opcache_urls do
              dir_sep = (opcache_url[-1] === '/' ? '' : '/')
              execute :curl, %W{#{opcache_url}#{dir_sep}opcache_clear.php}
            end
          end
        end
      end
    end

    namespace :varnish do
      # TODO: Document what the magento:cache:varnish:ban task is for and how to use it. See also magento/magento2#4106
      desc 'Add ban to Varnish for url(s)'
      task :ban do
        on primary fetch(:magento_deploy_setup_role) do
          # TODO: Document use of :ban_pools and :varnish_cache_hosts in project config file
          next unless any? :ban_pools
          next unless any? :varnish_cache_hosts
          
          within release_path do
            for pool in fetch(:ban_pools) do
              for cache_host in fetch(:varnish_cache_hosts) do
                execute :curl, %W{-s -H 'X-Pool: #{pool}' -X PURGE #{cache_host}}
              end
            end
          end
        end
      end
    end
  end
  
  namespace :composer do
    desc 'Run composer install'
    task :install => :auth_config do

      on release_roles :all do
        within release_path do
          composer_flags = fetch(:composer_install_flags)

          if fetch(:magento_deploy_production)
            composer_flags += ' --optimize-autoloader'
          end

          execute :composer, "install #{composer_flags} 2>&1"

          if fetch(:magento_deploy_production) and magento_version >= Gem::Version.new('2.1')
            composer_flags += ' --no-dev'
            execute :composer, "install #{composer_flags} 2>&1" # removes require-dev components from prev command
          end

          if test "[ -f #{release_path}/update/composer.json ]"   # can't count on this, but emit warning if not present
            execute :composer, "install #{composer_flags} -d ./update 2>&1"
          else
            puts "\e[0;31m    Warning: ./update/composer.json does not exist in repository!\n\e[0m\n"
          end
        end
      end
    end

    task :auth_config do
      on release_roles :all do
        within release_path do
          if fetch(:magento_auth_public_key) and fetch(:magento_auth_private_key)
            execute :composer, :config, '-q',
              fetch(:magento_auth_repo_name),
              fetch(:magento_auth_public_key),
              fetch(:magento_auth_private_key),
              verbosity: Logger::DEBUG
          end
        end
      end
    end
  end

  namespace :deploy do
    task :check do
      on release_roles :all do
        next unless any? :linked_files_touch
        on release_roles :all do |host|
          join_paths(shared_path, fetch(:linked_files_touch)).each do |file|
            unless test "[ -f #{file} ]"
              execute "touch #{file}"
            end
          end
        end
      end
    end

    task :verify do
      is_err = false
      on release_roles :all do
        unless test "[ -f #{release_path}/app/etc/config.php ]"
          error "\e[0;31mThe repository is missing app/etc/config.php. Please install the application and retry!\e[0m"
          exit 1  # only need to check the repo once, so we immediately exit
        end

        unless test %Q[#{SSHKit.config.command_map[:php]} -r '
              $cfg = include "#{release_path}/app/etc/env.php";
              exit((int)!isset($cfg["install"]["date"]));
          ']
          error "\e[0;31mError on #{host}:\e[0m No environment configuration could be found." +
                " Please configure app/etc/env.php and retry!"
          is_err = true
        end
      end
      exit 1 if is_err
    end

    task :local_config do
      on release_roles :all do
        if test "[ -f #{release_path}/app/etc/config.local.php ]"
          info "The repository contains app/etc/config.local.php, removing from :linked_files list."
          _linked_files = fetch(:linked_files, [])
          _linked_files.delete('app/etc/config.local.php')
          set :linked_files, _linked_files
        end
      end
    end
  end

  namespace :setup do
    desc 'Updates the module load sequence and upgrades database schemas and data fixtures'
    task :upgrade do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          warn "\e[0;31mWarning: Use of magento:setup:upgrade on production systems is discouraged." +
               " See https://github.com/davidalger/capistrano-magento2/issues/34 for details.\e[0m\n"

          execute :magento, 'setup:upgrade --keep-generated'
        end
      end
    end
    
    namespace :db do
      desc 'Checks if database schema and/or data require upgrading'
      task :status do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db:status'
          end
        end
      end

      task :config do
        on primary fetch(:all) do
          within release_path do
            execute :magento, 'app:config:import'
          end
        end
      end
      
      task :upgrade do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            db_status = capture :magento, 'setup:db:status --no-ansi', verbosity: Logger::INFO
            
            if not db_status.to_s.include? 'All modules are up to date'
              execute :magento, 'setup:db-schema:upgrade'
              execute :magento, 'setup:db-data:upgrade'
            end
          end
        end
      end
      
      desc 'Upgrades data fixtures'
      task 'schema:upgrade' do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db-schema:upgrade'
          end
        end
      end
      
      desc 'Upgrades database schema'
      task 'data:upgrade' do
        on primary fetch(:magento_deploy_setup_role) do
          within release_path do
            execute :magento, 'setup:db-data:upgrade'
          end
        end
      end
    end
    
    desc 'Sets proper permissions on application'
    task :permissions do
      on release_roles :all do
        within release_path do
          execute :find, release_path, "-type d -exec chmod #{fetch(:magento_deploy_chmod_d).to_i} {} +"
          execute :find, release_path, "-type f -exec chmod #{fetch(:magento_deploy_chmod_f).to_i} {} +"
          
          fetch(:magento_deploy_chmod_x).each() do |file|
            execute :chmod, "+x #{release_path}/#{file}"
          end
        end
      end
      Rake::Task['magento:setup:permissions'].reenable  ## make task perpetually callable
    end
    
    namespace :di do
      desc 'Runs dependency injection compilation routine'
      task :compile do
        on release_roles :all do
          within release_path do
            # Due to a bug in the single-tenant compiler released in 2.0 (see here for details: http://bit.ly/21eMPtt)
            # we have to use multi-tenant currently. However, the multi-tenant is being dropped in 2.1 and is no longer
            # present in the develop mainline, so we are testing for multi-tenant presence for long-term portability.
            if test :magento, 'setup:di:compile-multi-tenant --help >/dev/null 2>&1'
              output = capture :magento, 'setup:di:compile-multi-tenant --no-ansi', verbosity: Logger::INFO
            else
              output = capture :magento, 'setup:di:compile --no-ansi', verbosity: Logger::INFO
            end
            
            # 2.0.x never returns a non-zero exit code for errors, so manually check string
            # 2.1.x doesn't return a non-zero exit code for certain errors (see davidalger/capistrano-magento2#41)
            if output.to_s.include? 'Errors during compilation'
              raise Exception, 'DI compilation command execution failed'
            end
          end
        end
      end
    end
    
    namespace 'static-content' do
      desc 'Deploys static view files'
      task :deploy do
        on release_roles :all do
          _magento_version = magento_version

          deploy_themes = fetch(:magento_deploy_themes)
          deploy_jobs = fetch(:magento_deploy_jobs)

          if deploy_themes.count() > 0 and _magento_version >= Gem::Version.new('2.1.1')
            deploy_themes = deploy_themes.join(' -t ').prepend(' -t ')
          elsif deploy_themes.count() > 0
            warn "\e[0;31mWarning: the :magento_deploy_themes setting is only supported in Magento 2.1.1 and later\e[0m"
            deploy_themes = nil
          else
            deploy_themes = nil
          end

          if deploy_jobs and _magento_version >= Gem::Version.new('2.1.1')
            deploy_jobs = "--jobs #{deploy_jobs} "
          elsif deploy_jobs
            warn "\e[0;31mWarning: the :magento_deploy_jobs setting is only supported in Magento 2.1.1 and later\e[0m"
            deploy_jobs = nil
          else
            deploy_jobs = nil
          end

          deploy_languages = [fetch(:magento_deploy_languages).join(' ')]

          # Output is being checked for a success message because this command may easily fail due to customizations
          # and 2.0.x CLI commands do not return error exit codes on failure. See magento/magento2#3060 for details.
          within release_path do

            # Workaround for 2.1 specific issue: https://github.com/magento/magento2/pull/6437
            execute "touch #{release_path}/pub/static/deployed_version.txt"

            # Generates all but the secure versions of RequireJS configs
            deploy_languages.each {|lang| static_content_deploy "#{deploy_jobs}#{lang}#{deploy_themes}"}
          end

          # Run again with HTTPS env var set to 'on' to pre-generate secure versions of RequireJS configs
          deploy_flags = ['css', 'less', 'images', 'fonts', 'html', 'misc', 'html-minify']
          
          # As of Magento 2.1.3, it became necessary to exclude "--no-javacript" in order for secure versions of 
          # RequireJs configs to be generated
          if _magento_version < Gem::Version.new('2.1.3')
            deploy_flags.push('javascript')
          end
          
          deploy_flags = deploy_flags.join(' --no-').prepend(' --no-');

          # Magento 2.1.0 and earlier lack support for these flags, so generation of secure files requires full re-run
          deploy_flags = nil if _magento_version <= Gem::Version.new('2.1.0')

          within release_path do with(https: 'on') {
            deploy_languages.each {|lang| static_content_deploy "#{deploy_jobs}#{lang}#{deploy_themes}#{deploy_flags}"}
          } end

          # Set the deployed_version of static content to ensure it matches across all hosts
          upload!(StringIO.new(deployed_version), "#{release_path}/pub/static/deployed_version.txt")
        end
      end
    end
  end

  namespace :pearl do
    desc 'Compile pearl LESS + CSS assets'
    task :compile do
      on release_roles :all do
        within release_path do
          execute :magento, 'weltpixel:less:generate'

          pearl_css_stores = fetch(:magento_deploy_pearl_stores)
            if pearl_css_stores.count() > 0
              pearl_css_stores.each do |store|
                execute :magento, "weltpixel:css:generate --store=#{store}"
              end
            end
          end
        end
      end
    end

  namespace :maintenance do
    desc 'Enable maintenance mode'
    task :enable do
      on release_roles :all do
        within release_path do
          exempt_ips = fetch(:magento_deploy_maintenance_allowed_ips)
          exempt_ip_string = ""
          if exempt_ips.any?
            exempt_ips.each { |exempt_ip| exempt_ip_string += " --ip=#{exempt_ip}" }
          end
          execute :magento, "maintenance:enable #{exempt_ip_string}"
        end
      end
    end
    
    desc 'Disable maintenance mode'
    task :disable do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:disable'
        end
      end
    end

    desc 'Displays maintenance mode status'
    task :status do
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:status'
        end
      end
    end

    desc 'Sets maintenance mode exempt IPs'
    task 'allow-ips', :ip do |t, args|
      on release_roles :all do
        within release_path do
          execute :magento, 'maintenance:allow-ips', args[:ip]
        end
      end
    end
  end

  namespace :indexer do
    desc 'Reindex data by all indexers'
    task :reindex do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:reindex'
        end
      end
    end

    desc 'Shows allowed indexers'
    task :info do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:info'
        end
      end
    end

    desc 'Shows status of all indexers'
    task :status do
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:status'
        end
      end
    end

    desc 'Shows mode of all indexers'
    task 'show-mode', :index do |t, args|
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:show-mode', args[:index]
        end
      end
    end

    desc 'Sets mode of all indexers'
    task 'set-mode', :mode, :index do |t, args|
      on primary fetch(:magento_deploy_setup_role) do
        within release_path do
          execute :magento, 'indexer:set-mode', args[:mode], args[:index]
        end
      end
    end
  end
end
