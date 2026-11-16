# frozen_string_literal: true

# Plain-Ruby check of TPC.with_font_retry: `ruby test/retry_test.rb`. Runs in CI before the plugin checks.
module TRMNLP; module Testing; def self.plugin_dir = '.'; end; end
require_relative '../spec/support'
def check(name, ok) = (puts "#{ok ? 'ok' : 'FAIL'} #{name}"; exit 1 unless ok)
n = 0; TPC.with_font_retry { n += 1; raise "The page's fonts did not load within 10s" if n == 1 }
check('font timeout retried once, then passes', n == 2)
n = 0; begin TPC.with_font_retry { n += 1; raise "The page's fonts did not load within 10s" }; rescue StandardError; end
check('font timeout twice still fails', n == 2)
n = 0; begin TPC.with_font_retry { n += 1; raise 'expected nothing to overflow' }; rescue StandardError; end
check('any other failure is not retried', n == 1)
