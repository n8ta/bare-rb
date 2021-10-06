class SeenList
  def initialize
    @list = []
  end
  def add(node)
    if @list.include?(node)
      raise CircularSchema.new("Cycle detected #{@list[0]} -> #{node}")
    end
    @list << node
  end
  def pop
    @list.pop
  end
end
