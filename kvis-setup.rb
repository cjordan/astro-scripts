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

def get_window_id(search_string)
    xdotool "search --name '#{search_string}'"
end

def get_geometry(id)
    # xdotool does not report the position of windows correctly - use xwininfo instead
    (`xwininfo -id #{id}`).scan(/Absolute.*:\s*(\d*)/).flatten.map{|n| n.to_i}
end

def get_win_decorator_height(id)
    output = (`xwininfo -id #{id}`).scan(/^.*Y:\s*(\d*)/).flatten.map{|n| n.to_i}
    return output[0] - output[1]
end

def get_top_bar_height(id)
    (`xwininfo -id #{id}`).scan(/Relative.*Y:\s*(\d*)/)[0][0].to_i
end

def click_on(id,x,y)
    # Get the geometry of this window id
    geometry = get_geometry(id)
    # Add the [x,y] passed in by geometry to x1, y1, x2, y2
    x += geometry[0]
    y += geometry[1]
    # Move the mouse to x,y, then click
    xdotool "mousemove #{x} #{y}"
    xdotool "click 1"
    sleep $sleep_time
end

def navigate_dropdown(id,x1,y1,x2,y2)
    # Get the geometry of this window id
    geometry = get_geometry(id)
    # Add the [x,y] passed in by geometry to x1, y1, x2, y2
    x1 += geometry[0]
    y1 += geometry[1]
    x2 += geometry[0]
    y2 += geometry[1]
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


## Get some information on the desktop so we can place windows neatly at the edges
# Record the mouse position so we can reset it when done
original_mouse_pos = (xdotool "getmouselocation").scan(/:(\d*)/)[0..1].join(' ')
# Move the mouse to somewhere very far away...
xdotool "mousemove 5000 5000"
# The mouse will only move as far away as the desktop allows, so now we have the screen geometry
screen_geometry = (xdotool "getmouselocation").scan(/:(\d*)/)[0..1].flatten.map{|n| n.to_i}

# Find the main kvis window and select it
kvis_id = get_window_id("kvis.*Karma")
# Raise the window
# This will not work on all window managers - however, all is fine if kvis is on top
xdotool "windowraise #{kvis_id}"

# Get the window decorator height
win_dec_height = get_win_decorator_height(kvis_id)
# Window manager top bar height
top_bar_height = get_top_bar_height(kvis_id)


## Window formatting variables
# Array browser (sitting on the right)
browser_width = 500
browser_height = 600

# File browser (sitting on the left)
file_width = 500
file_height = screen_geometry[1] - 2*top_bar_height - win_dec_height - 2

# Main kvis window - "profile" selection
case options[:layout]
when "wide"
    kvis_width = 1400
    kvis_height = 700
    kvis_pos_x = 0
    kvis_pos_y = top_bar_height
else
    puts "*** kvis-setup.rb: Layout specified is not recognised; defaulting to 'square'." unless options[:layout] == "square"
    kvis_width = 800
    kvis_height = 800
    kvis_pos_x = file_width+2
    kvis_pos_y = top_bar_height
end


## Axis labels and Paper colours
# Open "Axis labels" from the "Overlay" dialog...
navigate_dropdown(kvis_id,230,15,230,65)
# Find the "Axis labels" window
axis_id = get_window_id("dressingControlPopup")
# Enable axis labels
click_on(axis_id,100,15)
# Enable "Paper Colours"
click_on(axis_id,200,140)
# ... and close the dialog
click_on(axis_id,30,15)


## Colour scheme
# Open "PseudoColour" from the "Intensity" dialog...
navigate_dropdown(kvis_id,100,15,100,65)
# Find the "PseudoColour" window
pseudo_id = get_window_id("pseudoCmapwinpopup")
# Disable "Reverse" from "Paper Colours"
click_on(pseudo_id,130,15)
# Use the "Glynn Rogers 2" profile
click_on(pseudo_id,230,295)
# ... and close the dialog
click_on(pseudo_id,30,15)


## Spectrum "profile" window
# Open the "View" dialog...
click_on(kvis_id,365,15)
# Find the "View" window
view_id = get_window_id("View Control for display window")
# Enable "Show Marker in Line Profile"
click_on(view_id,100,115)
# Select "Box Sum" from the "Profile Mode" list...
navigate_dropdown(view_id,200,40,200,115)
# Find the "Profile" window
profile_id = get_window_id("Profile Window for display window")
# Enable "Auto V Zoom"
click_on(profile_id,100,15)
# Make the style "hist"
navigate_dropdown(profile_id,280,40,280,90)
# Open the "Overlay dialog" and make the profile window have paper colours
navigate_dropdown(profile_id,100,40,100,90)
# Find the "Axis labels" window
# Unfortunately, by default this will find the previous "Axis" window, even though it's closed
axis2_id = get_window_id("dressingControlPopup").split("\n")[1]
# Enable axis labels
click_on(axis2_id,100,15)
# Enable "Paper Colours"
click_on(axis2_id,200,140)
# ... and close the dialog
click_on(axis2_id,30,15)
# Move the profile window and resize it
xdotool "windowsize --sync #{profile_id} #{browser_width} #{screen_geometry[1] - 2*top_bar_height - browser_height - 2*win_dec_height - 4}"
xdotool "windowmove #{profile_id} #{screen_geometry[0]-browser_width-2} #{top_bar_height + browser_height + 2*win_dec_height + 2}"
# and close the "View" dialog
click_on(view_id,30,15)


# Open the "Files" dialog and resize it
# Don't know why, but this needs to be done twice.
click_on(kvis_id,30,15)
click_on(kvis_id,30,15)
# Find the "Files" window
files_id = get_window_id("Array File Selector")
# Enable the pin option
click_on(files_id,225,965)
# Resize it
xdotool "windowsize --sync #{files_id} #{file_width} #{file_height}"


# Move and resize the browser window
browser_id = get_window_id("Browser.*for display window")
xdotool "windowsize --sync #{browser_id} #{browser_width} #{browser_height}"
xdotool "windowmove --sync #{browser_id} #{screen_geometry[0]-browser_width-2} #{top_bar_height}"

# Move and resize the main kvis window
xdotool "windowsize --sync #{kvis_id} #{kvis_width} #{kvis_height}"
xdotool "windowmove --sync #{kvis_id} #{kvis_pos_x} #{kvis_pos_y}"

# Return the mouse to where we started
xdotool "mousemove #{original_mouse_pos}"
