##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

namespace :magento do
  
  namespace :cache do
    desc 'Flush the Magento Cache'
    task :flush do
      on release_roles :all do
        within release_path do
          execute :php, '-f', 'bin/magento', '--', 'cache:flush'
        end
      end
    end
  end
  
  namespace :setup do
    desc 'Run the Magento upgrade process'
    task :upgrade do
      on release_roles :all do
        within release_path do
          execute :php, '-f', 'bin/magento', '--', 'setup:upgrade'
        end
      end
    end

    # TODO: Change this once the bug with single tenant compiler is fixed http://devdocs.magento.com/guides/v2.0/config-guide/cli/config-cli-subcommands-compiler.html#config-cli-subcommands-single
    task :di do
      task :compile_multi_tenant do
        on release_roles :all do
          within release_path do
            execute :php, '-f', 'bin/magento', '--', 'setup:di:compile-multi-tenant', '-q'
          end
        end
      end
    end
  end
  
  namespace :varnish do
    desc 'Add ban to Varnish for url(s)'
    task :ban do
      on release_roles :all do
        within release_path do
          for url in fetch(:urls) do
            varnish_response = capture(:curl, '-v', '-k', '-H', '"X-Host: ' + url + '"', '-X', 'BAN', '127.0.0.1:6081')
            if varnish_response.include? '<title>200 Banned</title>'
              puts '    Successfully added ban to Varnish for url: ' + url
            elsif
              puts "\n\e[0;31m    ######################################################################\n" \
                "    #                                                                    #\n" \
                "    #                    Failed to ban Varnish urls                      #\n" \
                "    #                                                                    #\n" \
                "    ######################################################################\n\n" \
                + varnish_response + \
                "\e[0m\n"
            end
          end
        end
      end
    end
  end
  
  desc 'Reset permissions'
  task :reset_permissions do
    on release_roles :all do
      within release_path do
        execute :find, '.', '-type', 'd', '-exec', 'chmod', '770', '{}', '+'
        execute :find, '.', '-type', 'f', '-exec', 'chmod', '660', '{}', '+'
        execute :chmod, '-R', 'g+s', '.'
        execute :chmod, '+x', './bin/magento'
      end
    end
  end

  namespace :indexer do
    desc 'Reindex data by all indexers'
    task :reindex do
      on release_roles :all do
        within "#{release_path}" do
          execute :php, '-f', 'bin/magento', '--', 'indexer:reindex'
        end
      end
    end
  end

end
