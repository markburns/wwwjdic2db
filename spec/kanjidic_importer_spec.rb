#encoding: utf-8

require 'db/kanjidic_importer'
require 'pp'
require 'active_support'

describe KanjidicImporter do

  before(:all) { 
    @indexes=[ :radical, :classical_radical, :halpern, :nelson,
      :new_nelson, :japanese_for_busy_people, :kanji_way , 
      :japanese_flashcards , :kodansha , :hensall , :kanji_in_context ,
      :kanji_learners_dictionary , :french_heisig , :o_neill , :de_roo ,
      :sakade , :tuttle_flash_card , :tuttle_dictionary ,
      :tuttle_kanji_and_kana , :unicode, :four_corner ,
      :heisig, :morohashi_index , :morohashi_volume_page ,
      :henshall , :gakken , :japanese_names , :cross_reference ,
      :misclassification]

      @importer = KanjidicImporter.new
      @filename = "db/kanjidic"

      @lines = File.open @filename, "r" do|f|
        l=f.readlines
        arr=[]
        #skip the first line
        l.each do |line|
          arr << line unless line[0]=="#"
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
  if false
    it ("returns a regexp for a data type")  {
      r= @importer.regexp :katakana 
      r.should == (/\b[ア-ン]+[ア-ン.]*\b/)

      r= @importer.regexp :hiragana 
      r.should == (/\b[あ-ん]+[あ-ん.]*\b/)
    }

    it "gets relevant data from a line" do
      kanji = @importer.get_element :kanji, @line
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
      hash.keys.should == all_values
      hash.each_pair do |key,value|
        puts "#{key}: #{value.length} items"
      end
    end

    it "imports reading lookup values" do
      @importer.import_reading_lookup_values @lines
      Onyomi.count.should be 415
      Meaning.count.should be 8486
      Nanori.count.should be 1023
      Skip.count.should be 583
      Korean.count.should be 472
      Pinyin.count.should be 1139
      Kunyomi.count.should be 4382
    end
  end
  it( "returns a regexp for an index type" ){
    @indexes.each do |index| 
    r = @importer.regexp index
    r.should_not be nil
    end

  }


  it("generates a hash lookup for a table") {
    hash = @importer.table_to_hash_lookup(Kunyomi, "kunyomi")
    l = hash.length
    l.should == (4382)
  }

  it "gets a dictionary  index" do
    indexes = @importer.get_dictionary_index :radical, @line
    indexes.should == [[2307,1,"184"]]
    indexes = @importer.get_dictionary_index [:heisig], @line
    indexes.should == [[2307,22,"1473"]]

    indexes = @importer.get_dictionary_index [:radical, :heisig], @line
    indexes.should == [[2307,1,"184"],[2307,22,"1473"]]
  end

  it "appends to an array of dictionary indexes" do 
    indexes = @importer.get_dictionary_index [:radical, :heisig], @line
    indexes.should == [[2307,1,"184"],[2307,22,"1473"]]
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

