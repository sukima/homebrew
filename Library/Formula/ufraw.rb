require 'formula'

class Ufraw <Formula
  url 'http://downloads.sourceforge.net/project/ufraw/ufraw/ufraw-0.17/ufraw-0.17.tar.gz'
  homepage 'http://ufraw.sourceforge.net'
  md5 '5e2c2b4adaea1f6d03eac66e11747fc6'

  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'gtk' if ARGV.include? '--with-gtk'
  depends_on 'libtiff'
  depends_on 'jpeg'
  depends_on 'little-cms'
  depends_on 'dcraw'
  depends_on 'exiv2' => :optional

  def options
    [
      ['--with-gtk', 'Build the UFRaw GUI (depends on GTK)'],
    ]
  end

  def install
    fails_with_llvm "Compiling with LLVM gives a segfault while linking."
    config_opts = [
      "--disable-dependency-tracking",
      "--prefix=#{prefix}",
      "--without-gimp",
    ]
    config_opts << "--without-gtk" unless ARGV.include? "--with-gtk"

    system "./configure", config_opts

    system "make install"
    (share+'pixmaps').rmtree
  end
end
