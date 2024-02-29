# This file is used to load extensions that are implemented in a lib directory
#
# https://guides.rubyonrails.org/autoloading_and_reloading_constants.html
#
# https://github.com/radar/guides/blob/master/rails-lib-files.md#option-1
# If you need this library to always be loaded for your rails app,
# you require it in an initializer.
#
require_relative '../../lib/application_service/lib'
require_relative '../../lib/auth_credentials/lib'
