require "open3"

module ClamScan
  class Request
    class << self
      def send (opts={})
        output = nil

        begin
          Open3.popen3(*popen_args(opts)) do |stdin, stdout, stderr|
            [stdin, stdout, stderr].each(&:binmode)

            stdout_reader = Thread.new { stdout.read }
            stderr_reader = Thread.new { stderr.read }

            if opts[:stream]
              begin
                if opts[:stream].respond_to?(:read)
                  IO.copy_stream(opts[:stream], stdin)
                elsif opts[:stream].is_a?(String)
                  stdin.write opts[:stream]
                end
              rescue Errno::EPIPE
              end
            end
            stdin.close

            output = stdout_reader.value
          end
        rescue SystemCallError => e
          raise RequestError, "An error occured while making system call to #{::ClamScan.configuration.client_location}: #{e.to_s}"
        end

        Response.new($?, output)
      end

    private

      BOOLEAN_ARGS = %w(
        allmatch
        bell
        fdpass
        infected
        leave_temps
        no_summary
        quiet
        recursive
        stdout
        verbose
      )

      IGNORE_ARGS = %w(
        custom_args
        location
        stream
      )

      VALUE_ARGS = %w(
        algorithmic_detection
        block_encrypted
        bytecode
        bytecode_statistics
        bytecode_timeout
        bytecode_unsigned
        copy
        cross_fs
        database
        detect_broken
        detect_pua
        detect_structured
        exclude
        exclude_dir
        exclude_pua
        file_list
        follow_dir_symlinks
        follow_file_symlinks
        heuristic_scan_precedence
        include
        include_dir
        include_pua
        log
        max_dir_recursion
        max_files
        max_filesize
        max_recursion
        max_scansize
        move
        official_db_only
        phishing_cloak
        phishing_scan_urls
        phishing_sigs
        phishing_ssl
        remove
        scan_archive
        scan_elf
        scan_html
        scan_mail
        scan_ole2
        scan_pdf
        scan_pe
        structured_cc_count
        structured_ssn_count
        structured_ssn_format
        tempdir
      )

      def argify (key, value=nil)
        "--#{key.gsub('_', '-')}" + (value ? "=#{value}" : '')
      end

      def popen_args (opts={})
        args = [::ClamScan.configuration.client_location]

        if opts[:custom_args]
          args += opts[:custom_args]
        else
          opts = ::ClamScan.configuration.default_scan_options.merge(opts)

          opts.each do |key, value|
            key_string = key.to_s

            if BOOLEAN_ARGS.include? key_string
              args << argify(key_string) if value
            elsif VALUE_ARGS.include? key_string
              args << argify(key_string, value) if value
            elsif IGNORE_ARGS.include? key_string
              # do nothing
            else
              raise RequestError, "Invalid option: #{key}"
            end
          end

          args << opts[:location] if opts[:location]
          args << '-' if opts[:stream]
        end

        args
      end
    end
  end
end
