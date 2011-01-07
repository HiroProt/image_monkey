require 'sinatra'
require 'open-uri'
require 'RMagick'
require 'ftools'
require 'smusher'

SOURCE_HOST = "http://test.tanga.com/"

module ImageMonkey

  class Image
    def content_type
      @img.format
    end

    def thumbnail_path
      @_path ||= "tmp/#{rand(100000000)}"
    end

    # Options: :size :path
    def initialize options={}
      begin
        file = open(SOURCE_HOST + options[:path])
      rescue OpenURI::HTTPError => e
        raise Sinatra::NotFound.new("couldn't find it")
      end

      FileUtils.mkdir_p("tmp")
      @img = Magick::Image.from_blob(file.read).first
      @img.change_geometry(options[:size]) { |cols, rows, image| image.crop_resized!(cols, rows) }
      @img = @img.sharpen(0.5, 0.5)
      @img.write(thumbnail_path) { self.quality = 70 }
      Smusher.optimize_image(thumbnail_path)
    end
  end

end


get '/resizer/*/*' do |size, path|
  image = ImageMonkey::Image.new(:size => size, :path => path)
  expires      315360000, :public
  send_file    image.thumbnail_path, :type => image.content_type
end

get '*' do |path|
  begin
    file = open(SOURCE_HOST + path)
    puts file.path
    expires   315360000, :public
    send_file file.path,
              :filename => File.basename(path),
              :disposition => 'inline',
              :type => File.extname(path)
  rescue OpenURI::HTTPError => e
    raise Sinatra::NotFound.new("couldn't find it")
  end

end
