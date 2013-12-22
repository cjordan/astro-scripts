#!/usr/bin/env ruby

require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
	opts.banner = "Converts red, green, blue and yellow 'plus' annotation symbols from kvis eps files to some shape. Accepts multiple files, and writes to the current directory.\nShapes include 'cross', 'plus', 'circle' and 'none'."

	opts.on('-h','--help','Display this message') {puts opts; exit}

	opts.on('-r','--red SHAPE','Convert red + symbols to a shape (cross, plus, circle)') do |s|
		options[:red] = [s," 1.0000   0.0000   0.0000  setrgbcolor\n","Red"]
	end

	opts.on('-g','--green SHAPE','Convert green + symbols to a shape') do |s|
		options[:green] = [s," 0.0000   1.0000   0.0000  setrgbcolor\n","Green"]
	end

	opts.on('-b','--blue SHAPE','Convert blue + symbols to a shape') do |s|
		options[:blue] = [s," 0.0000   0.0000   1.0000  setrgbcolor\n","Blue"]
	end

	opts.on('-y','--yellow SHAPE','Convert yellow + symbols to a shape') do |s|
		options[:yellow] = [s," 1.0000   1.0000   0.0000  setrgbcolor\n","Yellow"]
	end

	opts.on('-p','--pink SHAPE','Convert pink + symbols to a shape') do |s|
		options[:pink] = [s," 1.0000   0.7529   0.7961  setrgbcolor\n","Pink"]
	end

	options[:weight1] = "1.0e0"
	opts.on('--weight1 WEIGHT','Weight of the primary colour (default white). Handles scientific notation (eg. default: 1.0e0)') {|w1| options[:weight1] = w1}
	options[:weight2] = "3.0e-1"
	opts.on('--weight2 WEIGHT','Weight of the secondary colour (default black, value: 3.0e-1)') {|w2| options[:weight2] = w2}

	options[:size] = 2.5
	opts.on('--size SIZE','Size of circles (default 2)') {|s| options[:size] = s}

	opts.on('-s','--switch','Switch the primary and secondary colours to black and white, respectively') {|s| options[:switch?] = true}

	opts.on('-i','--interactive','As + symbols are parsed, choose if you want to include it or not') {|i| options[:interactive?] = true}

	# options[:file?] = false; options[:file] =
	# opts.on('-o','--output file_name','Output file name') {|o| options[:file?] = true; options[:file] = o}
end.parse!

def capture_lines(line_array,start_line,end_line)
	output = [line_array.index(start_line)]
	return nil if output == [nil]
	output[1] = output[0]
	line_array[output[0]+1..-1].each do |l|
		break if l.match(end_line)
		output[1] += 1
	end
	return output
end

def cross(str1,str2)
	str1_s = str1.split(" ")
	str2_s = str2.split(" ")
	x_min = str1_s[3].to_f
	x_max = str1_s[0].to_f
	y_min = str2_s[4].to_f
	y_max = str2_s[1].to_f
	x = (x_min + x_max)/2
	y = (y_min + y_max)/2
	scaler = 2**-0.5
	n_x_min = x + (x_min-x)*scaler
	n_x_max = x + (x_max-x)*scaler
	n_y_min = y + (y_min-y)*scaler
	n_y_max = y + (y_max-y)*scaler
	return sprintf("    %.5f  %.5f M %.5f  %.5f D str\n    %.5f  %.5f M %.5f  %.5f D str\n",n_x_min,n_y_min,n_x_max,n_y_max,n_x_min,n_y_max,n_x_max,n_y_min)
end

def plus(str1,str2)
	return "    #{str1}    #{str2}\n"
end

def circle(str,size)
	str_s = str.split(" ")
	x = (str_s[0].to_f+str_s[3].to_f)/2
	y = str_s[1]
	return sprintf("    %.5f  %.5f  %.2f  0 360 arc closepath stroke\n",x,y,size)
end

def bw_append(shape,lines,options,colour)
	def comment(replace,line_array,start_line,end_line)
		(start_line..end_line).each {|l| replace.sub!(/^(#{line_array[l]})/,"%  \\1")}
		# replace = "%  #{replace[l]}"
		return replace
	end

	def str_pair?(str1,str2)
		str1_s = str1.split(" ")
		str2_s = str2.split(" ")
		return false if ((str1_s[0].to_f+str1_s[3].to_f)/2 - (str2_s[0].to_f+str2_s[3].to_f)/2).abs > 0.00001
		return false if ((str1_s[1].to_f+str1_s[4].to_f)/2 - (str2_s[1].to_f+str2_s[4].to_f)/2).abs > 0.00001
		return true
	end

	header = "\n%% #{colour} plus symbols\n"
	header1 = options[:switch?] ? "0.0000   0.0000   0.0000  setrgbcolor\n" : "1.0000   1.0000   1.0000  setrgbcolor\n"
	header2 = options[:switch?] ? "\n1.0000   1.0000   1.0000  setrgbcolor\n" : "\n0.0000   0.0000   0.0000  setrgbcolor\n"
	header1 << options[:weight1] << " setlinewidth\n"
	header2 << options[:weight2] << " setlinewidth\n"

    replace = options[:annotations].join()
    replace = comment(replace,options[:annotations],lines[0],lines[1])
	string = ""

	(lines[0]+1..lines[1]).each do |i|
		next unless str_pair?(options[:annotations][i],options[:annotations][i+1])
		string << cross(options[:annotations][i],options[:annotations][i+1]) if shape == "cross"
		string << plus(options[:annotations][i],options[:annotations][i+1]) if shape == "plus"
		string << "stroke" << circle(options[:annotations][i],options[:size]) if shape == "circle"
		string << "" if shape == "none"
	end

	replace << header << header1 << string << header2 << string
	return replace
end


ARGV.each do |file|
	original = File.basename(file)
	matches = original.match(/(.*)\.(.*)/)
	options[:file] = "#{matches[1]}_modified.#{matches[2]}"

	options[:line_array] = File.readlines(file)

    end_of_header = options[:line_array].index("grestore\n")
    options[:header] = options[:line_array][0..end_of_header]
    options[:annotations] = options[:line_array][end_of_header+1..-1]


	[options[:red],
        options[:green],
        options[:blue],
        options[:yellow],
        options[:pink]].each do |colour|
		next if not colour
		while (lines = capture_lines(options[:annotations],colour[1],".*(setrgbcolor|setlinewidth)")) != nil
            puts "Found #{lines[1]/2} of #{colour[2]}."
			options[:annotations] = bw_append(colour[0],lines,options,colour[2])
            options[:annotations] = options[:annotations].split("\n").each {|a| a << "\n"}
		end
	end
	File.open(options[:file],"w") {|f| f.puts options[:header] + options[:annotations]}
	puts "Updated file: #{options[:file]}"
end
