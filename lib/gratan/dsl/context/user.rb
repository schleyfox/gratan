class Gratan::DSL::Context::User
  include Gratan::DSL::Validator
  include Gratan::Logger::Helper

  attr_reader :result

  def initialize(user, host, options, &block)
    @object_identifier = "User `#{user}@#{host}`"
    @user = user
    @host = host
    @options = options
    @result = {}
    instance_eval(&block)
  end

  def on(name, options = {}, &block)
    name = name.kind_of?(Regexp) ? name : name.to_s

    __validate("Object `#{name}` is already defined") do
      not @result.has_key?(name)
    end

    if options[:object_type]
      __validate("Object `#{name}` has invalid object_type") do
        ["TABLE", "FUNCTION", "PROCEDURE"].include?(options[:object_type])
      end
    end

    if @options[:enable_expired] and (expired = options.delete(:expired))
      expired = Time.parse(expired)

      if Time.new >= expired
        log(:warn, "Object `#{name}` has expired", :color => :yellow)
        return
      end
    end

    grant = {:privs => Gratan::DSL::Context::On.new(@user, @host, name, @options, &block).result}
    grant[:with] = options[:with] if options[:with]
    grant[:object_type] = options[:object_type] if options[:object_type]
    @result[name] = grant
  end
end
