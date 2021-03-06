require 'csv'
require 'longurl'
require 'fileutils'

#check whether user is in directory the file is in
puts 'What is the name of the file you want to work with? (Include the .csv extension.)'
file_name = gets.chomp
if !File.exists?(file_name)
	abort('Sorry, you are not in the right directory. Change to that directory and run the script again.')
end
puts 'Which proposition are you working on?'
prop_num = gets.chomp

#make array to store http links
http_array = []

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
				if substring.length > 20
					substring = substring[0...-(substring.length-20)]
					http_array.push(substring)
				else
					substring = ''
				end
			end
		end
	end
end

puts 'Going to expand ' + http_array.length.to_s + ' links' 

i = 0
expanded_links = []
errors = []
puts 'Expanding links...'
http_array.each do |link|
	begin
		expanded_links[i] = LongURL.expand(link)
		while expanded_links[i] != LongURL.expand(expanded_links[i]) do
			expanded_links[i] = LongURL.expand(expanded_links[i]) 
		end
		i += 1
		if i % 100 == 0 then puts i end
		rescue LongURL::NetworkError => ne
			puts 'Network error; waiting, then trying again'
			errors.push(ne)
			sleep(5)
		rescue LongURL::InvalidURL, LongURL::UnknownError => e
			puts 'Link expanding failed; moving on'
			puts e.message + ' at ' + i.to_s
			errors.push(e)
	end
end

puts 'Expanded links with ' + errors.length.to_s + ' errors'

frequencies = Hash.new(0)
expanded_links.each { |url| frequencies[url] += 1 }
frequencies = frequencies.sort_by { |a, b| b }
frequencies.reverse!

#output hash to CSV
path = FileUtils.pwd
FileUtils.mkdir_p(path) unless File.exists?(path)
new_file = File.new(path + '/Expanded_URLs_for_Prop_' + prop_num + '.csv', 'w')
csv_string = CSV.generate do |csv|
  frequencies.each do |key, value|
    csv << [key, value]
  end
end
new_file.write(csv_string)
new_file.close