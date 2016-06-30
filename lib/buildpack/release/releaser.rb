# Encoding: utf-8
# ASP.NET Core Buildpack
# Copyright 2014-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../app_dir'

module AspNetCoreBuildpack
  class Releaser
    def release(build_dir)
      app = AppDir.new(build_dir)
      start_cmd = get_start_cmd(app)

      fail 'No project could be identified to run' if start_cmd.nil? || start_cmd.empty?

      write_startup_script(startup_script_path(build_dir))
      generate_yml(start_cmd)
    end

    private

    def write_startup_script(startup_script)
      FileUtils.mkdir_p(File.dirname(startup_script))
      File.open(startup_script, 'w') do |f|
        f.write 'export HOME=/app;'
        f.write 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/libunwind/lib;'
        f.write 'export PATH=$PATH:$HOME/.dotnet:$HOME;'
      end
    end

    def generate_yml(start_cmd)
      yml = <<-EOT
---
default_process_types:
  web: #{start_cmd} --server.urls http://0.0.0.0:${PORT}
EOT
      yml
    end

    def get_source_start_cmd(project)
      return "dotnet run --project #{project}" unless project.nil?
    end

    def get_published_start_cmd(project, build_dir)
      return "#{project}" if File.exist? File.join(build_dir, "#{project}")
      return "dotnet #{project}.dll" if File.exist? File.join(build_dir, "#{project}.dll")
    end

    def get_start_cmd(app)
      start_cmd = get_source_start_cmd(app.main_project_path)
      return start_cmd unless start_cmd.nil?

      start_cmd = get_published_start_cmd(app.published_project, app.root)
      return start_cmd unless start_cmd.nil?
    end

    def startup_script_path(dir)
      File.join(dir, '.profile.d', 'startup.sh')
    end
  end
end
