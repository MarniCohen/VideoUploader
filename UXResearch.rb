require 'rails'
require 'vimeo'
require 'yaml'
require 'tempfile'

def prompt()
  print "> "
end

def login()
  config = YAML.load(File.read('etc/config.yaml'))

  #Confluence Login
  @user = config["username"]
  @pass = config["password"]

  @consumerKey = config["consumerkey"]
  @consumerSecret = config["consumersecret"]
  @token = config["token"]
  @tokenSecret = config["tokensecret"]

  @parent = "UX Research Videos"
end

#Gets the name of event
def event_name()
  login()
  @name = "UX Research"
  event_date() 
end
 
#Assumes today's date is date of video.
def event_date()
  time = Time.now
  @date = time.month.to_s + "/" + time.day.to_s + "/" + time.year.to_s
  event_topic()
end

#Gets the study name
def event_topic()
  puts "What was the study name? (i.e. learning vm)"
  prompt; @topic = gets.chomp
  
  while @topic.empty?  || @topic.nil?
   puts "Did you pay attention? What did they talk about?"
   prompt; @topic = gets.chomp
  end
 event_speaker() 
end

#Gets the participant.
def event_speaker()
  puts "Who was the participant?"
  prompt; @speaker = gets.chomp
  
  while @speaker.empty?  || @speaker.nil?
   puts "Who spoke?? Go find out their name."
   prompt; @speaker = gets.chomp
  end
  event_recap()
end

def event_recap()
 puts "So let me get this straight.  On #{@date},  #{@speaker} talked about #{@topic}? (y/n)"
  prompt; confirm = gets.chomp
  
  if confirm.downcase == "y"
    @title = "#{@name}" + " #{@date}" + " #{@topic}" + " #{@speaker}"
  else
    event_name()
  end
 uploader()
end

#Finds and uploads file
def uploader()
  puts "Make sure the file you want to upload is in ~/Desktop/Video Uploader/Videos/"
  filename = pickfile()
  file = "Videos/" + filename
  puts "Ok, wait a minute while I do some magic."
  upload = Vimeo::Advanced::Upload.new(@consumerKey, @consumerSecret, :token => @token, :secret => @tokenSecret)

  setTitle = Vimeo::Advanced::Video.new(@consumerKey, @consumerSecret, :token => @token, :secret => @tokenSecret)

  video = upload.upload(file)
  @video_id = video["ticket"]["video_id"]
  puts "Vimeo Video ID: #{@video_id}"
  setTitle.set_title("#{@video_id}", "#{@title}")

  confluence_magic()
end

#Confluence magic time!
def confluence_magic
  @link = "https://vimeo.com/#{@video_id}"
  @content = "#{@video_id}"
  @confluencePage = %x[java -jar `dirname $0`/confluence-cli-3.7.0/lib/confluence-cli-3.7.0.jar --server https://confluence.puppetlabs.com --user #{@user} --password #{@pass} --action addPage --space UX --parent "#{@parent}"  --title "#{@title}" --content "{widget:height=321|width=500|url=https://vimeo.com/#{@video_id}}"]
  puts "Video Posted! Confluence Page ID:  #{@confluencePage.split(//).last(9).join("").to_s}"
  @confluenceID = @confluencePage.split(//).last(9).join("").to_s.chomp
  @link = "https://confluence.puppetlabs.com/pages/viewpage.action?pageId=#{@confluenceID}"
  the_end()
end

#If it all worked
def the_end
  puts "Here is the generated link, it may take a few minutes to finish converting: " + @link
  
  puts "Hooray! It worked!"
  exit
end

def pickfile()
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

event_name()
