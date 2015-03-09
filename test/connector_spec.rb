require 'rspec'
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
end