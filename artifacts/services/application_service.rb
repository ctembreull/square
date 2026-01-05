class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  def self.test(*args, &block)
    new(*args, &block).test
  end
end
