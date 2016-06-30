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

require_relative 'libunwind_installer.rb'
require_relative 'dotnet_installer.rb'
require_relative 'dotnet.rb'
require_relative '../bp_version.rb'

require 'json'
require 'pathname'

module AspNetCoreBuildpack
  class Compiler
    def initialize(build_dir, cache_dir, libunwind_binary, dotnet_installer, dotnet, copier, out)
      @build_dir = build_dir
      @cache_dir = cache_dir
      @libunwind_binary = libunwind_binary
      @dotnet_installer = dotnet_installer
      @dotnet = dotnet
      @copier = copier
      @out = out
    end

    def compile
      puts "ASP.NET Core buildpack version: #{BuildpackVersion.new.version}\n"
      puts "ASP.NET Core buildpack starting compile\n"
      step('Restoring files from buildpack cache', method(:restore_cache))
      step('Extracting libunwind', method(:extract_libunwind))
      step('Installing Dotnet CLI', method(:install_dotnet)) if dotnet_installer.should_install(build_dir)
      step('Restoring dependencies with Dotnet CLI', method(:restore_dependencies)) if dotnet_installer.should_install(build_dir)
      step('Saving to buildpack cache', method(:save_cache))
      puts "ASP.NET Core buildpack is done creating the droplet\n"
      return true
    rescue StepFailedError => e
      out.fail(e.message)
      return false
    end

    private

    def extract_libunwind(out)
      libunwind_binary.extract(File.join(build_dir, 'libunwind'), out) unless File.exist? File.join(build_dir, 'libunwind')
    end

    def restore_cache(out)
      copier.cp(File.join(cache_dir, '.nuget'), build_dir, out) if File.exist? File.join(cache_dir, '.nuget')
      copier.cp(File.join(cache_dir, 'libunwind'), build_dir, out) if File.exist? File.join(cache_dir, 'libunwind')
    end

    def install_dotnet(out)
      dotnet_installer.install(build_dir, out)
    end

    def restore_dependencies(out)
      dotnet.restore(build_dir, out)
    end

    def save_cache(out)
      copier.cp(File.join(build_dir, '.nuget'), cache_dir, out) if File.exist? File.join(build_dir, '.nuget')
      copier.cp(File.join(build_dir, 'libunwind'), cache_dir, out) unless File.exist? File.join(cache_dir, 'libunwind')
    end

    def step(description, method)
      s = out.step(description)
      begin
        method.call(s)
      rescue => e
        s.fail(e.message)
        raise StepFailedError, "#{description} failed, #{e.message}"
      end

      s.succeed
    end

    attr_reader :build_dir
    attr_reader :cache_dir
    attr_reader :libunwind_binary
    attr_reader :dotnet_installer
    attr_reader :mozroots
    attr_reader :dotnet
    attr_reader :copier
    attr_reader :out
  end

  class StepFailedError < StandardError
  end
end
