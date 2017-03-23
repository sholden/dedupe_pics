module DedupePics
  class Image
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def basename
      File.basename(path)
    end

    def extname
      File.extname(path)
    end

    def rootname
      File.basename(path, extname)
    end

    def md5name
      "#{rootname}-#{md5}#{extname}"
    end

    def md5
      @md5 ||= Digest::MD5.file(path).hexdigest
    end
  end
end