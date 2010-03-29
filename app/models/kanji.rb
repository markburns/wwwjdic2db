class Kanji < ActiveRecord::Base

  cattr_reader :per_page
  @@per_page = 100

  has_one :studyable_item, :as => :studyable
  ARBITRARY_LARGE_NUMBER_OF_KANJI = 100000
  has_one :heisig
  has_many :heisig_keywords, :through => :heisig
  has_many :primitives_kanjis
  has_many :primitives, :through => :primitives_kanjis
  has_many :onyomis_kanjis
  has_many :onyomis, :through => :onyomis_kanjis
  has_many :kunyomis_kanjis
  has_many :kunyomis, :through => :kunyomis_kanjis
  has_many :pinyins_kanjis
  has_many :pinyins, :through => :pinyins_kanjis
  has_many :koreans_kanjis
  has_many :koreans, :through => :koreans_kanjis
  has_many :meanings_kanjis
  has_many :meanings, :through => :meanings_kanjis
  has_many :stories, :as => :commentable
  has_many :kanji_tree_edits
  has_many :jlpts_kanjis
  has_many :joyos_kanjis
  has_one :skips_kanji
  has_one :skip, :through => :skips_kanji

  has_many :kyuujitai

  def to_s
    kanji
  end

  def kanji
    read_attribute(:kanji)#.force_encoding 'utf-8'
  end



  named_filter :heisig do |min, max|
    having :heisig_keywords do
      with(:heisig_id).between(min.to_i,max.to_i)
    end
    group_by 'kanjis.id'
  end


  named_filter(:joyo) do |levels|
    having(:joyos_kanjis) do 
      any_of do
        if levels.class==Array
          levels.each do |level|
            with(:level).equal_to level
          end
        elsif levels.class == Fixnum
          with(:level).equal_to levels
        end
      end
    end
    group_by 'kanjis.id'
  end

  named_filter(:jlpt) do |levels| 
    having(:jlpts_kanjis) do
      any_of do 
        if levels.class == Array
          levels.each do |level|
            with(:level).equal_to level
          end
        elsif levels.class == Fixnum
          with(:level).equal_to levels
        end
      end
    end
    group_by 'kanjis.id'
  end

  
  named_filter(:cumulative_frequency_range) do |min,max|
    with(:cumulative_frequency).gte min.to_f
    with(:cumulative_frequency).lte max.to_f
  end

  #Helper method maps params found in hash
  #to their corresponding expected values
  #wherever a parameter has a value of '1' then
  #the expected value is added to the return array
  #For example:
  #
  def self.hash_params_to_a hash, params
    #If all values are set to 0 then don't get Joyo Kanji
    zero_count=0
    levels = []
    #build array of levels to send to named_scope
    hash.each_pair do |key,value|
      if params[key]=="1"
        levels << value
      elsif params[key]=="0"
        zero_count+=1
      end
    end

    #If all values are set to 0 then don't get Joyo Kanji
    if zero_count == hash.length
      levels = []
    end
    return levels
  end


  named_filter :with_onyomis do
    having(:onyomis_kanjis) do
      having(:onyomi) 
    end
  end

  named_filter :include_onyomis do
    join(OnyomisKanji, :join_type => :left) do
      on :id=>:kanji_id
      join(Onyomi) do
        on :onyomi_id=>:id
      end
    end
  end


  def self.find_filtered params, options
    page = options[:page]
    per_page = options[:per_page]
    chain = Kanji

    #chain = chain.all(:include => [:onyomis, :kunyomis, :meanings, :heisig, :heisig_keywords])

    #filter name, start value and end value (min max)
    filters = [[:heisig,:heisig_start, :heisig_end],
      [:heisig_lesson,:heisig_lesson_start,:heisig_lesson_end],
      [:cumulative_frequency_range, :frequency_start, :frequency_end]
    ]

    filters.each do |filter|
      
      filter_name = filter[0]
      min = params[filter[1].to_s]
      max = params[filter[2].to_s]
      #if we have values for each parameter
      if min && max
        #process the filter
        chain = chain.send(filter_name,min,max)
      
      end
    end
    #go over each selection and append to filter chain
    selections = [
      [:joyo, {:joyo_1 => '1', :joyo_2 => '2', :joyo_3 => '3',
          :joyo_4 => '4',:joyo_5 =>'5',:joyo_6 =>'6', :joyo_high_school =>'S'}],
      [:jlpt, {:jlpt_1 => '1', :jlpt_2 => '2', :jlpt_3 => '3',
          :jlpt_4 => '4',
          :jlpt_n1 => 'N1', :jlpt_n2 => 'N2', :jlpt_n3 => 'N3',
          :jlpt_n4 => 'N4', :jlpt_n5 => 'N5'}]
    ]

    selections.each do |selection|
      method = selection[0]
      hash = selection[1]
      levels = self.hash_params_to_a(hash,params)
      if levels.length > 0
        chain = chain.send(method, levels)
      end
    end


    sum = chain.sum(:frequency_percentage)
    sum = (([sum, 100].min*100).round/ 100).to_s

    count = chain.count.to_s #force the calculation before the pagination


    chain = chain.paginate :page => page, :per_page => per_page
    
    return include_readings(chain), count, sum
  end


  def self.include_readings collection
    kanjis_collection = collection.to_a
    puts kanjis_collection.class
    kanji_ids = kanjis_collection.collect { |k| k.id}
    readings=Kanji.find_all_by_id(kanji_ids, :include => :onyomis_kanjis).to_a  

    onyomis_kanji_ids = readings.collect {|k| 
      k.onyomis_kanjis.collect {|ok|
        ok.onyomi_id
      }.flatten
    }.flatten

    onyomis_kanjis = OnyomisKanji.find_all_by_id(onyomis_kanjis_ids, :include =>:onyomi)
    
  end

  def heisig_id
    unless heisig.nil?
      return heisig.id
    end
  end

  def keyword
    unless heisig.nil?
      return heisig.keyword
    end
    return ""
  end

  
  def self.find_by_keyword keyword
    h = HeisigKeyword.find_by_keyword keyword
    return nil if h == nil
    kanji_id = (Heisig.find(h.heisig_id)).kanji_id
    Kanji.find kanji_id
  end

=begin

1. when a user requests a kanji_tree_edit, a kanji is found which
    EITHER "has no edits" (status "U" unedited, edit count 0)
    OR "only has edit status of R (rejected)"

      {i.e. NOT any of
                P (pending submission awaiting opinion of admin),
            OR H (held awaiting edit from user),
            OR A (Accepted)
      }

  {optionally} AND satisfies the criteria requested by the user
    (e.g. Heisig > x, JlptKanji.level == 4)
=end

  named_filter :unedited  do
    any_of do
      having(:status).equal_to 'U'
      having(:status).equal_to 'R'
    end
  end
  named_filter :accepted do
    having(:status).equal_to 'A'
  end

  named_filter(:rtk_lite) do
    having :heisig do
      with(:rtk_lite).equals true
      order :heisig_id
    end
  end

  named_filter (:frequency_range) do |min,max|
    with(:cumulative_frequency).gte min.to_f
    with(:cumulative_frequency).lte max.to_f
  end

  named_filter (:frequency_order) do
    order :rank
  end


end
