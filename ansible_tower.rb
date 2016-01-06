require 'curb'
require 'json'
require 'byebug'

module AnsibleTower
  @@page_size = 50
  @@page = 1

  def next
    return "No Response".to_json if self.response.nil?
    return "No Previous Records".to_json if self.response['next'].nil?
    next_url = "#{proto}#{host}#{self.response['next']}"
    get(next_url)
  end

  def previous
    return "No Response".to_json if self.response.nil?
    return "No Previous Records".to_json if self.response['previous'].nil?
    prev_url = "#{proto}#{host}#{self.response['previous']}"
    get(prev_url)
  end

  def results
    get(url)['results']
  end

  def page
    @@page
  end

  def page_size
    @@page_size
  end

  def host=(x)
   @@host = x
  end

  def host
   @@host
  end

  def proto
    'https://'
  end

  class Auth
    include AnsibleTower
    attr_reader :response

   def initialize(*args, &block)
     @debug = true if args.first
   end

   def self.token(*args, &block)
     x = Auth.new(*args, &block)
     yield x
     x.put
     x.response
   end

   def put
    @conn = Curl::Easy.http_post(url, post_data) do |curl|
       headers.each {|k,v| curl.headers[k] = v }
       curl.ssl_verify_peer = false
       curl.resolve_mode = :ipv4
       curl.verbose = true if @debug
    end
    @response = JSON.parse(@conn.body)
    @conn.close
   end

   def username=(x)
     @username = x
   end

   def username
     @username
   end


   def url
     "#{proto}#{host}/api/v1/authtoken/"
   end

   def password=(x)
    self.password_encrypted = x
    @password = "hidden"
   end

   def password
     @password
   end

   def password_encrypted=(x)
     @password_encrypted = x
   end

   def password_encrypted
     @password_encrypted
   end

   def post_data
    {:username => @username, :password => @password_encrypted}.to_json
   end

   def headers
     {}.tap do |header|
       header['Content-Type'] = 'application/json'
     end
   end

  end

  class Base < Auth
    include AnsibleTower

    attr_reader :token, :expires, :response

    def initialize(*args, &block)
    end

    def creds(auth)
      @token = auth["token"]
      @expires = auth["expires"]
    end

    def get(get_url = url)
      @conn = Curl::Easy.http_get(get_url) do |curl|
         headers.each {|k,v| curl.headers[k] = v }
         curl.ssl_verify_peer = false
         curl.resolve_mode = :ipv4
         curl.verbose = true if @debug
      end
      @response = JSON.parse(@conn.body)
      @conn.close
      @response
    end

    def put(put_url = url, post_data)
      @conn = Curl::Easy.http_post(put_url, post_data) do |curl|
         headers.each {|k,v| curl.headers[k] = v }
         curl.ssl_verify_peer = false
         curl.resolve_mode = :ipv4
         curl.verbose = true if @debug
      end
      @response = JSON.parse(@conn.body)
      @conn.close
      @response
    end

    def url
    end

    def headers
      {}.tap do |header|
        header['Content-Type'] = 'application/json'
        header['Authorization'] = "Token #{@token}"
      end
    end
  end

  class UnifiedJob < Base
    include AnsibleTower

    attr_reader :token, :expires, :response

    def initialize(*args, &block)
      @debug = true if args.first
      creds(Auth.token(*args, &block))
    end

    def url
      "#{proto}#{host}/api/v1/unified_jobs/"
    end
  end

  class Ping < Base
    include AnsibleTower

    attr_reader :token, :expires, :response

    def initialize(*args, &block)
      @debug = true if args.first
      creds(Auth.token(*args, &block))
    end

    def url
      "#{proto}#{host}/api/v1/ping/"
    end
  end
end
