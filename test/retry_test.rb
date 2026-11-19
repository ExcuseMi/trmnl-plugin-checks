# frozen_string_literal: true

# Plain-Ruby check of TPC.with_font_retry: `ruby test/retry_test.rb`. Runs in CI before the plugin checks.
# It runs on the runner's own Ruby (ubuntu-latest's, 3.x: self-test prints it), older than the trmnlp image's: no `it` block parameter in what it calls
# (2026-11-19: TPC.skipped used `it`, passed on Ruby 4 here and stopped every plugin's check on the runner). 
# Guard for that: started on a newer Ruby (a developer's machine), this file first runs itself on an older one when it finds one
# (RUNNER_RUBY, /usr/bin/ruby3.3, /usr/bin/ruby3.2) and fails if that run fails. And the two workflows must use the same Ruby:
# self-test.yml and plugin-check.yml both take the runner's own (neither sets one up), so self-test on a pushed branch is the plugin runners' Ruby.
if RUBY_VERSION >= '3.4' && !ENV['TPC_OLD_RUBY_RUN']
  old = [ENV['RUNNER_RUBY'], '/usr/bin/ruby3.3', '/usr/bin/ruby3.2'].compact.find { |r| File.executable?(r) }
  if old
    ok = system({ 'TPC_OLD_RUBY_RUN' => '1' }, old, __FILE__)
    puts "#{ok ? 'ok' : 'FAIL'} the same tests on #{old} (the plugin runners' Ruby is older than #{RUBY_VERSION})"
    exit 1 unless ok
  else
    puts "note: no older Ruby found here (set RUNNER_RUBY): push a branch and wait for self-test before main"
  end
end
wf = %w[self-test plugin-check].map { |n| File.read(File.join(__dir__, '..', '.github', 'workflows', "#{n}.yml")) }
unless wf.none? { |t| t.match?(/uses:\s*ruby\/setup-ruby/) } && wf.all? { |t| t.include?('runs-on: ubuntu-latest') }
  puts 'FAIL self-test.yml and plugin-check.yml must run on the same runner and Ruby (neither sets a Ruby up)'; exit 1
end
module TRMNLP; module Testing; def self.plugin_dir = '.'; end; end
require_relative '../spec/support'
def check(name, ok) = (puts "#{ok ? 'ok' : 'FAIL'} #{name}"; exit 1 unless ok)
n = 0; TPC.with_font_retry { n += 1; raise "The page's fonts did not load within 10s" if n == 1 }
check('font timeout retried once, then passes', n == 2)
n = 0; begin TPC.with_font_retry { n += 1; raise "The page's fonts did not load within 10s" }; rescue StandardError; end
check('font timeout twice still fails', n == 2)
n = 0; begin TPC.with_font_retry { n += 1; raise 'expected nothing to overflow' }; rescue StandardError; end
check('any other failure is not retried', n == 1)

# TPC.skipped: the devices a plugin leaves out of its checks (TPC_SKIP_DEVICES)
ms = [{ 'name' => 'og_png' }, { 'name' => 'xteink_x3' }, { 'name' => 'v2' }]
check('no skip list keeps every device', TPC.skipped(ms, '').length == 3 && TPC.skipped(ms, nil).length == 3)
check('a named device is left out, the others stay', TPC.skipped(ms, 'xteink_x3').map { |m| m['name'] } == %w[og_png v2])
check('several names, commas or spaces; an unknown name changes nothing', TPC.skipped(ms, 'xteink_x3, v2 nope').map { |m| m['name'] } == %w[og_png])
