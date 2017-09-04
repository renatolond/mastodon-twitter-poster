class InterruptibleSleep
  def sleep(seconds)
    @_sleep_check, @_sleep_interrupt = IO.pipe
    IO.select([@_sleep_check], nil, nil, seconds)
  end

  def wakeup
    @_sleep_interrupt.close if @_sleep_interrupt && !@_sleep_interrupt.closed?
  end
end
