require 'csv'
require 'pp'

#check whether user is in directory the file is in
puts 'What is the name of the file you want to work with? (Include the .csv extension.)'
file_name = gets.chomp
if !File.exists?(file_name)
	abort('Sorry, you are not in the right directory. Change to that directory and run the script again.')
end

#since the file exists in that folder, open it
File.open(file_name, 'r', :headers => :first_row)
#make array to store http links
http_array = []

#method to get first character of string
class String
	def initial
		self[0,1]
	end
end

#iterate through CSV sheet
CSV.foreach(file_name) do |row|
	#if the row includes a hyperlink...
	if row[4].include?('http://')
		#split the row by whitespace; add to array
		strings = row[4].split(" ")
		#go through array of strings
		strings.each do |substring|
			#if the strings in the array include a hyperlink and are the correct length...
			if substring.include?('http://t.co/') && substring.length == 20
				http_array.push(substring)
			#but if string doesn't start with http (i.e., there are other characters before the link begins)
			elsif substring.include?('http://t.co/') && substring.length != 20 && substring.initial != 'h'
				substring_array = substring.partition('http://t.co/')
				partitioned_substring = substring_array[1] + substring_array[2]
				#if there's still an extraneous character at the end of the second part of the URL, get rid of it
				if partitioned_substring.length > 20
					#chop string down to 20 chars
					partitioned_substring = partitioned_substring[0...-(partitioned_substring.length-20)]
					http_array.push(partitioned_substring)
				#otherwise, just add string to array
				else
					http_array.push(partitioned_substring)
				end
			elsif substring.include?('http://t.co/') && substring.length != 20 && substring.initial == 'h'
				#puts "Original substring in second elsif: #{substring}"
				#cut extraneous characters from end of string
				#add newly cut string to array
				#don't push the shorter links (under 20 chars) to array
				#puts "Substring after slice: #{substring}"
			end
		end
	end
end

#go through http_array
#expand links
#count # of times the same link occurs
#export these data to CSV

#close the file