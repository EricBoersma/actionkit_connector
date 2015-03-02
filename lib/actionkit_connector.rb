require "actionkit_connector/version"

module ActionKitConnector
  class Connector
    include HTTParty

    def initialize(username, password, base_url)
      @auth = {username: username, password: password}
      @base_url = base_url
    end

    def list_petition_pages(offset=0, limit=20)
      target = "#{@base_url}/petitionpage/"
      options = {
          basic_auth: @auth,
          query: {
              _limit: limit,
              _offset: offset
          }
      }
      self.class.get(target, options)
    end

    def petition_page(id)
      target = "#{@base_url}/petitionpage/#{id}/"
      self.class.get(target, {basic_auth: @auth})
    end

    def create_petition_page(name, title, lang, canonical_url)
      target = "#{@base_url}/petitionpage/"
      options = {
          basic_auth: @auth,
          headers: {
              'Content-type' => 'application/json'
          },
          :body => {
              :type => "petitionpage",
              :hidden => false,
              :name => name,
              :title => title,
              :lang => lang,
              :canonical_url => canonical_url
          }.to_json,
          format: :json
      }
      self.class.post(target, options)
    end

    def create_action(page_name, email)
      target = "#{@base_url}/action/"
      options = {
          basic_auth: @auth,
          body: {
              page: page_name,
              email: email
          },
          format: :json
      }
      self.class.post(target, options)
    end
  end
end
