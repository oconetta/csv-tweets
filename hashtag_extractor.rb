require 'csv'
require 'fileutils'

#check whether user is in directory the file is in
puts 'What is the name of the file you want to work with? (Include the .csv extension.)'
file_name = gets.chomp
if !File.exists?(file_name)
	abort('Sorry, you are not in the right directory. Change to that directory and run the script again.')
end
puts 'Which proposition are you working on?'
prop_num = gets.chomp

#make array to store hashtags
hashtag_array = []

#method to get first character of string
class String
	def initial
		self[0,1]
	end
end

#check for and get rid of missing/stray quotes
text = File.read(file_name)
text = text.gsub(/\\\"/, "\"\"")

#iterate through CSV sheet
CSV.parse(text, {:col_sep => ',', :quote_char => '"'}) do |row|
	#if the row includes a hyperlink...
	if row[4].include?('#')
		#split the row by whitespace; add to array
		strings = row[4].split(" ")
		#go through array of strings
		strings.each do |substring|
			#if the substring includes and begins with a #, add it to array
			if substring.include?('#') && substring.initial == '#'
				#get rid of extraneous non-alphanumeric characters
				substring = substring.gsub(/[^0-9a-z ]/i, '')
				hashtag_array.push(substring)
			end
		end
	end
end

#sort hashtags by frequency
frequencies = Hash.new(0)
hashtag_array.each { |hashtag| frequencies[hashtag] += 1 }
frequencies = frequencies.sort_by { |a, b| b }
frequencies.reverse!

#output hash to CSV
path = FileUtils.pwd
FileUtils.mkdir_p(path) unless File.exists?(path)
new_file = File.new(path + '/Hashtag_Counts_for_Prop_' + prop_num + '.csv', 'w')
csv_string = CSV.generate do |csv|
  frequencies.each do |key, value|
    csv << [key, value]
  end
end
new_file.write(csv_string)
new_file.close