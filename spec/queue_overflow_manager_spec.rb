require "spec_helper"
require "polipus/queue_overflow"
require "redis-queue"

describe Polipus::QueueOverflow::Manager do
  before(:all) do
    @redis_q = Redis::Queue.new("queue_test","bp_queue_test", :redis => Redis.new())
    @queue_overflow   = Polipus::QueueOverflow.mongo_queue(nil, "queue_test")
    @polipus = flexmock("polipus")
    @polipus.should_receive(:queue_overflow_adapter).and_return(@queue_overflow)
    @manager = Polipus::QueueOverflow::Manager.new(@polipus, @redis_q, 10)
  end

  before(:each) do
    @queue_overflow.clear
    @redis_q.clear
  end

  after(:all) do
    @queue_overflow.clear
    @redis_q.clear
  end

  it 'should remove 10 items' do
    @manager.perform.should be == [0,0]
    20.times {|i| @redis_q << "message_#{i}" }
    @manager.perform.should be == [10, 0]
    @queue_overflow.size.should be == 10
    @redis_q.size.should be == 10
  end

  it 'should restore 10 items' do
    @manager.perform.should be == [0,0]
    10.times {|i| @queue_overflow << "o_message_#{i}" }
    @manager.perform.should be == [0, 10]
    @queue_overflow.size.should be == 0
    @redis_q.size.should be == 10
    @manager.perform.should be == [0, 0]

  end

  it 'should restore 3 items' do
    
    @manager.perform.should be == [0,0]
    3.times {|i| @queue_overflow << "o_message_#{i}" }
    @manager.perform.should be == [0, 3]
    @queue_overflow.size.should be == 0
    @redis_q.size.should be == 3
    @manager.perform.should be == [0, 0]
    
  end

end