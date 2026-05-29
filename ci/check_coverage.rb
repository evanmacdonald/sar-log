#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

THRESHOLDS = {
  statements: 70.0,
  branches: 65.0,
  functions: 70.0,
  lines: 70.0
}.freeze

coverage_path = ARGV.fetch(0) do
  abort "Usage: ruby ci/check_coverage.rb <xccov-report.json>"
end

report = JSON.parse(File.read(coverage_path))
app_targets = report.fetch("targets").reject do |target|
  target.fetch("name").end_with?(".xctest") ||
    target.fetch("buildProductPath", "").include?(".xctest")
end

abort "No app coverage targets found in #{coverage_path}" if app_targets.empty?

files = app_targets.flat_map { |target| target.fetch("files", []) }
covered_lines = files.sum { |file| file.fetch("coveredLines", 0).to_i }
executable_lines = files.sum { |file| file.fetch("executableLines", 0).to_i }
functions = files.flat_map { |file| file.fetch("functions", []) }
covered_functions = functions.count { |function| function.fetch("executionCount", 0).to_i.positive? }

def percent(covered, total)
  return 100.0 if total.zero?

  covered.to_f / total * 100.0
end

metrics = {
  statements: {
    percent: percent(covered_lines, executable_lines),
    detail: "#{covered_lines}/#{executable_lines} executable lines"
  },
  branches: {
    percent: 100.0,
    detail: "0/0 measured branches; xccov does not expose Swift branch counters"
  },
  functions: {
    percent: percent(covered_functions, functions.length),
    detail: "#{covered_functions}/#{functions.length} functions"
  },
  lines: {
    percent: percent(covered_lines, executable_lines),
    detail: "#{covered_lines}/#{executable_lines} lines"
  }
}

puts "Coverage summary:"
metrics.each do |name, metric|
  puts "  #{name}: #{format('%.2f', metric[:percent])}% (#{metric[:detail]})"
end

failures = metrics.each_with_object([]) do |(name, metric), failed_metrics|
  threshold = THRESHOLDS.fetch(name)
  next if metric[:percent] >= threshold

  failed_metrics << "#{name} coverage #{format('%.2f', metric[:percent])}% is below #{format('%.2f', threshold)}%"
end

abort failures.join("\n") unless failures.empty?
