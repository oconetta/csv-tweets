require 'rubygems'
require 'csv'

#check whether user is in directory the file is in
puts 'What is the name of the file you want to work with? (Include the .csv extension.)'
file_name = gets.chomp
if !File.exists?(file_name)
	abort('Sorry, you are not in the right directory. Run the script again.')
end

#since the file exists in that folder, open it
File.open(file_name)

#close the file
File.close()