require "coffee_script"
require "source"
require "execjs"

module Eco
  module Source
    def self.path
      @path ||= ENV["ECO_SOURCE_PATH"] || bundled_path
    end

    def self.path=(path)
      @contents = @version = @context = nil
      @path = path
    end

    def self.contents
      @contents ||= File.read(path)
    end

    def self.combined_contents
      [CoffeeScript::Source.contents, contents].join(";\n")
    end

    def self.version
      @version ||= contents[/Eco Compiler v(.*?)\s/, 1]
    end

    def self.context
      @context ||= ExecJS.compile(combined_contents)
    end
  end

  class << self
    def version
      Source.version
    end

    def compile(template)
      template = template.read if template.respond_to?(:read)
      Source.context.call("eco.precompile", template)
        # Contiamo improvement (we don't care about line breaks in generated html)
        .gsub(/__out\.push\('\s*\\n\s*'\);/, "")
        .gsub(/\s*\\n\s*/, "\n\s")
        .gsub(/\s+/, "\s")
        .gsub(/\\n/, "")
    end

    def context_for(template)
      ExecJS.compile("var render = #{compile(template)}")
    end

    def render(template, locals = {})
      context_for(template).call("render", locals)
    end
  end
end
