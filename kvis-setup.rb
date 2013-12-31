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

    options[:layout] = "wide"
    opts.on('-l','--layout STR','Specify the layout. Supported orientations are:
                                     - \'square\'
                                     - \'wide\'
                                     Default is \'wide\'') {|o| options[:layout] = o}

    opts.on('-d','--debug','Prints the commands being sent to xdotool.') {$debug = true}
end.parse!


## Common "Window" class - all kvis windows inherit these properties
class Window
    # Pass in the window id so we know which window to work upon
    def initialize(id)
        @id = id
        # Resize the window to "default" if it is not already this size
        xdotool "windowsize --sync #{@id} #{@default.join(' ')}" unless get_geometry(@id) == @default
    end
    # Raise this window above all others (will not work for all window managers)
    def raise
        xdotool "windowraise #{@id}"
    end
    # Move this window to new coordinates (x,y)
    def move(x,y)
        xdotool "windowmove --sync #{@id} #{x} #{y}"
    end
    # Resize this window to geometry (x,y)
    def size(x,y)
        xdotool "windowsize --sync #{@id} #{x} #{y}"
    end
    # Closes the current window
    # Use with care - the coordinates of the button must be specified per window.
    # If this is run without "close" properly defined, the script will exit prematurely.
    def close
        abort("#{File.basename(__FILE__)}: Window #{@id} did not close - your settings may need adjusting. Exiting...") if win_is_open?(@id)
    end
end

## Primary kvis window
class Kvis < Window
    def initialize(id)
        # Default window size. Resize if necessary.
        @default = [522,614]
        super
    end
    # Open the Files window
    def files
        click_on(@id,30,15)
    end
    # Opens up an element from the Intensity menu
    def intensity(element)
        case element.downcase
        when "pseudo"
            navigate_dropdown(@id,100,15,100,65)
        end
    end
    # Opens up an element from the Overlay menu
    def overlay(element)
        case element.downcase
        when "axis"
            navigate_dropdown(@id,230,15,230,65)
        when "annotation"
            navigate_dropdown(@id,230,15,230,160)
        end
    end
    # Open the View window
    def view
        click_on(@id,365,15)
    end
end

## Browser window
class Browser < Window
    def initialize(id)
        @default = [439,588]
        super
    end
    def close
        click_on(@id,30,15)
        super
    end
end

## Axis Labels window
class Axis < Window
    def initialize(id)
        @default = [344,331]
        super
    end
    def close
        click_on(@id,30,15)
        super
    end
    def enable
        click_on(@id,100,15)
    end
    def paper_colours
        click_on(@id,200,140)
    end
end

## PseudoColour window
class Pseudo < Window
    def initialize(id)
        @default = [418,393]
        super
    end
    def close
        click_on(@id,30,15)
        super
    end
    def reverse
        click_on(@id,130,15)
    end
    def glynn_rogers2
        click_on(@id,230,295)
    end
end

## View window
class View < Window
    def initialize(id)
        @default = [460,249]
        super
    end
    def close
        click_on(@id,30,15)
        super
    end
    def marker
        click_on(@id,100,115)
    end
    def profile(element)
        case element.downcase
        when "line"
            navigate_dropdown(@id,200,40,200,90)
        when "box_sum"
            navigate_dropdown(@id,200,40,200,115)
        end
    end
end

## Profile window
class Profile < Window
    def initialize(id)
        @default = [442,436]
        super
    end
    def close
        click_on(@id,30,15)
        super
    end
    def v_zoom
        click_on(@id,100,15)
    end
    def style(element)
        case element.downcase
        when "hist"
            navigate_dropdown(@id,280,40,280,90)
        end
    end
    def overlay(element)
        case element.downcase
        when "axis"
            navigate_dropdown(@id,100,40,100,90)
        end
    end
end

## Files window
class Files < Window
    def initialize(id)
        # The Files window is special - it will size itself according to the files in the pwd.
        # Resize it here so the button placement is predictable.
        @default = [400,400]
        super
    end
    def close
        click_on(@id,30,360)
        super
    end
    def pin
        click_on(@id,220,360)
    end
end


def xdotool(command)
    puts "\n#{command}" if $debug
    # Run xdotool with the specified command in a shell.
    # "strip" is necessary for pesky newlines
    `xdotool #{command}`.strip
end
def get_window_id(search_string)
    (xdotool "search --name '#{search_string}'").split("\n")[-1]
end
def click_on(id,x,y)
    # Get the position of this window id
    position = get_position(id)
    # Add the [x,y] passed in by get_position to our x and y
    x += position[0]
    y += position[1]
    # Move the mouse to (x,y), then click
    xdotool "mousemove #{x} #{y}"
    xdotool "click 1"
    sleep $sleep_time
