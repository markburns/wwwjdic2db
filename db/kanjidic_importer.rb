#!/usr/bin/ruby
# encoding: utf-8

require 'pp'
require 'db/connection'
require 'hash_extension'

class KanjidicImporter

  attr_accessor :dictionary_lookup, :kanji_lookup, :onyomi_lookup
  attr_reader :lookup_attributes
  KANJIDIC = "db/kanjidic"
  ENGLISH = 1 


  def initialize
    @lookup_attributes = [:kunyomi, :onyomi, :english_word, :nanori,  :skip, :korean, :pinyin]
    @index_names=[ :radical, :classical_radical, :halpern, :nelson,
      :new_nelson, :japanese_for_busy_people, :kanji_way , 
      :japanese_flashcards , :kodansha , :hensall , :kanji_in_context ,
      :kanji_learners_dictionary , :french_heisig , :o_neill , :de_roo ,
      :sakade , :tuttle_flash_card , :tuttle_dictionary ,
      :tuttle_kanji_and_kana , :unicode, :four_corner ,
      :heisig, :morohashi_index , :morohashi_volume_page ,
      :henshall , :gakken , :japanese_names , :cross_reference ,
      :misclassification]
    generate_lookups()
  end

  def generate_lookups
    @onyomi_lookup = table_to_hash_lookup Onyomi, "onyomi"
    @kunyomi_lookup = table_to_hash_lookup Kunyomi, "kunyomi"
    @nanori_lookup = table_to_hash_lookup Nanori, "nanori"
    @english_word_lookup = table_to_hash_lookup EnglishWord, "word"
    @kanji_lookup = table_to_hash_lookup Kanji, "kanji"
    @korean_lookup = table_to_hash_lookup Korean, "korean"
    @pinyin_lookup = table_to_hash_lookup Pinyin, "pinyin"

    @skip_lookup = table_to_hash_lookup Skip, "skip_pattern"
    use_symbol= true
    @dictionary_lookup = table_to_hash_lookup Dictionary, "name", use_symbol
  end

  #creates an inverse lookup hash of column value to id
  #obviously this needs unique values or the lookup is 
  #unpredictable
  #key_column is the attribute in the table to use as the hash key
  #value_column defaults to id, and is the attribute to use as the hash value
  #string_key? is used to determine if the output hash has a string or symbol lookup
  def table_to_hash_lookup table, key_column, symbol_key = false, value_column="id"
    key_column = key_column.to_s #allows for accepting symbols or strings
    value_column = value_column.to_s
    o=table.find_as_hashes(:all, :select => "#{key_column}, #{value_column}")
    #returns array of form
    # [{"id"=>"1", "column"=>"value"},{"id" => "2", "column" => "value2"}....]

    #convert to form
    #{'value' => 1, 'value2' => 2,...}

    dictionary=o.inject({}) {|result, element|
      #only get values that have a key column
 
      unless element[key_column].nil?
        entry = element[key_column].to_s#.force_encoding("utf-8")
        entry = entry.to_sym if symbol_key
        #insert into the hash
        result[entry] = element[value_column].to_i 
      end
      result
    }

    return dictionary
  end


  #this imports the values that need importing before
  #the whole file is parsed
  #for example it imports the kunyomi readings so they
  #can be used in the table KunyomisKanji
  #I.e. it is necessary to do a pass over the file first, and
  #populated the necessary tables with unique values, and
  #then when going over each line the ids for the relationships
  #are known 
  #validate -- run ActiveRecord validation
  #delete -- delete all the records in each table first (to perfrom a complete
  #datbase rebuild)
  def import_reading_lookup_values lines, types=@lookup_attributes, validate=false, delete_all=true
    ActiveRecord::Base.transaction do |transaction|
      #returns a hash of arrays of values
      unique_values = get_unique_values types, lines
      unique_values.each_pair do |column,values|
        table = eval(column.to_s.capitalize)
        table.delete_all if delete_all
        #make assumption name that e.g. kunyomi is column
        #Kunyomi is model, with exception of skip_pattern
        if column == :skip
          column = :skip_pattern
        end
        #convert values array to 2D array for ar-extensions import
        values2d =[]
        values.each do |v|values2d<<[v];end
        table.import [column],values2d, :validate=>validate
      end
    end

    generate_lookups()
  end

  #imports all the various dictionary indexes found in the kanjidic file
  def import_indexes indexes, validate=false, delete_all=true
    columns = [:kanji_id, :dictionary_id, :dictionary_index_value]
    ActiveRecord::Base.transaction do |transaction|
      #puts "indexes:#{indexes}"
      KanjiLookup.delete_all if delete_all
      KanjiLookup.import columns, indexes, :validate =>validate
    end
  end

  #imports the various relations e.g. KunyomisKanji, OnyomisKanji etc
  #relationships - a hash of arrays of index values
  #the hash key is the column name (symbol)
  #the infered relationship is from e.g. :kunyomi -> KunomisKanji
  def import_relationships relationships, validate=false, delete_all=true
    ActiveRecord::Base.transaction do |transaction|
      relationships.each_pair do |column, values|
        table = eval(column.to_s.capitalize+"sKanji")
        relation_id = (column.to_s + "_id").to_sym
        columns = [:kanji_id, relation_id]
        table.delete_all if delete_all
        table.import columns, values,  :validate => validate 
      end
    end
  end


  #type - an array of Symbols or a single Symbol representing
  #the dictionary name
  #line - the line of data to parse
  #appends to indexes 
  #[[kanji_id, dictionary_id, dictionary_index_value],[kanji_id,...],...]
  def get_dictionary_index types, line, indexes=nil
    indexes ||= []
    if types.is_a? Symbol
      types = [types]
    end
    kanji_id = @kanji_lookup[line[0]]
    out=[]
    types.each do |type|
      dictionary_index_value = get_element(type, line)
      unless dictionary_index_value.nil?
        dictionary_id = @dictionary_lookup[type]
        values = [kanji_id, dictionary_id, dictionary_index_value]
        #puts "values:#{values}"
        indexes << values
      else 
        #puts "#{type} not found on this line"
      end
    end
    return indexes
  end

  #returns a specific element from the line
  #this function is tied to the kanjidic text format, which is unlikely 
  #to change fundamentally except add on extra indexes
  def get_element type, line
    case type
    when :kanji
      return line[0]
    when :nanori, :onyomi, :kunyomi
      nanori_match = regexp(:nanori_divider).match line
      #if there is a nanori section then create the
      # nanoris and get section for other readings (yomi)
      unless nanori_match.nil?
        nanori_section = nanori_match.post_match
        nanoris = nanori_section.scan regexp(:kana)
        yomi = nanori_match.pre_match
      else #no nanoris everything is a yomi (normal reading)
        nanoris= []
        yomi = line
      end
      return nanoris if type == :nanori
      #puts "processing #{type}"
      return yomi.scan(regexp(type)).flatten

    when :yomi, :english_word, :kana, :korean, :pinyin, :skip
      return line.scan(regexp(type)).flatten

    when :bushu, :radical, :historical_radical, :classical_radical, :halpern, :nelson,
      :new_nelson, :japanese_for_busy_people, :kanji_way , 
      :japanese_flashcards , :kodansha , :hensall , :kanji_in_context ,
      :kanji_learners_dictionary , :french_heisig , :o_neill , :de_roo ,
      :sakade , :tuttle_flash_card , :tuttle_dictionary ,
      :tuttle_kanji_and_kana , :unicode, :four_corner ,
      :heisig, :morohashi_index , :morohashi_volume_page ,
      :henshall , :gakken , :japanese_names , :cross_reference ,
      :misclassification
      return (line.scan regexp(type)).flatten[0]

    end
  end

  def regexp type
    case type

    when :katakana , :onyomi
      /\b[ア-ン]+[ア-ン.]*\b/
    when :hiragana , :kunyomi
      #hiragana is the range of characters from あ-ん
      /\b[あ-ん]+[あ-ん.]*\b/
    when :kana
      #kana is the sum of all the characters in hiragana and katakana
      /\b[ア-ンあ-ん]+[ア-ンあ-ん.]*\b/
    when :nanori_divider
      /\sT1\s/
    when :english_word
      /\{([^\}]+)\}/ #anything between {}
    when :korean
      /\sW(\w+)\s/
    when :pinyin
      /\sY(\w+)\s/
    when :stroke_count, :strokes #"Stroke count"
      /\s(S[^\s]+)\s/
    when :skip
      /\sP([\d-]+)\s/
    when :joyo
      /\s(G[1-6])\s/
    when :joyo_high_school
      /\s(G[8])\s/
    when :jinmeiyou
      /\s(G[9])\s/
    when :jinmeiyou_variant
      /\s(G[10])\s/
    when :jlpt
      /\s(J([^\s]+))\s/
    when :frequency
      /\s(F[^\s]+)\s/
        #indexes
    when :radical, :bushu
      /\sB([^\s]+)\s/
    when  :classical_radical, :historical_radical
      /\bC([^\s]+)\b/
    when :halpern
      /\s(H[^\s]+)\s/
    when :nelson
      /\s(N[^\s]+)\s/
    when :new_nelson
      /\s(V[^\s]+)\s/
    when :japanese_for_busy_people
      /\s(DB[^\s]+)\s/
    when :kanji_way #"The Kanji Way to Japanese Language Power";
      /\s(DC[^\s]+)\s/
    when :japanese_flashcards #"Japanese Kanji Flashcards";
      /\s(DF[^\s]+)\s/
    when :kodansha #"Kodansha Compact Kanji Guide";
      /\s(DG[^\s]+)\s/
    when :hensall #"A Guide To Reading and Writing Japanese";
      /\s(DH[^\s]+)\s/
    when :kanji_in_context #"Kanji in Context";
      /\s(DJ[^\s]+)\s/
    when :kanji_learners_dictionary #"Kanji Learners Dictionary";
      /\s(DK[^\s]+)s/
    when :french_heisig #"French adapatation of Heisig's Remembering The Kanji";
      /\s(DM[^\s]+)\s/
    when :o_neill #"O'Neill's Essential Kanji";
      /\s(DO[^\s]+)\s/
    when :de_roo #two_thousand_and_one_kanji #"2001 Kanji"
      /\s(DR[^\s]+)\s/
    when :sakade #"A Guide To Reading and Writing Japanese";
      /\s(DS[^\s]+)\s/
    when :tuttle_flash_card #"Tuttle Kanji Cards";
      /\s(DT[^\s]+)\s/
    when :tuttle_dictionary #"The Kanji Dictionary (Tuttle 1996)"
      /\s(I[^N][^\s]+)\s/
    when :tuttle_kanji_and_kana #"Kanji & Kana book (Tuttle)";
      /\s(IN[^\s]+)\s/
    when :unicode
      /\s(U[^\s]+)\s/
    when :four_corner #"The four corner code";
      /\s(Q[^\s]+)\s/
    when :heisig
      /\bL(\d+)\b/
    when :morohashi_index #"Morohashi Daikanwajiten Index";
      /\s(MN[^\s]+)\s/
    when :morohashi_volume_page #"Morohashi Daikanwajiten Volume and Page";
      /\s(MN[^\s]+)\s/
    when :henshall #"A Guide To Remembering Japanese Characters";
      /\s(E[^\s]+)\s/
    when :gakken #"Gakken Kanji Dictionary";
      /\s(G[^\s]+)\s/
    when :japanese_names #"Japanese Names, by P.G. O'Neill";
      /\s(O[^\s]+)\s/
    when :cross_reference #"Cross Reference Code";
      /\sX([^\s]+)\s/
    when :misclassification #"Mis-classification code";
      /\s(Z[^\s]+)\s/
    end
  end

  #Expects an array of types as symbols (or single symbol)
  #And an array of lines, or uses member variable
  #Return every unique occurence of that type within the
  #file specified
  #strip_duplicates - this only returns values in the lines
  #that are not in the database (can be used to import new values)
  #returned as a hash of arrays of values (key is the symbol)
  def get_unique_values types, lines=nil, strip_duplicates=false
    lines ||= @lines
    if lines.nil?
      raise ArgumentError, "No value for lines, and no value previously set", caller
    else 
      @lines = lines
    end
    #make sure to return array if only one type
    #otherwise return hash of arrays
    single_item =false 
    unless types.class == Array
      types = [types]
      single_item =true
    end

    hash_types={}
    #create a dictionary for each type
    types.each {|type|hash_types[type]={}}

    #for each line get the elements of each type
    #add to dictionary for that type
    lines.each do |line|
      types.each do |type|
        #add the element(s) to the hash
        #puts "hash_types:#{hash_types}"
        dict = hash_types[type]
        hash_types[type] = add_elements(line, type, dict, strip_duplicates)
      end

    end
    if single_item
      #e.g. hash = {:kanji => {"木"=>1,"子"=>1},:onyomi=>{"コウ"=>1}}
      return hash_types.values[0].keys
    end

    #e.g. hash = {:kanji => {"木"=>1,"子"=>1},:onyomi=>{"コウ"=>1}}
    #gets changed to {:kanji => ["木","子"], :onyomi => ["コウ"]}
    hash_types.keys.each do |k|
      hash_types[k] =hash_types[k].keys
    end

    return hash_types
  end

  def add_elements line, type, dictionary, strip_duplicates
    elements = get_element(type, line)
    if strip_duplicates
      lookup = eval('@' + type.to_s + '_lookup')
    end

    if elements.is_a? String
      dictionary[elements]=1
      #remove from hash if already in database
      if strip_duplicates
        if lookup[elements]
          dictionary.delete(elements)
        end
      end
    elsif elements.is_a? Array  
      elements.each do |e|
        dictionary[e]=1
        if strip_duplicates
          if lookup[e]
            dictionary.delete e
          end
        end
      end
    end
    return dictionary
  end

  def import_file filename=KANJIDIC, validate=false, delete_all=true
    lines = read_lines filename
    import_kanjidic lines, validate, delete_all
    
  end

  def read_lines filename=KANJIDIC
    lines = File.open filename, "r" do |f|; f.readlines;end
  end

  def import_kanjidic lines=nil, validate=false, delete=true
    if lines.nil?
      lines = read_lines
    end
    import_reading_lookup_values lines, @lookup_attributes, validate, delete
    readings, indexes = parse_kanjidic lines
    import_indexes indexes, validate, delete
    import_relationships readings, validate, delete

  end

  #returns all the relationships and indexes in the lines
  def parse_kanjidic lines
    line_number=1
    # get id values from the tables for the various attributes such as kunyomi, onyomi etc
    # to be used in the join tables 
    readings_to_import= {}
    @lookup_attributes.each do |column|
      #stores readings in a hash of arrays with the key being
      #the attribute name e.g. :nanori, :kunyomi, etc
      readings_to_import[column]=[]
    end 


    #create empty arrays to store index values
    indexes_to_import= [] #2D array of [[dictionary_id, kanji_id, index_value],...]

    lines.each do |line|
      unless line_number == 1
        kanji = line[0].to_s
        kanji_id = @kanji_lookup[kanji]
        #for each of nanori, onyomi, english_words, pinyin etc
        @lookup_attributes.each do |column|    
          #get each of the multiple value attributes and append them to an array 
          #to import at the end
          klass = eval(column.to_s.capitalize)
          relation_klass = eval(column.to_s.capitalize.pluralize+"Kanji")
          lookup =  "@#{column}_lookup"
          #puts lookup
          lookup = eval(lookup)

          values = get_element(column, line)
          values.each do |value|
            #e.g. equivalent to o=Onyomi.find_by_onyomi onyomi
            relation_id = lookup[value]
            # e.g. equivalent to  array << OnyomisKanji.new(:kanji_id=>id,:onyomi_id =>o.id)
            readings_to_import[column] << [kanji_id ,relation_id]
          end
        end 

        #for the indexes we have a KanjiIndex table an Dictionaries table
        #and a KanjiIndex has a dictionary_id column
        @index_names.each do |index_name|
          indexes_to_import += get_dictionary_index(index_name, line)
        end

      end
      line_number +=1
    end
    return readings_to_import, indexes_to_import
  end
end
