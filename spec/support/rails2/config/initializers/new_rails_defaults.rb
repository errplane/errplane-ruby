if defined?(ActiveRecord)
  ActiveRecord::Base.include_root_in_json = true
  ActiveRecord::Base.store_full_sti_class = true
end

ActionController::Routing.generate_best_match = false
ActiveSupport.use_standard_json_time_format = true
ActiveSupport.escape_html_entities_in_json = false
