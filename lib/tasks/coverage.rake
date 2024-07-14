# frozen_string_literal: true

namespace :coverage do
  desc 'Generate coverage badge'
  task generate_badge: :environment do
    coverage_result = JSON.parse(File.read('coverage/coverage.json'))
    groups_coverage = coverage_result['groups'].values.map { |group| group['lines']['covered_percent'] }
    total_coverage_percent = (groups_coverage.sum / groups_coverage.size).to_i
    File.write('coverage/coverage.svg', build_svg(total_coverage_percent))
    puts "Generated coverage badge SVG with #{total_coverage_percent}% coverage."
  end

  private

  def build_svg(total_coverage_percent)
    <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="96" height="20" role="img" aria-label="coverage: 90%">
        <title>coverage: #{total_coverage_percent}%</title>
        <linearGradient id="s" x2="0" y2="100%">
          <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
          <stop offset="1" stop-opacity=".1"/>
        </linearGradient>
        <clipPath id="r">
          <rect width="96" height="20" rx="3" fill="#fff"/>
        </clipPath>
        <g clip-path="url(#r)">
          <rect width="61" height="20" fill="#3d464e"/>
          <rect x="61" width="35" height="20" fill="#{select_color(total_coverage_percent)}"/>
          <rect width="96" height="20" fill="url(#s)"/>
        </g>
        <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
          <text aria-hidden="true" x="315" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="510">coverage</text>
          <text x="315" y="140" transform="scale(.1)" fill="#fff" textLength="510">coverage</text>
          <text aria-hidden="true" x="775" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="250">#{total_coverage_percent}%</text>
          <text x="775" y="140" transform="scale(.1)" fill="#fff" textLength="250">#{total_coverage_percent}%</text>
        </g>
      </svg>
    SVG
  end

  def select_color(total_coverage_percent)
    if total_coverage_percent >= 90
      '#32C856'
    elsif total_coverage_percent >= 75
      '#dfb317'
    else
      '#e05d44'
    end
  end
end
