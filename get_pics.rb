require 'open-uri'
require 'hpricot'
# last updated : 2011-09-22
DIR = "/home/#{ENV['USER']}"

puts "Default dir: '#{DIR}/tmp/pictures/search_term'"

SEARCH = "http://flickr.com/search/?q="
IMG = 'img.pc_img'

def get_pics search_term = 'sexy+volleyball'
  the_dir = File.join(DIR, "tmp", "pictures", search_term)
  doc_main = open("#{SEARCH}#{search_term}") { |f| Hpricot(f) }
    count =  doc_main.search('div.Results').text.gsub(/[,()]/,'').to_i
    puts "Found #{count} pictures on flickr. On #{pics_on_page=doc_main.search(IMG).count} pages."
    if count > 0
      FileUtils.mkdir_p(the_dir)
      page = 1
      (count/pics_on_page + 1).to_i.times do
        doc = open("#{SEARCH}#{search_term}&page=#{page}") { |f| Hpricot(f) } 
        doc.search(IMG).each do |image|
          src = image[:src].sub(/_t\.jpg/, '.jpg')
          filename = "page#{page}_#{File.basename(src)}"
          unless File.exists? tf=File.join(the_dir, filename)
            File.open(tf, "wb") { |f| open(src) {|i| f << i.read} }
            print "+"
          else
            print "-"
          end
          $stdout.flush
        end
        page = page +1
      end
    end
  puts " done."
end
