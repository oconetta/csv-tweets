require 'csv'
require 'longurl'
require 'fileutils'
require 'pp'

#DEFINE METHODS

#method to get first character of string
class String
	def initial
		self[0,1]
	end
end

#method to take hyperlinks out of tweets
def extract_links(file, array)
	@file = file
	@array = array
	#check for and get rid of missing/stray quotes
	text = File.read(@file)
	text = text.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
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
					@array.push(substring)
				#but if string doesn't start with http (i.e., there are other characters before the link begins)
				elsif substring.include?('http://t.co/') && substring.length != 20 && substring.initial != 'h'
					substring_array = substring.partition('http://t.co/')
					partitioned_substring = substring_array[1] + substring_array[2]
					#if there's still an extraneous character at the end of the second part of the URL, get rid of it
					if partitioned_substring.length > 20
						#chop string down to 20 chars
						partitioned_substring = partitioned_substring[0...-(partitioned_substring.length-20)]
						@array.push(partitioned_substring)
					#otherwise, just add string to array
					else
						@array.push(partitioned_substring)
					end
				elsif substring.include?('http://t.co/') && substring.length != 20 && substring.initial == 'h'
					if substring.length > 20
						#chop substring from end of string if it's too long
						substring = substring[0...-(substring.length-20)]
						@array.push(substring)
					#or get rid of it if it's too short/fubar
					else
						substring = ''
					end
				end
			end
		end
	end
	return @array
end

def expand_links(array)
	@array = array

	puts 'Going to expand ' + @array.length.to_s + ' links' 

	#set counter at 0
	i = 0
	#set up arrays for expanded hyperlinks and errors
	@expanded = []
	@errors = []

	puts 'Expanding links...'

	#go through array of hyperlinks
	@array.each do |link|
		begin
			#expand links
			@expanded[i] = LongURL.expand(link)
			#expand link until it's expanded fully (so if first expanded link is a tinyurl link, it'll expand again)
			while @expanded[i] != LongURL.expand(@expanded[i]) do
				@expanded[i] = LongURL.expand(@expanded[i]) 
			end
			i += 1
			#prints progress occasionally
			if i % 100 == 0 then puts i end
			#handle errors from API so they don't crash the program
			rescue LongURL::NetworkError => ne
				puts 'Network error; waiting, then trying again'
				@errors.push(ne)
				sleep(5)
			rescue LongURL::InvalidURL, LongURL::UnknownError => e
				puts 'Link expanding failed; moving on'
				puts e.message + ' at ' + i.to_s
				@errors.push(e)
		end
	end
	#shows number of errors that occurred while process ran
	puts 'Expanded links with ' + @errors.length.to_s + ' errors'
	return @expanded
end

#method to chunk the array into a given amount of slices
class Array
	def chunk_by(num_slices)
		@num_slices = num_slices
		#returns an array of arrays
		if self.length.odd?
			half_length = self.length/@num_slices
			half_length = half_length + 0.1
			half_length = half_length.ceil
			self.each_slice(half_length).to_a
		else
			half_length = self.length/@num_slices
			self.each_slice(half_length).to_a
		end
	end
end

#method to sort frequencies of expanded links from array and return sorted hash
def sort_by_frequency(array)
	@array = array
	frequencies = Hash.new(0)
	@array.each { |url| frequencies[url] += 1 }
	frequencies = frequencies.sort_by { |a, b| b }
	frequencies.reverse!
	return frequencies
end

#method to write results of extraction and sorting to file
def write_to_CSV(hash)
	@hash = hash
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
	if File.exists?(path)
		puts 'CSV export successful!'
	else
		puts 'CSV export failed'
	end
end

#RUN PROGRAM

#check whether user is in directory the file is in
puts 'What is the name of the file you want to work with? (Include the .csv extension.)'
file_name = gets.chomp
if !File.exists?(file_name)
	abort('Sorry, you are not in the right directory. Change to that directory and run the script again.')
end
puts 'Which proposition are you working on?'
prop_num = gets.chomp

#make array to store http links; will pass to function
http_array = []
#make array to store expanded links
expanded_links = []

http_array = extract_links(file_name, http_array)
http_array = http_array.chunk_by(2)
pp http_array

#expand links in multiple threads
threads = []
first_thread = Thread.new { expanded_links[0] = expand_links(http_array[0]) }
threads.push(first_thread)
second_thread = Thread.new { expanded_links[1] = expand_links(http_array[1]) }
threads.push(second_thread)

#join threads
threads.each do |thr|
	t1 = Time.now
	thr.join
	t2 = Time.now
	puts t2-t1
end

expanded_links = expanded_links.flatten
expanded_links = expanded_links.sort_by_frequency
write_to_CSV(expanded_links)