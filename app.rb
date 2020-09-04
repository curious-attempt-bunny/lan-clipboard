require 'sinatra'
require 'pathname'
require 'securerandom'
require 'sinatra/json'

set bind: '0.0.0.0'

uploads_dir = 'data'
mkdir(uploads_dir) unless File.exists?(uploads_dir)

clipboard = [
    {
        timestamp: Time.now.to_i,
        content: 'Ohai! Anything you post here will expire after 10 minutes.'
    }
]

Thread.new do
    while true
        sleep 30
        now = Time.now.to_i
        clipboard.reject! do |entry|
            reject = entry[:timestamp] < now - 10*60
            if reject
                if entry[:files]
                    entry[:files].each do |file|
                        puts "Deleting #{file[:tempfile].path}"
                        file[:tempfile].delete
                    end 
                end
            end
            reject
        end    
    end
end

get '/' do
    haml :index, locals: { clipboard: clipboard }
end

post '/share' do
    content = params[:content]
    files = params[:files]

    clipboard << {
        id: SecureRandom.hex(32),
        timestamp: Time.now.to_i,
        content: content,
        files: files
    }

    puts files.inspect

    redirect '/'
end

get '/clipboard/:id/files/:index' do
    entry = clipboard.find { |entry| entry[:id] == params[:id] }
    redirect '/' unless entry

    json entry[:files][params[:index].to_i]
    file = entry[:files][params[:index].to_i]
    type = file[:head].match(/Content-Type: ([^\r\n]+)[\r\n]/)[1]
    puts type
    send_file(
        file[:tempfile],
        type: type,
        filename: file[:filename]
    )
end
