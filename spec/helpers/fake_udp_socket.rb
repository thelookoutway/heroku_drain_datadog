class FakeUDPSocket
  attr_reader :buffer

  def initialize
    @buffer = []
  end

  def send(message, *)
    @buffer.push(message)
  end

  def flush
    @buffer.clear
  end

  def to_s
    inspect
  end

  def inspect
    "<FakeUDPSocket: #{@buffer.inspect}>"
  end
end
