#!/usr/bin/env ruby

# require "nokogiri"
# page = Nokogiri::HTML(open(html))

require "date"
require "icalendar"


def hours2hm(h)
    hours = h.floor
    mins = ((h % 1)*60).floor
    "T#{hours}H#{mins}M"
end


cal = Icalendar::Calendar.new
projects = ARGV[1..-1]
File.read(ARGV.first).split("<tr>").each do |l|
    project_code = l.match(/<td valign="top">(C\d{4})<\/td>/)
    next unless project_code
    next unless projects.include?(project_code[1])

    dates = []
    date_table = l.split("<td nowrap=\"nowrap\" valign=\"top\">")[1]
    date_table.split(" <br>").each do |d|
        break if d =~ /Total/
        dates.push(d)
    end

    start_times = []
    start_time_table = l.split("<td nowrap=\"nowrap\" valign=\"top\" align=\"center\"> ")[1]
    start_time_table.split(" <br> ").each do |s|
        break unless s =~ /^\d/
        start_times.push(s)
    end

    durations = []
    duration_table = l.split("<td nowrap=\"nowrap\" valign=\"top\" align=\"right\"> ")[1]
    duration_table.split("<br>").each do |d|
        break if d.include?("valign")
        durations.push(hours2hm(d.to_f))
    end

    dates_and_times = dates.zip(start_times).map { |d, t| DateTime.parse("#{d} #{t}") }
    dates_and_times.map! { |d| d.new_offset(DateTime.now.offset) }

    dates_and_times.each_with_index do |d, i|
        event = Icalendar::Event.new
        event.dtstart = d
        event.duration = durations[i]
        # p durations[i]
        # STDIN.gets.chomp
        event.summary = project_code[1]
        cal.add_event(event)
    end
end

puts cal.to_ical
