#This script takes a vimeo ID and makes a confluence page and links it
#This script DOES NOT UPLOAD VIDEOS
#It only automates the creation of confluence pages
#so there


require 'rubygems'
#require 'bundler'
require 'yaml'


def prompt()
  print "> "
end

def login()
  config = YAML.load(File.read('etc/config.yaml'))

  #Confluence Login
  @user = config["username"]
  @pass = config["password"]

  #Vimeo API Info
  @consumerKey = config["consumerkey"]
  @consumerSecret = config["consumersecret"]
  @token = config["token"]
  @tokenSecret = config["tokensecret"]
 
end

#Gets the name of event
def event_name()
  @name = "UX Design Review"
 
  event_date()
  end

#Assumes today's date is date of video.  I'll expand this later for flexibility
def event_date()
  puts "What's the date? mm/dd/yyyy?"
  @date = gets.chomp
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
  
  puts "They talked about: #{@topic}, correct? (y/n)"
  correct_topic = gets.chomp
 
  if correct_topic == "y" || correct_topic == "Y"
    event_speaker()
  end
  event_topic()
end

#Gets the speaker. Will add flexibility of xtra speakers later.
def event_speaker()
  puts "Who was the main speaker?"
  prompt; @speaker = gets.chomp
  
  while @speaker.empty?  || @speaker.nil?
   puts "Who spoke?? Go find out their name."
   prompt; @speaker = gets.chomp
  end
  
  puts "So #{@speaker} was the speaker? (y/n)"
  correct_speaker = gets.chomp

  if correct_speaker == "y" || correct_speaker == "Y"
    event_keywords()
  end
  event_speaker()
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
 puts "So let me get this straight.  On #{@date}'s #{@name},  #{@speaker} talked about #{@topic} which included #{@keywords}? (y/n)"
  prompt; confirm = gets.chomp
  
  if confirm.downcase == "y"
    @title = "#{@date}" + " #{@topic}" + " #{@speaker}"
  else
    event_name()
  end

 uploader()
end


#Finds and uploads file
def uploader()
  puts "What is the vimeo id?"
  prompt; @video_id = gets.chomp

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

    @confluencePage = %x[java -jar `dirname $0`/confluence-cli-3.7.0/lib/confluence-cli-3.7.0.jar --server https://confluence.puppetlabs.com --user "marni" --password "area51" --action addPage --space VID --parent "#{@parent}"  --title "#{@title}" --content "{widget:height=321|width=500|url=https://vimeo.com/#{@video_id}}" --labels "#{@keywords}"]

    puts "Video Posted! Confluence Page ID:  #{@confluencePage.split(//).last(9).join("").to_s}"

    @confluenceID = @confluencePage.split(//).last(9).join("").to_s.chomp
    @link = "https://confluence.puppetlabs.com/pages/viewpage.action?pageId=#{@confluenceID}"
  
    @updateLink = %x[java -jar `dirname $0`/confluence-cli-3.7.0/lib/confluence-cli-3.7.0.jar --server https://confluence.puppetlabs.com --user "marni" --password "area51" --action modifyPage --space VID --title "#{@parent}" --content "[#{@title}|#{@link}]"]



the_end()
end

#If it all worked
def the_end
puts "Hooray! It worked!"
exit
end

event_name()
