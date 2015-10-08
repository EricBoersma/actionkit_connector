require_relative 'actionkit_connector/version'
require 'httparty'

module ActionKitConnector
  class Connector
    include HTTParty

    attr_accessor :username
    attr_accessor :password
    attr_accessor :base_url

    # Initializes a connector to the ActionKit API.
    # A new connection is created on each call, so there
    # no need to worry about resource utilization.
    #
    # @param [String] username The username of your ActionKit user.
    # @param [String] password The password for your ActionKit user.
    # @param [String] base_url The base url of your ActionKit instance.
    def initialize(username, password, base_url)
      self.username = username
      self.password = password
      self.base_url = base_url
    end

    def auth
      {username: self.username, password: self.password}
    end

    # Lists petition pages in your instance.
    #
    # @param [Int] offset The number of records to skip.
    # @param [Int] limit  The maximum number of results to return.
    def list_petition_pages(offset=0, limit=20)
      target = "#{self.base_url}/petitionpage/"
      options = {
          basic_auth: self.auth,
          query: {
              _limit: limit,
              _offset: offset
          }
      }
      self.class.get(target, options)
    end

    # Returns the information for a single PetitionPage.
    #
    # @param [Int] id The ID of the page to return.
    def petition_page(id)
      target = "#{self.base_url}/petitionpage/#{id}/"
      self.class.get(target, {basic_auth: self.auth})
    end

    # Create a petition page in your ActionKit instance.
    #
    # @param [String] name          The name of the page.
    # @param [String] title         The title of the page.
    # @param [URI]    lang          The URI string for the language of this page in the form of /rest/v1/language/{id}
    # @param [URL]    canonical_url The canonical URL for this page.
    def create_petition_page(name, title, lang, canonical_url)
      target = "#{self.base_url}/petitionpage/"
      options = {
          basic_auth: self.auth,
          headers: {
              'Content-type' => 'application/json'
          },
          :body => {
              :type => 'petitionpage',
              :hidden => false,
              :name => name,
              :title => title,
              :language => lang,
              :canonical_url => canonical_url
          }.to_json,
          format: :json
      }
      self.class.post(target, options)
    end

    # Create a donation page in your ActionKit instance.
    #
    # @param [String] name          The name of the page.
    # @param [String] title         The title of the page.
    # @param [URI]    lang          The URI string for the language of this page in the form of /rest/v1/language/{id}
    # @param [URL]    canonical_url The canonical URL for this page.
    def create_donation_page(name, title, lang, canonical_url)
      target = "#{self.base_url}/donationpage/"
      options = {
          basic_auth: self.auth,
          headers: {
              'Content-type' => 'application/json'
          },
          :body => {
              :type => 'donationpage',
              :hidden => false,
              :name => name,
              :title => title,
              :language => lang,
              :canonical_url => canonical_url
          }.to_json,
          format: :json
      }
      self.class.post(target, options)
    end

    # Creates an action which associates a user with a page.
    #
    # @param [String] page_name The ActionKit name of the page on which the action is being taken.
    # @param [String] email     The email address of the person taking action.
    def create_action(page_name, email, options={})
      target = "#{self.base_url}/action/"
      body = { page: page_name, email: email }.merge self.parse_action_options(options)
      options = {
          basic_auth: self.auth,
          body: body,
          format: :json
      }
      self.class.post(target, options)
    end

    def parse_action_options(options)
      included_options = {}
      acceptable_options = [
          :ip_address, :is_forwarded, :link,
          :mailing, :referring_mailing, :referring_user
      ]
      options.each_key do |key|
        if acceptable_options.include? key.to_sym
          included_options[key.to_sym] = options[key]
        elsif key.to_s.start_with? 'action_'
          # ActionKit allows for custom fields to be entered into an action by prepending
          # their name with 'action_'
          included_options[key.to_sym] = options[key]
        end
      end
      included_options
    end
  end
end
