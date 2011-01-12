require File.expand_path(File.dirname(__FILE__) + '/test_helper')

require 'app'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "on GET to /" do
    context "with no parameters" do
      setup {
        get '/'
      }
      should "return 404" do
        assert_equal 404, last_response.status
      end
    end
    context "with url of valid image" do
      setup {
        @image = "/window.jpg"
        @image_path = File.join(File.dirname(__FILE__), @image)
      }
      context "with imagemagick-qualified resize" do
        setup {
          @resize = '200x300!'
          get "/#{@resize}#{@image}"
        }
        should "return content type of image" do
          assert last_response.ok?
          assert_equal 'image/jpeg', last_response.headers['Content-Type']
        end
        should "return properly resized image" do
          assert_equal File.read(ImageMonkey::Image.new(
                        :size => @resize,
                        :path => @image_path
                      ).thumbnail_path),
                      last_response.body
        end
      end
      context "with bogus resize string" do
        setup {
          @resize = 'what-am-i-doing'
          get "/#{@resize}#{@image}"
        }
        should "return 404" do
          assert_equal 404, last_response.status
        end
      end
    end
    context "with url of missing image" do
      setup {
        @image = "/missing.png"
      }
      context "with imagemagick-qualified resize" do
        setup {
          @resize = '200x300!'
          get "/#{@resize}#{@image}"
        }
        should "return 404" do
          assert_equal 404, last_response.status
        end
      end
    end
  end
end