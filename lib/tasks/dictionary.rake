require 'db/kanjidic_importer'
require 'open-uri'
require 'nkf'
require 'fileutils'
require 'diff/lcs'

KANJIDIC_URL = 'http://ftp.monash.edu.au/pub/nihongo/kanjidic.gz'
KANJIDIC_RSYNC_URL ='ftp.monash.edu.au::nihongo/kanjidic' 

namespace :kanjidic do

  desc "Download latest changes to kanjidic"

  task :download do
    #backup
    FileUtils.cp euc_filename, euc_filename + '.bak'
    #download the latest changes
    success = system("rsync -v #{KANJIDIC_RSYNC_URL} #{euc_filename}")
    
    if success && $?.exitstatus ==0 
      puts 'Downloaded changes successfully'
      create_utf_diff
    else
      puts  "Problem downloading - do you have rsync installed? "
      puts "http://samba.anu.edu.au/rsync/download.html"
    end
  end

  def create_utf_diff
    #backup
    FileUtils.cp unicode_filename, old_unicode_filename

    #create utf file
    convert_to_unicode euc_filename, unicode_filename

    #create diff
    old = File.read(old_unicode_filename).split "\n"
    new = File.read(unicode_filename).split "\n"
    diff = Diff::LCS.LCS(old, new)
    puts "Difference between files"
  end

  def unicode_diff_filename
    File.join db_folder, 'diff.utf'
  end

  def zipped_filename
    File.join RAILS_ROOT, 'kanjidic.gz'
  end

  def unzipped_filename
    File.join RAILS_ROOT, 'kanjidic'
  end

  def db_folder
    File.join RAILS_ROOT, 'db'
  end

  def euc_filename 
    File.join db_folder,'kanjidic.euc'
  end
  def unicode_filename
    File.join db_folder, 'kanjidic.utf'
  end

  def old_unicode_filename
    unicode_filename + '.old'
  end


  desc "Download full kanjidic"

  task :full_download do
    puts "Downloading kanjidic.gz from #{KANJIDIC_URL}"
    lines = wget KANJIDIC_URL

    File.open(zipped_filename, 'w'){|f| f << lines}

    unless gunzip(zipped_filename)
      puts "Problem unzipping kanjidic.gz, do you have gunzip installed?"
      puts "http://www.gzip.org/#exe"
    end


    #move file into db folder
    from = File.join RAILS_ROOT, 'kanjidic'
    FileUtils.mv(unzipped_filename, euc_filename)

    #convert EUC-JP encoding to UTF-8
    convert_to_unicode euc_filename, unicode_filename
  end

  def gunzip(filename)
    command = "gunzip --force #{filename}"
    success = system(command)
    success && $?.exitstatus == 0
  end

  def convert_to_unicode input, output

    euc_jp =File.read input
    unicode = NKF.nkf("-u",euc_jp)
    File.open(output,"w"){ |f| f << unicode}
  end

  def wget url
    return open(url,'User-Agent' => 'Ruby-Wget').read
  end

  desc "Create dictionary from downloaded file"
  task :create do
    validate = false
    delete_all = true
    filename = ARGV[0]
    puts filename
    @importer = KanjidicImporter.new
    #@importer.generate_lookups()
    @lines = File.read 'db/kanjidic'
    @importer.import_kanjidic @lines, validate, delete_all
  end


end
