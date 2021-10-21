# Inspired by https://github.com/DataDog/dogstatsd-ruby/blob/master/spec/support/fake_udp_socket.rb
class FakeUDPSocket
  def initialize
    @buffer = []
  end

  def send(message, *)
    @buffer.push(message.dup)
  end

  def recv
    @buffer.shift
  end

  def to_s
    inspect
  end

  def inspect
    "<FakeUDPSocket: #{@buffer.inspect}>"
  end

  def connect(*args)
  end
end
