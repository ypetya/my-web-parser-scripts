require 'open-uri'
require 'hpricot'
DIR = "/home/#{ENV['USER']}"

puts "Default dir: '#{DIR}/tmp/pictures/search_term'"

def get_pics search_term = 'sexy+volleyball', pics_on_page = 24 
  the_dir = File.join(DIR, "tmp", "pictures", search_term)
  doc_main = open("http://flickr.com/search/?q=#{search_term}") { |f| Hpricot(f) }
    count =  doc_main.search('div.Found').search('strong').text.gsub(/,/,'').to_i
    puts "Found #{count} pictures on flickr."
    if count > 0
      FileUtils.mkdir_p(the_dir)
      page = 1
      (count/pics_on_page + 1).to_i.times do
        doc = open("http://flickr.com/search/?q=#{search_term}&page=#{page}") { |f| Hpricot(f) } 
        doc.search('img.pc_img').each do |image|
          src = image[:src].sub(/_m\.jpg/, '.jpg')
          filename = "page#{page}_#{File.basename(src)}"
          File.open(File.join(the_dir, filename), "wb") { |f| open(src) {|i| f << i.read} }
          print "."
          $stdout.flush
        end
        page = page +1
      end
    end
  puts " done."
end
