require 'yaml'
require 'confluence_api'
require 'vimeo'
require 'tempfile'
require 'erb'

def prompt()
  print "> "
end

def login(config)
  @consumerKey = config["consumerkey"]
  @consumerSecret = config["consumersecret"]
  @token = config["token"]
  @tokenSecret = config["tokensecret"]
end

def start()
  config = YAML.load(File.read('etc/config.yaml'))
  login(config)
  client = Confluence.client config
  list_event_name_options()
  prompt; name = gets.chomp

  name         = sort_event_name(name)
  parent       = sort_event_parent(name)
  parent_id    = get_parent_id(parent, client)
  topic        = get_event_topic(name)
  date         = get_event_date()
  speaker      = get_event_speaker()
  keywords     = get_event_keywords()
  title        = event_recap(date, parent_id, name, speaker, topic, keywords)
  vimeo_id     = upload_video_to_vimeo(title)
  id           = create_confluence_page(parent, parent_id, title, vimeo_id, keywords, client) 
  set_confluence_labels(id, keywords)
  done         = done(parent, id)
  #  update_confluence_page(link, title, parent_id)
end

def list_event_name_options()
  puts "What is the name of the event?"
  puts "(A)ll Hands"
  puts "(B)ig Picture"
  puts "(D)emos"
  puts "(M)isc"
  puts "(U)X Design Review"
  puts "(T)SE"
  puts "U(X) Research"
end

def sort_event_name(name)
  while name.empty? || name.nil?
    puts "You gotta gimmie something to work with.  What event did you just watch?"
    prompt; name = gets.chomp
  end

  case name.downcase
  when "a"
    name = "All Hands"
  when "b"  
    name = "Big Picture"
  when "d"
    name = "Demos"
  when "u"
    name = "Design Review"
  when "m"
    name = "Misc"
  when "t"
    name = "TSE"
  when "x"
    name = "UX Research"
  else
    puts "What did you just say to me? (A)ll Hands. (B)ig Picture. (D)emos. (M)isc. (T)SE. (U)X Design Weekly, U(X) Research"
    prompt; name = gets.chomp
  end
  name
end

def sort_event_parent(name)
  case name
  when "All Hands"
    name_parent = "All Hands"
  when "Big Picture"
    name_parent = "Big Picture"
  when "Demos"
    name_parent = "Demos 2014"
  when "Design Review"
    name_parent = "Design Review"
  when "Misc"
    name_parent = "Misc"
  when "TSE"
    name_parent = "Misc"
  when "UX Research"
    name_parent = "UX Research Videos"
  else
    puts "What did you just say to me? (A)ll Hands. (B)ig Picture. (D)emos. (M)isc. (T)SE. (U)X Design Weekly, U(X) Research."
    prompt; name = gets.chomp
    sort_event_name(name)
  end
  name_parent
end

def get_parent_id(name_parent, client)
  if name_parent == "UX Research Videos"
  parent_id = client.get_id_from_title_and_space(name_parent, "UX")
  else
  parent_id = client.get_id_from_title_and_space(name_parent, "VID")
  end
end

def get_event_topic(name)
  if name == "All Hands"
    topic = ""
  else
    puts "What was the topic of the talk? (i.e. Burgundy, Q3 OKRs,  PE3)"
    prompt; topic = gets.chomp

    while topic.empty?  || topic.nil? && name != "All Hands"
      puts "Did you pay attention? What did they talk about?"
      prompt; topic = gets.chomp
    end
  end
  topic
end

def get_event_date()
  time = Time.now
  date = time.month.to_s + "/" + time.day.to_s + "/" + time.year.to_s
end

def get_event_speaker()
  puts "Who was the main speaker?"
  prompt; speaker = gets.chomp

  while speaker.empty?  || speaker.nil?
    puts "Who spoke?? Go find out their name."
    prompt; speaker = gets.chomp
  end
  speaker
end

def get_event_keywords()
  puts "What are some keywords, seperated by commas? (i.e. Docs, javascript, PPM).  Note that the spaces turn into seperate keywords (e.g. big picture becomes 'big' 'picture')"
  prompt; keywords = gets.chomp

  while keywords.empty?  || keywords.nil?
    puts "Give me at least one keyword."
    prompt; keywords = gets.chomp
  end
  keywords = keywords.split(',')
end

def event_recap (date, name_parent, name, speaker, topic, keywords)
 puts "So let me get this straight.  On #{date}'s #{name}, #{speaker} talked about #{topic} which included #{keywords}? (y/n)"
  prompt; confirm = gets.chomp

  if confirm.downcase == "y"
    title = "#{name}" + " #{date}" + " #{topic}" + " #{speaker}"
  else
    start()  
  end
  title
end

def upload_video_to_vimeo(title)
  puts "Make sure the file you want to upload is in ~/Desktop/Video Uploader/Videos/"

  filename = select_video_file()
  file = "Videos/" + filename
  puts "Ok, wait a minute while I do some magic."

  video = Vimeo::Advanced::Upload.new(@consumerKey, @consumerSecret, :token => @token, :secret => @tokenSecret)
 vimeo_title = Vimeo::Advanced::Video.new(@consumerKey, @consumerSecret, :token => @token, :secret => @tokenSecret)

  uploaded_video = video.upload(file)
  File.rename file, "Videos/Archived/" + filename

  video_id = uploaded_video["ticket"]["video_id"]
  puts "Vimeo Video ID: #{video_id}"
  vimeo_link = "https://vimeo.com/#{video_id}"
  puts "Vimeo Link: " + vimeo_link
  vimeo_title.set_title("#{video_id}", "#{title}")
  vimeo_link
end

def select_video_file()
  while true
  files = Dir.entries("Videos")
  files.each_with_index {|item, index|
    next if item == "." || item == ".."
    puts "#{index-1}) #{item}"
  }

  puts "Pick the number corresponding the file you wish to upload"
  choice = gets.chomp.to_i+1
  puts "You picked #{files[choice]}. Are you sure? y/n "
  confirm = gets.chomp
  if confirm.downcase == 'y'
    then
    return files[choice]
  end
  end
end

def create_confluence_page(parent, parent_id, title, vimeo_link, keywords, client) 
  if parent == "UX Research Videos"
    space = "UX"
  else
    space = "VID"
  end
  erb = ERB.new(File.read("vimeo_content.erb"), nil, '-<>')
  content = erb.result(binding)
  puts "Content being posted"
  puts content
  id = client.create_page(title, space, content, "editor", parent_id)
  puts "Created confluence page. Id # " + id
  id
end

def  update_confluence_page(link, title, parent_id)
  content = get_editor_from_page_id(parent_id)
  erb = ERB.new(File.read("confluence_link.erb"), nil, '-<>')
  new_content = erb.result(binding)
  content = new_content + content
end

def set_confluence_labels(id, label_array)
  #client.add_labels(id, label_array)
end

def done(parent, id)
  confluence_link = "https://confluence.puppetlabs.com/pages/viewpage.action?pageId=#{id}"
  puts "Hooray! It worked!"
  puts "Here is the generated link, it may take a few minutes to finish converting: " + confluence_link
  system('say "donuts"')
  exit
end

start()

