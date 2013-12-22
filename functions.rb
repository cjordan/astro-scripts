#!/usr/bin/env ruby

class Astro
    def self.overwrite?(file,force=false,ignore=false)
        # checks if file or directory already exists, and prompts the user to overwrite or abort.
        if force
            FileUtils.rm_rf(file)
        elsif File.exists?(file)
            return false if ignore
            puts "\n*** This file (#{file}) already exists! Overwrite? [Yn]"
            response = STDIN.gets.chomp
            if (response == "" or response.downcase == "y")
                FileUtils.rm_rf(file)
                puts "*** Old file deleted.\n"
            else
                puts "*** Keeping old file.\n"
                return false
            end
        end
        return true
    end

    def self.fitsfile?(f)
        true if f.include? '.fits' and File.file?(f)
    end

    def self.cotra_radec(gc)
        # from a [GC_long,GC_lat] input, generates a [RA,Dec] output
        output = `cotra type=galactic radec="#{gc.join(',')}"`
        return output.scan(/J2000:\s*(\d+:\d+:\d+\.\d+)\s+(-?\d+:\d+:\d+\.\d+)/)[0]
    end

    def self.cotra_gc(radec)
        # from a [RA,Dec] input, generates a [GC_long,GC_lat] output
        output = `cotra type=j2000 radec="#{radec.join(',')}"`
        return output.scan(/Galactic:\s*(\d+\.\d+)\s+(-?\d+\.\d+)/)[0]
    end

    def self.radec_to_deg(radec_pair)
        # from a [RA,Dec] input {(-)xx:xx:xx.xxx format}, outputs a float array of the input in degrees
        abort("Input array is not of size 2.") if not radec_pair.length == 2
        return radec_pair.map{|c| c.split(":").map{|c| c.to_f.abs}.zip([1,1.0/60,1.0/3600]).map{|c| c.first*c.last}.inject{|total,c| total+c}}.zip([15,radec_pair[1].include?("-") ? -1 : 1]).map{|c| c.first*c.last}

        # the following is slightly faster, but dirty.
        # result = []
        # radec_pair.each do |c|
        # 	match = c.scan(/(-?)(\d+):(\d+):(\d+\.\d+)/)[0]
        # 	match[0] = match[0] == "-" ? -1 : 1
        # 	result[result.length] = match[0]*(match[1].to_f + match[2].to_f/60 + match[3].to_f/3600)
        # end
        # result[0] = result[0]*15
        # return result
    end

    def self.gc_to_hms(gc)
        # from a [GC_long,GC_lat] input, outputs a colon formatted HMS version in an array
        output = gc.map{|c| [c.truncate,c.abs.remainder(1)*60]}.map{|c| [sprintf("%02d",c[0]),sprintf("%02d",c[1]),sprintf("%.3f",c[1].remainder(1)*60)].join(":")}
        output[1] = "-" + output[1] if gc[1] < 0
        return output
    end

    def self.radec_to_hms(radec_pair)
        # from a [RA,Dec] input {(-)x.x format}, outputs a string of the input in conventional RADec format
        abort("Input array is not of size 2.") if not radec_pair.length == 2
        result = radec_pair.map{|c| c.to_s}
        result[0] = "#{sprintf("%02d",radec_pair[0]/15)}:#{sprintf("%02d",(radec_pair[0]/15)%1*60)}:#{sprintf("%09f",((radec_pair[0]/15)%1*60)%1*60)}"
        # this line is used if the hms format is desired for declination. for accuracy purposes, we do not convert it here.
        #result[1] = "#{sprintf("%02d",radec_pair[1])}:#{sprintf("%02d",(1-radec_pair[1]%1)*60)}:#{sprintf("%09f",(1-radec_pair[1]%1*60%1)*60)}"
        return result
    end

    def self.offset(co_ord,ref)
        # takes a RADec pair and subtracts a reference, all in degrees
        # output format: [(-)x.xxxx,(-)x.xxxx]
        return co_ord.zip(ref.map{|c| c.to_f}).map{|e| e.first - e.last}.map{|c| sprintf("%.6f", c)}
    end
end
