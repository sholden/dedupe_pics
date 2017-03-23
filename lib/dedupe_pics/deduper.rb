require 'digest/md5'
require 'fileutils'
require 'logger'

module DedupePics
  class Deduper
    attr_reader :original_paths, :output_path, :logger

    def initialize(original_paths, output_path, logger: Logger.new(STDOUT))
      @original_paths = original_paths
      @output_path = output_path
      @logger = logger
    end

    def dedupe!
      logger.info "Scanning #{original_paths.length} paths for images"

      original_images = find_images
      logger.info "Found #{original_images.length} images"

      images_by_md5 = original_images.each_with_object({}){|i, h| h[i.md5] ||= i}
      logger.info "Deduped #{images_by_md5.length} images (#{original_images.length - images_by_md5.length} dupes)"

      grouped_by_basename = images_by_md5.values.group_by(&:basename)
      logger.info "Disambiguating #{grouped_by_basename.values.count{|ary| ary.length > 1}} image names"

      images_to_destination = grouped_by_basename.values.each_with_object({}) do |images, hash|
        if images.one?
          images.each{|i| hash[i] = File.join(output_path, i.basename)}
        else
          images.each{|i| hash[i] = File.join(output_path, i.md5name)}
        end
      end

      logger.info "Copying deduped images to #{output_path}"
      FileUtils.mkdir_p(output_path)
      images_to_destination.each do |image, destination|
        FileUtils.copy(image.path, destination, preserve: true)
      end
    end

    def find_images
      original_paths.flat_map{|p| Dir[image_pattern(p)]}.uniq.map{|p| Image.new(p) }
    end

    def image_pattern(path)
      File.join(path, '**', '*.{jpg,jpeg,gif,png,mpg,avi,3gp,mov}')
    end
  end
end