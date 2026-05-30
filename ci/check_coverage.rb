#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

THRESHOLDS = {
  statements: 70.0,
  branches: 65.0,
  functions: 70.0,
  lines: 70.0
}.freeze

EXCLUDED_SOURCE_PATTERNS = [
  %r{/SARLog/.*View\.swift$},
  %r{/SARLog/SARLogApp\.swift$}
].freeze

coverage_path = ARGV.fetch(0) do
  abort "Usage: ruby ci/check_coverage.rb <coverage-report.json>"
end

def percent(covered, total)
  return 100.0 if total.zero?

  covered.to_f / total * 100.0
end

def covered_source_file?(path)
  EXCLUDED_SOURCE_PATTERNS.none? { |pattern| path.match?(pattern) }
end

def sum_llvm_summary(files, metric_name)
  files.each_with_object({ "count" => 0, "covered" => 0 }) do |file, totals|
    metric = file.fetch("summary").fetch(metric_name)
    totals["count"] += metric.fetch("count")
    totals["covered"] += metric.fetch("covered")
  end.tap do |totals|
    totals["percent"] = percent(totals.fetch("covered"), totals.fetch("count"))
  end
end

def metrics_from_llvm_cov(report)
  files = report.fetch("data").first.fetch("files").select do |file|
    covered_source_file?(file.fetch("filename"))
  end
  abort "No app logic coverage files found" if files.empty?

  lines = sum_llvm_summary(files, "lines")
  functions = sum_llvm_summary(files, "functions")
  branches = sum_llvm_summary(files, "branches")

  {
    statements: {
      percent: lines.fetch("percent").to_f,
      detail: "#{lines.fetch('covered')}/#{lines.fetch('count')} executable lines"
    },
    branches: {
      percent: branches.fetch("count").positive? ? branches.fetch("percent").to_f : nil,
      detail: branches.fetch("count").positive? ? "#{branches.fetch('covered')}/#{branches.fetch('count')} branches" : "unavailable in llvm-cov JSON"
    },
    functions: {
      percent: functions.fetch("percent").to_f,
      detail: "#{functions.fetch('covered')}/#{functions.fetch('count')} functions"
    },
    lines: {
      percent: lines.fetch("percent").to_f,
      detail: "#{lines.fetch('covered')}/#{lines.fetch('count')} lines"
    }
  }
end

def metrics_from_xccov(report)
  app_targets = report.fetch("targets").reject do |target|
    target.fetch("name").end_with?(".xctest") ||
      target.fetch("buildProductPath", "").include?(".xctest")
  end

  abort "No app coverage targets found" if app_targets.empty?

  files = app_targets.flat_map { |target| target.fetch("files", []) }.select do |file|
    covered_source_file?(file.fetch("path"))
  end
  abort "No app logic coverage files found" if files.empty?

  covered_lines = files.sum { |file| file.fetch("coveredLines", 0).to_i }
  executable_lines = files.sum { |file| file.fetch("executableLines", 0).to_i }
  functions = files.flat_map { |file| file.fetch("functions", []) }
  covered_functions = functions.count { |function| function.fetch("executionCount", 0).to_i.positive? }

  {
    statements: {
      percent: percent(covered_lines, executable_lines),
      detail: "#{covered_lines}/#{executable_lines} executable lines"
    },
    branches: {
      percent: nil,
      detail: "unavailable in xccov JSON; use llvm-cov export JSON"
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
end

report = JSON.parse(File.read(coverage_path))
metrics = if report.fetch("type", "").start_with?("llvm.coverage")
            metrics_from_llvm_cov(report)
          else
            metrics_from_xccov(report)
          end

puts "Coverage summary:"
metrics.each do |name, metric|
  percent_text = metric[:percent] ? "#{format('%.2f', metric[:percent])}%" : "unavailable"
  puts "  #{name}: #{percent_text} (#{metric[:detail]})"
end

failures = metrics.each_with_object([]) do |(name, metric), failed_metrics|
  threshold = THRESHOLDS.fetch(name)
  if metric[:percent].nil?
    warn "#{name} coverage is unavailable; threshold not enforced for this metric"
    next
  end
  next if metric[:percent] >= threshold

  failed_metrics << "#{name} coverage #{format('%.2f', metric[:percent])}% is below #{format('%.2f', threshold)}%"
end

abort failures.join("\n") unless failures.empty?
