# frozen_string_literal: true
require "propshaft/errors"

class Propshaft::Compilers::JavascriptAssetUrls
  attr_reader :assembly

  ASSET_URL_PATTERN = /((?:import|from)\(?\s*["'](.*\.js)["']\)?)/

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(logical_path, input)
    input.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(logical_path.dirname, $2), logical_path, $2, $1 }
  end

  private
    def resolve_path(directory, filename)
      if filename.start_with?("../")
        Pathname.new(directory + filename).relative_path_from("").to_s
      elsif filename.start_with?("/")
        filename.delete_prefix("/").to_s
      else
        (directory + filename.delete_prefix("./")).to_s
      end
    end

    def asset_url(resolved_path, logical_path, pattern, match)
      if asset = assembly.load_path.find(resolved_path)
        match.gsub(pattern, "#{assembly.config.prefix}/#{asset.digested_path}")
      else
        Propshaft.logger.warn "Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}"
        match
      end
    end
end
