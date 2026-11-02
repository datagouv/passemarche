# frozen_string_literal: true

Given('a market application exists') do
  @market_application = create(:market_application)
end

When('another thread holds a database connection') do
  connection_taken = Queue.new
  @release_connection = Queue.new
  @connection_holder = Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      connection_taken << true
      @release_connection.pop
    end
  end
  connection_taken.pop
end

Then('the market application is still found') do
  expect(MarketApplication.find_by(id: @market_application.id)).to eq(@market_application)
ensure
  @release_connection << true
  @connection_holder.join
end
