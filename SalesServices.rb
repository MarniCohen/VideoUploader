##Purpose of this:
#Record location of video on disk
#Upload to vimeo script with this info
#Pull new vimeo link for video
#New page on confluence with vimeo link
#Include keywords/names/date format nicely

#require 'rubygems'
#require 'bundler'
require 'vimeo'
require 'yaml'


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

end

#Gets the name of event
def event_name()
  
  login()
@name = "Sales Services Bootcamp"
event_date() 
end
 
#Assumes today's date is date of video.  I'll expand this later for flexibility
def event_date()
  time = Time.now
  @date = time.month.to_s + "/" + time.day.to_s + "/" + time.year.to_s
  event_topic()
end

#Gets the topic of event, this goes in the title with the name (i.e. Big Picture - PE3)
def event_topic()
  puts "What was the topic of the talk? (i.e. Burgundy, Q3 OKRs,  PE3)"
  prompt; @topic = gets.chomp
  
  while @topic.empty?  || @topic.nil?
   puts "Did you pay attention? What did they talk about?"
   prompt; @topic = gets.chomp
  end
 event_speaker() 
end

#Gets the speaker. Will add flexibility of xtra speakers later.
def event_speaker()
  puts "Who was the main speaker?"
  prompt; @speaker = gets.chomp
  
  while @speaker.empty?  || @speaker.nil?
   puts "Who spoke?? Go find out their name."
   prompt; @speaker = gets.chomp
  end
event_keywords() 

end

#Gets the keywords.
def event_keywords()
  puts "What are some keywords, seperated by commas? (i.e. Docs, javascript, PPM)"
  prompt; @keywords = gets.chomp
  
  while @keywords.empty?  || @keywords.nil?
   puts "Give me at least one keyword."
   prompt; @keywords = gets.chomp
  end
  event_recap()
end

def event_recap()
 puts "So let me get this straight.  On #{@date},  #{@speaker} talked about #{@topic} which included #{@keywords}? (y/n)"
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
  puts "What is the filename, including extension?"
  prompt; filename = gets.chomp

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


#sorting script
if @name == "Demos"
   @parent == "Demos 2014"
  else
   @parent = @name
end

    @confluencePage = %x[java -jar `dirname $0`/confluence-cli-3.7.0/lib/confluence-cli-3.7.0.jar --server https://confluence.puppetlabs.com --user #{@user} --password #{@pass} --action addPage --space VID --parent "#{@parent}"  --title "#{@title}" --content "{widget:height=321|width=500|url=https://vimeo.com/#{@video_id}}" --labels "#{@keywords}"]

    puts "Video Posted! Confluence Page ID:  #{@confluencePage.split(//).last(9).join("").to_s}"

    @confluenceID = @confluencePage.split(//).last(9).join("").to_s.chomp
    @link = "https://confluence.puppetlabs.com/pages/viewpage.action?pageId=#{@confluenceID}"
  
    @updateLink = %x[java -jar `dirname $0`/confluence-cli-3.7.0/lib/confluence-cli-3.7.0.jar --server https://confluence.puppetlabs.com --user #{@user} --password #{@pass} --action modifyPage --space VID --title "#{@parent}" --content "[#{@title}|#{@link}]"]



the_end()
end

#If it all worked
def the_end
puts "Hooray! It worked!"
exit
end

event_name()
