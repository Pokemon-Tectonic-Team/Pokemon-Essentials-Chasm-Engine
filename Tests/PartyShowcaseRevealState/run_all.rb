# Runs every *_test.rb in this directory together: `ruby run_all.rb`.
Dir[File.join(__dir__, "*_test.rb")].sort.each { |f| require f }
