#!/usr/bin/env ruby

# A script for common momenting and binning MIRIAD tasks.
# Current issues:
#   - peach would be great for each moment/bin operation,
#     but output strings have race conditions associated.

require 'optparse'
require 'fileutils'
require 'peach'

# this line assumes that the library of functions is in the
# same dir as the script itself.
require "#{__FILE__.match(/(\/.*\/)/)}functions.rb"


options = {}
optparse = OptionParser.new do |opts|
    opts.banner = "Produces moment and binned maps of all input files to the current directory. fits files are converted to MIRIAD uv format.
e.g. moment.rb -i -m-2,0 -b5,10 <file>"

    opts.on('-h','--help','Display this message.') {puts opts; exit}

    options[:moment] = []
    opts.on('-m','--moment order NUM','Specify additional moments to be done. Multiple values accepted, comma separated. eg. 0,-1') {|o| options[:moment] = o.split(',')}

    options[:binning] = []
    opts.on('-b','--binning order NUM','Specify the order of binning to be done. Required. Multiple values accepted, comma separated. eg. 5,10') {|o| options[:binning] = o.split(',')}

    opts.on('-s','--smooth NUM,NUM','Smooth each moment map, from specified FWHM.') {|o| options[:smooth] = o}

    opts.on('-a','--axis NUM','Axis for which the moment is calculated. Use 2 for a lvb moment.') {|o| options[:axis] = o}

    opts.on('-f','--force','Overwrite existing files.') {options[:force?] = true}

    opts.on('-i','--ignore','Do not run MIRIAD for files that already exist.') {options[:ignore?] = true}

    opts.on('-q','--quiet','Suppress output from MIRIAD.') {options[:quiet?] = true}
end.parse!


class Uv_file
    def initialize(file,options)
        @orig = file
        @options = options
        @return_str = "\n*** moment.rb: Output for #{file}\n"
        if Astro.fitsfile?(file)
            @uv = File.basename(@orig).match(/(.*)\.fits/)[1]
            self.uv_convert
        else
            @uv = @orig
        end
    end
    attr_accessor :return_str
    def uv_convert
        if Astro.overwrite?(@uv,@options[:force?],@options[:ignore?])
            @return_str << `fits in=#{@orig} out=#{@uv} op=xyin 2>&1`
        elsif @options[:ignore?]
            @return_str << "\n*** Ignoring #{@uv}\n"
        end
    end
    def bin(chans,f=@uv)
        binned = "#{File.basename(f)}.bin#{chans}"
        if Astro.overwrite?(binned,@options[:force?],@options[:ignore?])
            @return_str << "\n*** #{binned}" << `imbin in=#{f} out=#{binned} bin=1,1,1,1,#{chans},#{chans} 2>&1`
        elsif @options[:ignore?]
            @return_str << "\n*** Ignoring #{binned}\n"
        end
        return binned
    end
    def moment(order,f=@uv)
        mom = "#{File.basename(f)}.mom#{order}"
        if Astro.overwrite?(mom,@options[:force?],@options[:ignore?])
            @return_str << "\n*** #{mom}" << `moment in=#{f} out=#{mom} mom=#{order} 2>&1` unless @options[:axis]
            @return_str << "\n*** #{mom}" << `moment in=#{f} out=#{mom} mom=#{order} axis=#{@options[:axis]} 2>&1` if @options[:axis]
            if @options[:smooth]
                smooth = "#{mom}.smooth"
                Astro.overwrite?(smooth,@options[:force?],@options[:ignore?])
                @return_str << "\n*** #{smooth}" << `smooth in=#{mom} out=#{smooth} type=gaussian,gaussian fwhm=#{@options[:smooth]} 2>&1`
            end
        elsif @options[:ignore?]
            @return_str << "\n*** Ignoring #{mom}\n"
        end
    end
    def output
        puts @return_str << "\n\n"
    end
end


abort("\n*** moment.rb: Cannot have force and ignore options enabled simultaneously! Exiting...\n") if options[:force?] and options[:ignore?]

ARGV.peach(4) do |f|
    current = Uv_file.new(f,options)
    options[:moment].each {|m| current.moment(m)} if options[:moment]
    current.output unless options[:quiet?]
    options[:binning].each do |b|
        binned = Uv_file.new(current.bin(b),options)
        options[:moment].each {|m| binned.moment(m)} if options[:moment]
        binned.output unless options[:quiet?]
    end
end