end
def navigate_dropdown(id,x1,y1,x2,y2)
    # Get the position of this window id
    position = get_position(id)
    # Add the [x,y] passed in by position to x1, y1, x2, y2
    x1 += position[0]
    y1 += position[1]
    x2 += position[0]
    y2 += position[1]
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

def get_position(id)
    (`xwininfo -id #{id}`).scan(/Absolute.*:\s*(\d*)/).flatten.map{|n| n.to_i}
end
def get_geometry(id)
    (`xwininfo -id #{id}`).scan(/(Width|Height):\s*(\d*)/).map{|n| n[1].to_i}
end
def get_win_decorator_height(id)
    (`xwininfo -id #{id}`).scan(/^.*Y:\s*(\d*)/).flatten.map{|n| n.to_i}.reduce(:-)
end
def get_top_bar_height(id)
    (`xwininfo -id #{id}`).scan(/Relative.*Y:\s*(\d*)/)[0][0].to_i
end
def win_is_open?(id)
    (`xwininfo -id #{id}`).match(/Map State:\s*(IsViewable)/) ? true : false
end


# Record the mouse position so we can reset it when done
original_mouse_pos = (xdotool "getmouselocation").scan(/:(\d*)/)[0..1].join(' ')

# Get the desktop geometry so we can place windows neatly at the edges
screen_geometry = (`xwininfo -root`).scan(/(Width|Height):\s*(\d*)/).map{|n| n[1].to_i}


## Window manipulation
# From the main kvis window, open the Axis Labels window
kvis = Kvis.new(get_window_id("kvis.*Karma"))
kvis.raise
kvis.overlay("axis")

# Set axis labels to be enabled, along with paper colours
axis = Axis.new(get_window_id("dressingControlPopup"))
axis.enable
axis.paper_colours
axis.close

# Set the colour scale to by "Glynn Rogers2", and disable the "Reverse" option
kvis.intensity("pseudo")
pseudo = Pseudo.new(get_window_id("pseudoCmapwinpopup"))
pseudo.reverse
pseudo.glynn_rogers2
pseudo.close

# Open the View window and enable "Show Marker in Line Profile"
kvis.view
view = View.new(get_window_id("View Control for display window"))
view.marker
# Open the "Box Sum" profile
view.profile("box_sum")

# Enable "Auto V Zoom" and set the "Style" to "hist"
profile = Profile.new(get_window_id("Profile Window for display window"))
profile.v_zoom
profile.style("hist")
# Open the Axis Labels window for the profile window
profile.overlay("axis")

# Enable Axis Labels and paper colours
axis = Axis.new(get_window_id("dressingControlPopup"))
axis.enable
axis.paper_colours
axis.close

# Close the View window
view.raise
# *** This is a workaround until I can get dwm to play nicely with raising windows
view.move(screen_geometry[0]-50, 0)
view.close
# *** This is a workaround until I can get dwm to play nicely with raising windows
profile.move(screen_geometry[0]-50, screen_geometry[1]-50)

# Open the Files window
kvis.raise
kvis.files
files = Files.new(get_window_id("Array File Selector"))
# Set the Pin option
files.pin


## Window formatting variables
kvis_id = get_window_id("kvis.*Karma")
# Window decorator height
win_dec_height = get_win_decorator_height(kvis_id)
# Window manager top bar height - this assumes the main kvis window is positioned just beneath it
top_bar_height = get_top_bar_height(kvis_id)

# Files window (sitting on the left)
files_width = 500
files_height = screen_geometry[1] - 2*top_bar_height - win_dec_height - 4
files_x = 0
files_y = top_bar_height

# Main kvis window - "profile" selection
case options[:layout]
when "square"
    kvis_width = 800
    kvis_height = 800
    kvis_x = files_width + 2
    kvis_y = top_bar_height
else
    puts "*** kvis-setup.rb: Layout specified is not recognised; defaulting to 'wide'." unless options[:layout] == "wide"
    kvis_width = 1400
    kvis_height = 700
    kvis_x = 0
    kvis_y = top_bar_height
end

# Browser (sitting on the right)
browser_width = 500
browser_height = 600
browser_x = screen_geometry[0] - browser_width - 4
browser_y = top_bar_height

# Profile window (sitting on the right)
profile_width = browser_width
profile_height = screen_geometry[1] - 2*top_bar_height - browser_height - 2*win_dec_height - 6
profile_x = screen_geometry[0] - browser_width - 4
profile_y = top_bar_height + browser_height + 2*win_dec_height + 2


## Move and resize all the windows
kvis.size(kvis_width, kvis_height)
kvis.move(kvis_x, kvis_y)

files.size(files_width, files_height)
files.move(files_x, files_y)

browser = Browser.new(get_window_id("Browser.*for display window"))
browser.size(browser_width, browser_height)
browser.move(browser_x, browser_y)

profile.size(profile_width, profile_height)
profile.move(profile_x, profile_y)


## Return the mouse to where we started
xdotool "mousemove #{original_mouse_pos}"

## Done!
