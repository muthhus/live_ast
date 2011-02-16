# encoding: us-ascii

module LiveAST
  module Loader
    MAGIC_COMMENT = /\A(?:#!.*?\n)?\s*\#.*(?:en)?coding\s*[:=]\s*([^\s;]+)/

    class << self
      def load(file, wrap)
        if file.index Linker::REVISION_TOKEN
          raise "refusing to load file with revision token: `#{file}'"
        end
        # guards to protect toplevel locals
        header, footer, warnings_ok = header_footer(wrap)
  
        parser_src = read(file)
        evaler_src = header << parser_src << footer
        
        run = lambda do
          Evaler.eval(parser_src, evaler_src, TOPLEVEL_BINDING, file, 1)
        end
        warnings_ok ? run.call : suppress_warnings(&run)
        true
      end
  
      def read(file)
        contents = File.read(file, :encoding => "BINARY")
        encoding = contents[MAGIC_COMMENT, 1] || "US-ASCII"
        contents.force_encoding(encoding)
      end

      def header_footer(wrap)
        if wrap
          return "class << Object.new;", ";end", true
        else
          locals = NATIVE_EVAL.call("local_variables", TOPLEVEL_BINDING)
  
          params = locals.empty? ? "" : ("|;" + locals.join(",") + "|")
  
          return "lambda do #{params}", ";end.call", locals.empty?
        end
      end
  
      def suppress_warnings
        previous = $VERBOSE
        $VERBOSE = nil
        begin
          yield
        ensure
          $VERBOSE = previous
        end
      end
    end
  end
end