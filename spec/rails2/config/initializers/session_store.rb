# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails-2.3_session',
  :secret      => '76cc9f32d38e9b6227bd663076edcf28cc915dc3021da204763a73dbd0d2741f6f7074af21400d4f8f9ef6c4db72487c467edf4a1dfec732835c5674a9846dd7'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
