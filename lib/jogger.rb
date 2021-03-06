class UnknownTraversalError < ArgumentError; end;

# Allows to formulate traversals by using predefined
# named traversals. Also allows for method chaining.
#
# All named traversals are defined in {Jogger::NamedTraversals},
# so that's where you should define your own.
#
# Instances have a @current_traversal variable that is
# updated with each call. Beware: Jogger uses method missing to
# delegate unknown methods to the current traversal. So after
# you're done chaining things, you can do more stuff with it,
# e.g. call count on it:
#
#     t = Jogger.new(some_node)
#     t.go.some.where.count
#
# Everything except for {Jogger#result} is called on the
# `@current_traversal`, so what you really want to do to get the
# count of your traversal would be
#
#     t = Jogger.new(some_node)
#     t.go.some.where.result.count
#
class Jogger


  # @param initial_node [Object] A node to start out with. Can also be
  #   the result of a prior traversal you did outside of this class
  def initialize(initial_node = nil)
    @current_traversal = initial_node
  end

  # @return [Hash] The current state of the traversal as returned by pacer
  def result
    @current_traversal
  end

  # Runs the traversal with the same name as the called method on the
  # current traversal and replaces the current traversal (== the state)
  # with the results of the named traversal.
  #
  # If you call a method that is not a named traversal, the method call
  # is delegated to the @current traversal. Still, this will return self.
  # This is useful for more traversals after named routes.
  #
  # @return [Jogger] Returns itself so you can chain multiple
  #   calls just like you would do with pacer
  def method_missing(method, *args, &block)
    begin
      traversal_args = [method, args].flatten.compact
      @current_traversal = Jogger.traverse(@current_traversal, method, args)
    rescue UnknownTraversalError => a
      begin
        @current_traversal = @current_traversal.send(method, *args, &block)
      rescue NoMethodError => m
        raise "Unknown traversal #{method}. From (#{a}) via (#{m}) (method_missing rocks)"
      end
    end
    self
  end

  # Runs a named traversal on a given traversal. For example, you
  # could give it a start node as traversal base and a traversal named
  # :go_to_all_subscribers to go to all subscribers from that node.
  #
  # @param traversal_base [Object] The result of a previous traversal
  #   or a pacer node you want to begin your traversal with
  # @param named_traversal [Symbol] The name of the predefined traversal
  #   you want to run on the traversal_base
  # @param opts [Object] Whatever you want to pass to the named traverser
  # @return [Object] The result of the traversal.
  def self.traverse(traversal_base, named_traversal, opts = nil)
    raise UnknownTraversalError, "Unknown traversal #{named_traversal}" unless valid_traversal?(named_traversal)
    args = [named_traversal, traversal_base] + [*opts].compact
    Jogger::NamedTraversals.send(*args)
  end

  private

  def self.valid_traversal?(traversal)
    Jogger::NamedTraversals.respond_to? traversal
  end

end
