class Class
  def takes(*args)
    define_initialize(args)
  end

  def define_initialize(args)
    assignments = args.map { |a| "@#{a} = #{a}" }.join("\n")
    self.class_eval %{
      def initialize(#{args.join(", ")})
        #{assignments}
      end
    }
  end

  alias_method :let, :define_method
end

