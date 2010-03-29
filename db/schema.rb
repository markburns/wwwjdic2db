# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100329165705) do

  create_table "dictionaries", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "edict_mappings", :force => true do |t|
    t.integer  "english_word_id"
    t.integer  "japanese_word_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "english_words", :force => true do |t|
    t.string   "word"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "heisig_keywords", :force => true do |t|
    t.integer  "heisig_id"
    t.integer  "language_id"
    t.string   "keyword"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "heisig_edition_id"
  end

  add_index "heisig_keywords", ["heisig_edition_id"], :name => "index_heisig_keywords_on_heisig_edition_id"
  add_index "heisig_keywords", ["heisig_id"], :name => "index_heisig_keywords_on_heisig_id"
  add_index "heisig_keywords", ["keyword"], :name => "index_heisig_keywords_on_keyword"
  add_index "heisig_keywords", ["language_id"], :name => "index_heisig_keywords_on_language_id"

  create_table "heisigs", :force => true do |t|
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "heisig_id"
    t.integer  "lesson_id"
  end

  add_index "heisigs", ["heisig_id"], :name => "index_heisigs_on_heisig_id"
  add_index "heisigs", ["kanji_id"], :name => "index_heisigs_on_kanji_id"
  add_index "heisigs", ["lesson_id"], :name => "index_heisigs_on_lesson_id"

  create_table "japanese_words", :force => true do |t|
    t.string   "word"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jlpts_kanjis", :force => true do |t|
    t.string   "level",      :limit => 5
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "joyos_kanjis", :force => true do |t|
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "level",      :limit => 5
  end

  create_table "kanji_lookups", :force => true do |t|
    t.integer  "dictionary_id"
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "dictionary_index_value"
  end

  create_table "kanjis", :force => true do |t|
    t.text     "kanji"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "stroke_count"
    t.integer  "ordinal_id"
    t.integer  "frequency"
    t.integer  "kanji_tree_edits_count",                                :default => 0
    t.string   "status",                                                :default => "U"
    t.integer  "occurence_count"
    t.decimal  "frequency_percentage",   :precision => 7,  :scale => 5
    t.integer  "rank"
    t.decimal  "cumulative_frequency",   :precision => 10, :scale => 7
  end

  add_index "kanjis", ["frequency"], :name => "index_kanjis_on_frequency"
  add_index "kanjis", ["frequency_percentage"], :name => "index_kanjis_on_frequency_percentage"
  add_index "kanjis", ["kanji"], :name => "index_kanjis_on_kanji"
  add_index "kanjis", ["occurence_count"], :name => "index_kanjis_on_occurence_count"
  add_index "kanjis", ["rank"], :name => "index_kanjis_on_rank"

  create_table "koreans", :force => true do |t|
    t.string   "korean"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "koreans_kanjis", :force => true do |t|
    t.integer  "korean_id"
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "kunyomis", :force => true do |t|
    t.string   "kunyomi"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kunyomis", ["kunyomi"], :name => "index_kunyomis_on_kunyomi"

  create_table "kunyomis_kanjis", :id => false, :force => true do |t|
    t.integer  "kanji_id"
    t.integer  "kunyomi_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kunyomis_kanjis", ["kanji_id"], :name => "index_kunyomis_kanjis_on_kanji_id"
  add_index "kunyomis_kanjis", ["kunyomi_id"], :name => "index_kunyomis_kanjis_on_kunyomi_id"

  create_table "kyuujitais", :force => true do |t|
    t.integer  "kanji_id"
    t.string   "kyuujitai"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kyuujitais", ["kanji_id"], :name => "index_kyuujitais_on_kanji_id"
  add_index "kyuujitais", ["kyuujitai"], :name => "index_kyuujitais_on_kyuujitai"

  create_table "languages", :force => true do |t|
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "meanings_kanjis", :id => false, :force => true do |t|
    t.integer  "kanji_id"
    t.string   "meaning_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "meanings_kanjis", ["kanji_id"], :name => "index_meanings_kanjis_on_kanji_id"
  add_index "meanings_kanjis", ["meaning_id"], :name => "index_meanings_kanjis_on_meaning_id"

  create_table "nanoris", :force => true do |t|
    t.string   "nanori"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nanoris", ["nanori"], :name => "index_nanoris_on_nanori"

  create_table "nanoris_kanjis", :id => false, :force => true do |t|
    t.integer  "kanji_id"
    t.integer  "nanori_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nanoris_kanjis", ["kanji_id"], :name => "index_nanoris_kanjis_on_kanji_id"
  add_index "nanoris_kanjis", ["nanori_id"], :name => "index_nanoris_kanjis_on_nanori_id"

  create_table "onyomis", :force => true do |t|
    t.string   "onyomi"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "onyomis", ["onyomi"], :name => "index_onyomis_on_onyomi"

  create_table "onyomis_kanjis", :id => false, :force => true do |t|
    t.integer  "kanji_id"
    t.integer  "onyomi_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "onyomis_kanjis", ["kanji_id"], :name => "index_onyomis_kanjis_on_kanji_id"
  add_index "onyomis_kanjis", ["onyomi_id"], :name => "index_onyomis_kanjis_on_onyomi_id"

  create_table "pinyins", :force => true do |t|
    t.integer  "kanji_id"
    t.string   "pinyin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pinyins", ["pinyin"], :name => "index_pinyins_on_pinyin"

  create_table "pinyins_kanjis", :force => true do |t|
    t.integer  "kanji_id"
    t.integer  "pinyin_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pinyins_kanjis", ["kanji_id"], :name => "index_pinyins_kanjis_on_kanji_id"
  add_index "pinyins_kanjis", ["pinyin_id", "kanji_id"], :name => "index_pinyins_kanjis_on_pinyin_id_and_kanji_id"
  add_index "pinyins_kanjis", ["pinyin_id"], :name => "index_pinyins_kanjis_on_pinyin_id"

  create_table "primitives", :force => true do |t|
    t.string   "primitive"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "equivalent_kanji_id"
    t.integer  "stroke_count"
  end

  add_index "primitives", ["equivalent_kanji_id"], :name => "index_primitives_on_equivalent_kanji_id"
  add_index "primitives", ["filename"], :name => "index_primitives_on_filename"
  add_index "primitives", ["primitive"], :name => "index_primitives_on_primitive"
  add_index "primitives", ["stroke_count"], :name => "index_primitives_on_stroke_count"

  create_table "primitives_kanjis", :id => false, :force => true do |t|
    t.integer  "primitive_id"
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "primitives_kanjis", ["kanji_id"], :name => "index_primitives_kanjis_on_kanji_id"
  add_index "primitives_kanjis", ["primitive_id"], :name => "index_primitives_kanjis_on_primitive_id"

  create_table "skips", :force => true do |t|
    t.string   "skip_pattern"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "skips", ["skip_pattern"], :name => "index_skips_on_skip_pattern"

  create_table "skips_kanjis", :force => true do |t|
    t.integer  "skip_id"
    t.integer  "kanji_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "skips_kanjis", ["kanji_id"], :name => "index_skips_kanjis_on_kanji_id"
  add_index "skips_kanjis", ["skip_id"], :name => "index_skips_kanjis_on_skip_id"

  create_table "tanaka_english_words", :force => true do |t|
    t.integer  "tanaka_sentence_id"
    t.integer  "english_word_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tanaka_japanese_words", :force => true do |t|
    t.integer  "tanaka_sentence_id"
    t.integer  "japanese_word_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tanaka_sentences", :force => true do |t|
    t.string   "english"
    t.string   "japanese"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
