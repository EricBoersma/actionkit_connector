require 'spec_helper'
require_relative '../lib/actionkit_connector'

describe 'Connector' do
  let(:client) { ActionKitConnector::Connector.new('username', 'password', 'http://api.example.com') }

  before :each do
    @connector = ActionKitConnector::Connector.new 'username', 'password', 'url'
  end

  it 'should create auth' do
    expect(@connector.auth).to eql({username: 'username', password: 'password'})
  end

  it 'should change auth' do
    @connector.password = 'new_password'
    expect(@connector.auth).to eql({username: 'username', password: 'new_password'})
  end

  it 'should create base url' do
    expect(@connector.base_url).to eql 'url'
  end

  it 'parses action options for inclusion into AK' do
    expect(@connector.parse_action_options({ip_address: '1010', bad_result: 'foo'})).to eq({ip_address: '1010'})
  end

  it 'converts action_ fields to be included with AK' do
    expect(@connector.parse_action_options({'action_foo' => 'test', not_an_action: 'bad'})).to eq({action_foo: 'test'})
  end

  describe '#find_petition_pages' do
    before do
       stub_request(:get, "http://username:password@api.example.com/petitionpage/?_limit=10&_offset=0&name=foo-bar")
    end

    it "finds petition pages matching a given name" do
      client.find_petition_pages("foo-bar")

      expect(WebMock).to have_requested(:get, "http://username:password@api.example.com/petitionpage/?_limit=10&_offset=0&name=foo-bar")
    end
  end

  describe "#create_petition_page" do

    let(:request_body) do
      { type: 'petitionpage',
        hidden: false,
        name: 'foo-bar',
        title: 'foo bar',
        language: '/language/en',
        canonical_url: 'http://example.com/foo-bar' }.to_json
    end

    before do
       stub_request(:post, "http://username:password@api.example.com/petitionpage/").
         with(body: request_body)
    end

    it "creates a petition page" do
      client.create_petition_page("foo-bar", "foo bar", "/language/en", "http://example.com/foo-bar")
      expect(WebMock).to have_requested(:post, "http://username:password@api.example.com/petitionpage/").
        with(body: request_body)
    end
  end

  # Used for the donation validations below.
  let(:full_donation_options) {
    {
        donationpage: {
            name: 'donation',
            payment_account: 'Default Import Stub'
        },
        order: {
            amount: '1',
            card_num: '4111111111111111',
            card_code: '007',
            exp_date_month: '01',
            exp_date_year: '2016'
        },
        user: {
            email: 'eric@sumofus.org',
            country: 'United States',
        }
    }
  }

  describe '#create_donation_action' do
    let(:request_body) {
      full_donation_options.to_json
    }

    before do
      stub_request(:post, "http://username:password@api.example.com/donationpush/").
          with(body: request_body)
    end

    it 'creates a donationpush action' do
      client.create_donation_action(full_donation_options)
      expect(WebMock).to have_requested(:post, 'http://username:password@api.example.com/donationpush/').
        with(body: request_body, headers: {'Content-Type' => 'application/json'})
    end
  end

  describe 'donation validation methods' do
    let(:expected_donationpage) {
      full_donation_options[:donationpage]
    }
    let(:expected_order) {
      full_donation_options[:order]
    }
    let(:expected_user) {
      full_donation_options[:user]
    }
    describe '#validate_donation_options' do
      it 'sends back the correct options when provided a valid hash' do
        expect(client.validate_donation_options(full_donation_options)).to eq(full_donation_options)
      end

      it 'raises when provided an incorrect set of base hash values' do
        expect { client.validate_donation_options({}) }.to raise_error(RuntimeError)
      end
    end

    describe '#validate_donationpage_options' do
      it 'sends back the correct options when provided a valid hash' do
        expect(client.validate_donationpage_options(expected_donationpage)).to eq(expected_donationpage)
      end

      it 'raises when provided an incorrect set of hash values' do
        expect { client.validate_donationpage_options({}) }.to raise_error(RuntimeError)
      end
    end

    describe '#validate_donation_user_options' do
      it 'sends back the correct options when provided a valid hash' do
        expect(client.validate_donation_user_options(expected_user)).to eq(expected_user)
      end

      it 'raises when provided an incorrect set of hash values' do
        expect { client.validate_donation_user_options({}) }.to raise_error(RuntimeError)
      end
    end

    describe '#validate_donation_order_options' do
      it 'sends back the correct options when provided a correct hash' do
        expect(client.validate_donation_order_options(expected_order)).to eq(expected_order)
      end

      it 'raises when provided an incorrect set of hash values' do
        expect { client.validate_donation_order_options({}) }.to raise_error(RuntimeError)
      end

      it 'fills in default values if they are not provided' do
        sent_values = expected_order.tap { |hash|
          hash.delete(:card_num)
          hash.delete(:card_code)
        }
        expect(client.validate_donation_order_options(sent_values)).to eq(expected_order)
      end
    end

  end


end

