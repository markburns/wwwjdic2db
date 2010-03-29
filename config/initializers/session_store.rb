# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_importer_rails_session',
  :secret      => '74eb0276d641fa9095ababe7c588027f72554af81d45ef3b673234b42808d93c4f705620d9dca56273398f9f125a1d9deb86f7cab2b669ab81a504c0428ba8a1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
