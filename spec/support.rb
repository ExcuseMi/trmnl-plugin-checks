# frozen_string_literal: true

# Reads a plugin's own data sets for the base checks. Nothing is invented here.
#   custom_fields / variables / time zone: the plugin's .trmnlp.yml
#   mocks: tests/mocks.json of the plugin, else fixtures/<repo>/mocks.json of this repo (copied to tests/tpc_mocks.json)
# A mocks file maps a url (exact, `*` wildcards, or "re:<regexp>") to an answer: { json:, body:, status:, error: }.
# An answer may also name a file of the plugin: json_file / body_file (path relative to the plugin folder).
require 'json'
require 'yaml'

module TPC
  module_function

  def dir = TRMNLP::Testing.plugin_dir

  def config
    path = File.join(dir, '.trmnlp.yml')
    File.exist?(path) ? (YAML.safe_load_file(path, aliases: true) || {}) : {}
  end

  def custom_fields = config['custom_fields'] || {}
  def variables = config['variables'] || {}

  def mocks
    path = %w[tests/mocks.json tests/tpc_mocks.json].map { File.join(dir, it) }.find { File.exist?(it) }
    return {} unless path

    JSON.parse(File.read(path)).to_h do |key, answer|
      [key.start_with?('re:') ? Regexp.new(key.delete_prefix('re:')) : key, answer_for(answer)]
    end
  end

  def answer_for(answer)
    return answer.map { answer_for(it) } if answer.is_a?(Array)
    return answer unless answer.is_a?(Hash)

    out = answer.transform_keys(&:to_sym)
    out[:json] = JSON.parse(File.read(File.join(dir, out.delete(:json_file)))) if out[:json_file]
    out[:body] = File.read(File.join(dir, out.delete(:body_file))) if out[:body_file]
    out[:error] = out[:error].to_sym if out[:error]
    out
  end

  # Owner 2026-11-16: a font timeout (slow CI machine) is retried once; every other failure counts on the first try.
  FONT_TIMEOUT = /fonts did not load/

  def with_font_retry(tries: 2)
    yield
  rescue StandardError => e
    tries -= 1
    raise unless tries.positive? && e.message.match?(FONT_TIMEOUT)

    warn "retry after font timeout: #{e.message[0, 120]}"
    retry
  end

  # One entry per distinct screen of TRMNL's live model list (a new device appears by itself). Models of the same
  # size and screen classes draw the same page, so they are checked once and named together. Models without CSS
  # classes (tidbyt, vestaboard) have no HTML screen and are left out.
  # A plugin may leave named devices out (workflow input skip-devices, env TPC_SKIP_DEVICES: names separated by commas or
  # spaces), each with its reason written beside the input in the plugin's own workflow. A screen is left out only when
  # every model that shares it is named.
  def skipped(models, env = ENV.fetch('TPC_SKIP_DEVICES', ''))
    names = env.to_s.split(/[\s,]+/).reject(&:empty?)
    models.reject { names.include?(it['name']) }
  end

  def screens
    models = skipped(TRMNLP::Testing::DeviceModels.send(:models).select { it.dig('css', 'classes') })
    groups = models.group_by { [it['width'], it['height'], it.dig('css', 'classes')] }
    groups.values.flat_map do |group|
      %i[landscape portrait].map { |orientation| { device: group.first['name'], orientation:, same_as: group.map { it['name'] } } }
    end
  end
end

if (out = ENV.fetch('TPC_RESULTS', nil))
  RSpec.configure { |config| config.add_formatter('json', File.join(out, 'results.json')) }
end
