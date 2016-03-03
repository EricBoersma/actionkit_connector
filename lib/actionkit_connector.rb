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

    # Find petition pages matching a given name.
    #
    # @param [Int] offset The number of records to skip.
    # @param [Int] limit  The maximum number of results to return.
    # @param [String] name The string to match against name.
    def find_petition_pages(name, limit: 10, offset: 0)
      target = "#{self.base_url}/petitionpage/"

      options = {
          basic_auth: self.auth,
          query: {
            _limit: limit,
            _offset: offset,
            name: name
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
              'Content-type' => 'application/json; charset=UTF-8'
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
              'Content-type' => 'application/json; charset=UTF-8'
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
          body: body.to_json,
          format: :json,
          headers: {'Content-Type' => 'application/json; charset=UTF-8'}
      }
      self.class.post(target, options)
    end

    # Creates an action which registers a donation with a user account.
    #
    # @param [Hash] options The hash of values sent to ActionKit which contain information about this transaction.
    def create_donation_action(options={})
      target = "#{self.base_url}/donationpush/"
      options = self.validate_donation_options(options)
      page_opts = {
          basic_auth: self.auth,
          body: options.to_json,
          headers: {
              'Content-Type' => 'application/json; charset=UTF-8'
          }
      }
      self.class.post(target, page_opts)
    end

    # Gets all information about a user based on the given ID.
    #
    # @param [Int] id The ID of the user record to retrieve.
    def user(id)
      target = "#{self.base_url}/user/#{id.to_s}/"
      self.class.get(target, {basic_auth: self.auth})
    end

    def parse_action_options(options)
      included_options = {}
      acceptable_options = [
          :ip_address, :is_forwarded, :link,
          :mailing, :referring_mailing, :referring_user,
          :name
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

    def validate_donation_options(options)
      required_base_keys = [:donationpage, :order, :user]
      if required_base_keys.all? {|s| options.key? s}
        options[:donationpage] = validate_donationpage_options(options[:donationpage])
        options[:order] = validate_donation_order_options(options[:order])
        options[:user] = validate_donation_user_options(options[:user])
      else
        raise 'Donation options require donationpage, order and user keys in the base hash.'
      end
      options
    end

    def validate_donationpage_options(options)
      required_base_keys = [:name, :payment_account]
      if required_base_keys.all? {|s| options.key? s}
        options
      else
        raise 'Donation Page options require name and payment_account keys in the hash.'
      end
    end

    def validate_donation_order_options(options)
      required_base_keys = [:amount, :exp_date_month, :exp_date_year]
      if required_base_keys.all? {|s| options.key? s}
        if options[:card_num].nil?
          options[:card_num] = '4111111111111111' # Default placeholder card number.
        end

        if options[:card_code].nil?
          options[:card_code] = '007' # Default AK Card Code.
        end
      else
        raise 'Donation Order options require amount, exp_date_month and exp_date_year keys.'
      end
      options
    end

    def validate_donation_user_options(options)
      required_base_keys = [:email, :country]
      if required_base_keys.all? {|s| options.key? s}
        options
      else
        raise 'Donation User options require email and country keys in the hash.'
      end
    end
  end
end
