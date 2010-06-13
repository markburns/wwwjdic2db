Dictionary.destroy_all
["radical", "classical_radical", "halpern", "nelson",
"new_nelson", "japanese_for_busy_people", "kanji_way", "japanese_flashcards", 
"kodansha", "hensall", "kanji_in_context", "kanji_learners_dictionary", 
"french_heisig", "o_neill", "de_roo", "sakade", "tuttle_flash_card",
"tuttle_dictionary", "tuttle_kanji_and_kana", "unicode", 
"four_corner", "heisig", "morohashi_index", 
"morohashi_volume_page", "henshall", "gakken", 
"japanese_names", "cross_reference", "misclassification"].each do |name|

  d= Dictionary.new :name => name
  d.save

end
