require 'curb'
require 'json'
require 'byebug'

module AnsibleTower

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

  class UnifiedJob < Auth
    include AnsibleTower

    attr_reader :token, :expires, :response

    def initialize(*args, &block)
      creds(Auth.token(*args, &block))
    end

    def creds(auth)
      @token = auth["token"]
      @expires = auth["expires"]
    end

    def get
      @conn = Curl::Easy.http_get(url) do |curl|
         headers.each {|k,v| curl.headers[k] = v }
         curl.ssl_verify_peer = false
         curl.resolve_mode = :ipv4
         curl.verbose = true if @debug
      end
      @response = JSON.parse(@conn.body)
      @conn.close
      @response
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
      @response
    end

    def url
      "#{proto}#{host}/api/v1/unified_jobs/"
    end

    def headers
      {}.tap do |header|
        header['Content-Type'] = 'application/json'
        header['Authorization'] = "Token #{@token}"
      end
    end
  end
end
