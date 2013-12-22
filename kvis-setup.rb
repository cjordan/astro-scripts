#!/usr/bin/env ruby

# A "dumb" set up script for kvis, simulating mouse movements and clicks.
# It is time consuming to set up, but perhaps less frustrating than
# setting up kvis every single time. Coordinates were determined by
# screenshotting the desktop of the various dialogs and menus.
# This script assumes the main kvis window is on top when it is run.

require 'optparse'

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: kvis-setup.rb [options]\nDumb set up script for karma's kvis. Simulates mouse movements and clicks."

    opts.on('-h','--help','Display this message') {puts opts; exit}

    # sleep_time is global so you don't have to pass it annoyingly to functions
    $sleep_time = 0.05
	opts.on('-s','--sleep_time NUM','Specify the amount of time to sleep between actions. May be useful for slow computers or networks. Default is 0.05s.') {|o| $sleep_time = o.to_f}

    options[:layout] = "square"
    opts.on('-l','--layout STR','Specify the layout. Supported orientations are:
                                     - \'square\'
                                     - \'wide\'
                                     Default is \'square\'') {|o| options[:layout] = o}

    opts.on('-d','--debug','Prints the commands being sent to xdotool.') {$debug = true}
end.parse!


def xdotool(command)
    puts "\n#{command}" if $debug
    # Run xdotool with the specified command in a shell.
    # "strip" is necessary for pesky newlines
    `xdotool #{command}`.strip
end

def click_on(x,y)
    xdotool "mousemove #{x} #{y}"
    xdotool "click 1"
    sleep $sleep_time
end

def navigate_dropdown(x1,y1,x2,y2)
    # It's ugly, but "moving" the mouse on and off the dropdown button works better
    xdotool "mousemove #{x1} #{y1}"
    xdotool "mousemove #{x1} #{y1-30}"
    xdotool "mousemove #{x1} #{y1}"
    xdotool "mousedown 1"
    sleep $sleep_time
    xdotool "mousemove #{x2} #{y2}"
    xdotool "mouseup 1"
    sleep $sleep_time
end

browser_width = 500

## Record the mouse position so we can reset it when done
original_mouse_pos = (xdotool "getmouselocation").scan(/:(\d*)/)[0..1].join(' ')

## Get some information on the geometry of the desktop so we can place windows neatly at the edges
# Move the mouse to somewhere very far away...
xdotool "mousemove 5000 5000"
# The mouse will only move as far away as the desktop allows, so now we have the screen geometry
geometry = (xdotool "getmouselocation").scan(/:(\d*)/)[0..1].flatten.map{|n| n.to_i}

# Find the main kvis window and select it
kvis_window_id = xdotool "search --name 'kvis.*Karma'"
# windowraise and windowfocus do not work in dwm - stuff will work only when kvis is on top
xdotool "windowraise #{kvis_window_id}"
# Move it to the default location
xdotool "windowmove --sync #{kvis_window_id} 0 14"


## Axis labels and Paper colours
# Open "Axis labels" from the "Overlay" dialog...
navigate_dropdown(240,30,240,80)
# Enable axis labels
click_on(100,30)
# Enable "Paper Colours"
click_on(200,155)
# ... and close the dialog
click_on(30,30)


## Colour scheme
# Open "PseudoColour" from the "Intensity" dialog...
navigate_dropdown(100,30,100,80)
# Disable "Reverse" from "Paper Colours"
click_on(130,30)
# Use the "Glynn Rogers 2" profile
click_on(230,309)
# ... and close the dialog
click_on(30,30)


## Spectrum "profile" window
# Open the "View" dialog...
click_on(365,30)
# Enable "Show Marker in Line Profile"
click_on(100,130)
# Select "Box Sum" from the "Profile Mode" list...
navigate_dropdown(200,55,200,130)
# Enable "Auto V Zoom"
click_on(100,30)
# Make the style "hist"
navigate_dropdown(280,55,280,107)
# Open the "Overlay dialog" and make the profile window have paper colours
navigate_dropdown(100,50,100,100)
# Enable axis labels
click_on(100,30)
# Enable "Paper Colours"
click_on(200,155)
# ... and close the dialog
click_on(30,30)
# Move the profile window and resize it
profile_window_id = xdotool "search --name 'Profile window for display window'"
xdotool "windowmove #{profile_window_id} #{geometry[0]-browser_width-4} #{600+16}"
xdotool "windowsize --sync #{profile_window_id} #{browser_width} #{geometry[1]-600-32}"
# and close the "View" dialog
click_on(30,30)
sleep $sleep_time


# Open the "Files" dialog and resize it
# On my machine, the button appears at 30,30
# This could be made more robust by finding the coordinate of the window and moving the mouse relatively
# Don't know why, but this needs to be done twice.
click_on(30,30)
click_on(30,30)
# Enable the pin option
click_on(225,995)
# Grab the id and resize it
files_window_id = xdotool "search --name 'Array File Selector'"
xdotool "windowsize --sync #{files_window_id} #{browser_width} #{geometry[1]-30}"

# Move and resize the browser window
browser_window_id = xdotool "search --name 'Browser.*for display window'"
xdotool "windowmove --sync #{browser_window_id} #{geometry[0]-browser_width-4} 14"
xdotool "windowsize --sync #{browser_window_id} #{browser_width} 600"

# Move and resize the main kvis window
case options[:layout]
when "wide"
    xdotool "windowmove --sync #{kvis_window_id} 0 14"
    xdotool "windowsize --sync #{kvis_window_id} 1400 700"
else
    puts "*** kvis-setup.rb: Layout specified is not recognised; defaulting to 'square'." unless options[:layout] == "square"
    xdotool "windowmove --sync #{kvis_window_id} #{500+4} 14"
    xdotool "windowsize --sync #{kvis_window_id} 800 800"
end

# Return the mouse to where we started
xdotool "mousemove #{original_mouse_pos}"
