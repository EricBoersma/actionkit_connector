require 'spec_helper'
require_relative '../lib/actionkit_connector'

describe 'Connector' do
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

  describe "#create_petition_page" do
    let(:client) { ActionKitConnector::Connector.new('username', 'password', 'http://api.example.com') }

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
end

