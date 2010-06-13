#encoding: utf-8
require 'db/kanjidic_importer'
require 'pp'
require 'ruby-debug'
Debugger.start

describe KanjidicImporter do

  before(:all) { 
      @importer = KanjidicImporter.new
      @indexes = @importer.index_names
      @filename = "db/kanjidic"

      @lines = File.open @filename, "r" do|f|
        l=f.readlines
        arr=[]
        #skip the first line
        l.each do |line|
          arr << line unless line[0..0]=="#"
        end
        arr 
      end

      @line = "飯 4853 U98ef B184 G4 S12 F1046 J3 N5158 "
      @line << "V6679 H1691 DK1110 L1473 K1083 O1964 DO768 MN44064P "
      @line << "MP12.0387 E565 IN325 DS696 DF279 DH594 DT597 DJ604 "
      @line << "DB3.12 DG1904 DM1485 P1-8-4 I8b4.5 Q8174.7 DR2867 "
      @line << "Yfan4 Wban "
      @line << "ハン めし T1 い いい いり え {meal} {boiled rice}" 

  }

  it ("returns a regexp for a data type")  {
    r= @importer.regexp :katakana 
    r.should == (/\b[ア-ン]+[ア-ン.]*\b/)

    r= @importer.regexp :hiragana 
    r.should == (/\b[あ-ん]+[あ-ん.]*\b/)
  }


  it "gets relevant data from a line" do
    kanji = @importer.get_element :kanji, @line
    puts kanji
    kanji.should == "飯"

    onyomis = @importer.get_element :onyomi, @line
    onyomis.length.should == 1

    kunyomis = @importer.get_element :kunyomi, @line
    kunyomis.length.should == 1

    nanoris = @importer.get_element :nanori, @line
    nanoris.length.should == 4
    nanoris.should == %w[い いい いり え]

    meanings = @importer.get_element :meaning, @line
    meanings.length.should == 2
    meanings.should == ["meal", "boiled rice"]

    korean = @importer.get_element :korean, @line
    korean.length.should == 1
    korean.should == ["ban"]

    pinyin = @importer.get_element :pinyin, @line
    pinyin.length.should == 1
    pinyin.should == ["fan4"]

  end

  #certain text values need adding to tables first so that the relationships
  #can be built after the ids are created and saved
  it "gets all unique values from an array of lines" do
    #covers kanji, readings, meanings,classical radicals, radicals, 
    kunyomis = @importer.get_unique_values :kunyomi, @lines
    kunyomis.class.should be Array
    onyomis = @importer.get_unique_values :onyomi
    onyomis.class.should be Array
    onyomis.length.should be >= 415 

    hash = @importer.get_unique_values [:kunyomi, :onyomi]
    hash.class.should be Hash
    hash[:kunyomi].should_not be nil

    meanings = @importer.get_unique_values [:meaning]
    meanings.class.should be Hash
    meanings[:meaning].length.should be > 8020 
    hash = @importer.get_unique_values [:kunyomi, :onyomi]

    hash[:kunyomi].length.should be > 900
    hash[:onyomi].length.should be > 400

    all_values = @importer.lookup_attributes

    hash = @importer.get_unique_values all_values
    hash.class.should == Hash
    hash.length.should == all_values.length
    keys = hash.keys
    keys.each do |key|
      all_values.should include key
    end
    hash.each_pair do |key,value|
      puts "#{key}: #{value.length} items"
    end
  end

  it "imports reading lookup values" do
    @importer.import_reading_lookup_values @lines
    Kanji.count.should be_close 6356, 10
    Onyomi.count.should be_close 415, 5
    Meaning.count.should be_close  8486, 20
    Nanori.count.should be_close  1023, 10
    Skip.count.should be_close  583, 5
    Korean.count.should be_close  472, 5
    Pinyin.count.should be_close  1139, 10
    Kunyomi.count.should be_close  4382, 30
  end

  it("generates a hash lookup for a table") {
    hash = @importer.table_to_hash_lookup(Kunyomi, "kunyomi")
    l = hash.length
    l.should be_close 4382,10
  }

  it("generates a hash lookup for the dictionaries table") {
    hash = @importer.table_to_hash_lookup(Dictionary, "name", use_symbol=true)
    l = hash.length
    puts l
    l.should be_close 30,3
  }



  it( "returns a regexp for an index type" ){
    @indexes.each do |index| 
      r = @importer.regexp index
      r.should_not be nil
    end

  }

  #returns the dictioanry id and lookup value from
  #an input of dictionary indices and 
  def id_and_value input, which
    input[which][1..2]
  end
  
  it "gets a radical index" do
    indexes = @importer.get_dictionary_index :radical, @line
    id_and_value(indexes,0).should == [1,"184"]
  end

  it "gets a heisig index" do
    indexes = @importer.get_dictionary_index [:heisig], @line
    id_and_value(indexes,0).should == [22,"1473"]
  end

  it "gets a radical and heisig index" do
    indexes = @importer.get_dictionary_index [:radical, :heisig], @line
    [id_and_value(indexes,0),id_and_value(indexes,1)].should == 
      [[1,"184"],[22,"1473"]]
  end

  it "appends to an array of dictionary indexes" do 
    indexes = @importer.get_dictionary_index [:radical, :heisig], @line
    indexes = @importer.get_dictionary_index [:nelson], @line, indexes
    indexes.length.should == 3
  end

  it "imports multiple indexes" do

    KanjiLookup.delete_all
    indexes = []
    @lines.each do |line|
      indexes = @importer.get_dictionary_index @indexes, line, indexes
    end
    @importer.import_indexes indexes 
    KanjiLookup.count.should be > 60000 
  end

  it "parses kanjidic" do
    readings, indexes = @importer.parse_kanjidic @lines
    readings.length.should be @importer.lookup_attributes.length
    indexes.length.should be > 15000
  end

  it "imports kanjidic" do
    validate = false
    delete_all = true
    @importer.import_kanjidic @lines, validate, delete_all
    puts @lines[0]
    k=Kanji.first
    puts "First kanji #{k.kanji} , #{k.id}"
    o=Onyomi.first
    puts "First onyomi #{o.onyomi},#{o.id}"
    puts k.onyomis
    ok =  OnyomisKanji.first
    ok.onyomi_id.should_not be nil
    KunyomisKanji.first.kunyomi_id.should_not be nil

    puts "OnyomisKanji: onyomi id #{ok.onyomi_id}, kanji_id #{ok.kanji_id}"
    k2 = Kanji.find_by_id(ok.kanji_id)
    puts "Found kanji #{k.kanji} , #{k.id}"
    o2 = Onyomi.find_by_id ok.onyomi_id
    pp o2

    OnyomisKanji.count.should be > 6000
    KunyomisKanji.count.should be > 6000
    MeaningsKanji.count.should be > 10000
    NanorisKanji.count.should be > 500
    KoreansKanji.count.should be > 500
    PinyinsKanji.count.should be > 6000
  end

end

