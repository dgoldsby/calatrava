module Calatrava

  class AppBuilder
    include Rake::DSL

    def initialize(output_dir, manifest)
      @output_dir, @manifest = output_dir, manifest
    end

    def build_dir ; @output_dir ; end
    def build_html_dir ; "#{build_dir}/views" ; end
    def build_scripts_dir ; "#{build_dir}/scripts" ; end
    def build_images_dir ; "#{build_dir}/images" ; end
    def build_styles_dir ; "#{build_dir}/styles" ; end

    def coffee_files
      @manifest.coffee_files + [Calatrava::Project.current.config.path('env.coffee')]
    end

    def js_file(cf)
      "#{build_scripts_dir}/#{File.basename(cf, '.coffee')}.js"
    end

    def load_instructions
      @manifest.kernel_bootstrap.collect { |cf| js_file(cf) }.join($/)
    end

    def haml_files
      @manifest.haml_files
    end

    def builder_task
      directory build_html_dir
      directory build_images_dir
      directory build_scripts_dir

      app_files = haml_files.collect do |hf|
        file "#{build_html_dir}/#{File.basename(hf, '.haml')}.html" => [build_html_dir, hf] do
          HamlSupport::compile_hybrid_page hf, build_html_dir, :platform => 'ios'
        end
      end

      app_files += coffee_files.collect do |cf|
        file js_file(cf) => [build_scripts_dir, cf] do
          coffee cf, build_scripts_dir
        end
      end

      app_files += @manifest.css_tasks(build_styles_dir)
      app_files << file("#{build_dir}/load_file.txt" => build_dir) do |t|
        File.open(t.name, "w+") { |f| f.puts load_instructions }
      end

      task :shared => [build_images_dir, build_scripts_dir] do
        cp_ne "#{ASSETS_IMG_DIR}/*", build_images_dir
        cp_ne "assets/lib/*.js", build_scripts_dir
        cp_ne "ios/res/js/*.js", build_scripts_dir
      end

      task :app => [:shared] + app_files
    end

  end

end