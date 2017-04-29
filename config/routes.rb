Snorby::Application.routes.draw do

  resources :reputations do
    
    get :new_note
    post :create_note

    collection do
      post :apply
      delete :destroy_note
    end
  end

  resources :event_filterings do
    
    get :new_note
    post :create_note

    collection do
      post :apply
      delete :destroy_note
    end
  end

  resources :lookups
  
  resources :snmps do
    collection do
      post :mass_update
      get :search
    end
  end
  
  resources :traps do
    collection do
      get :search
    end
  end

  match '/dbversions/update'       => "dbversions#update_sources", :via => :post
  match '/rule_source/new'         => "dbversions#new_source"
  match '/rule_source'             => "dbversions#create_source",  :via => :post
  match '/rule_source/:id/edit'    => "dbversions#edit_source"
  match '/rule_source/:id'         => "dbversions#update_source",  :via => :put
  match '/rule_source/:id'         => "dbversions#destroy_source", :via => :delete
  
  resources :dbversions do
    get :update_sensors
    post :delete_rules

    collection do
      get  :stats
      get  :force_update
    end
  end

  resources :roles do
    get :add_users
    get :add_sensors
  end

  post 'saved_event_filters/create' => 'saved_event_filters#create'
  post 'saved_rule_filters/create' => 'saved_rule_filters#create'

  resources :saved_event_filters, :path => "/saved/event_filters" do
    
    collection do
      post :title
      post :update
    end

    member do
      get :view
      post :update
    end
  end

  resources :saved_searches, :path => "/saved/searches" do  
    collection do
      post :title
      post :update
    end

    member do
      get :view
      post :update
    end
  end
  match '/roles/:id/add_user/:user_id'        => 'roles#add_user'
  match '/roles/:id/delete_user/:user_id'     => 'roles#delete_user'
  match '/roles/:id/add_sensor/:sensor_sid'   => 'roles#add_sensor'
  match '/roles/:id/delete_sensor/:sensor_sid'=> 'roles#delete_sensor'

  match '/snmp_results', :controller => 'Snmps', :action => 'results'
  match '/trap_results', :controller => 'Traps', :action => 'results'

  #TODO revisar primer match para que solo exista una ruta hacia la misma acción

  match '/sensors/:sensor_id/rules/update_rule_action', :controller => 'Rules', :action => 'update_rule_action'
  match '/sensors/rules/active_rules.txt'             , :controller => 'Rules', :action => 'active_rules'         , :defaults => {:format => 'txt'}
  match '/sensors/rules/preprocessors_rules.txt'      , :controller => 'Rules', :action => 'preprocessors_rules'  , :defaults => {:format => 'txt'}
  match '/sensors/rules/thresholds.txt'               , :controller => 'Rules', :action => 'thresholds'           , :defaults => {:format => 'txt'}
  match '/sensors/rules/classifications.txt'          , :controller => 'Rules', :action => 'classifications'      , :defaults => {:format => 'txt'}
  match '/sensors/:sensor_id/update_rule_action'      , :controller => 'Rules', :action => 'update_rule_action'
  match '/sensors/:sensor_id/update_rule_overwrite'   , :controller => 'Rules', :action => 'update_rule_overwrite'
  match '/sensors/:sensor_id/update_rule_favorite'    , :controller => 'Rules', :action => 'update_rule_favorite'
  match '/sensors/:sensor_id/update_rules_action'     , :controller => 'Rules', :action => 'update_rules_action'
  match '/sensors/:sensor_id/update_rule_count'       , :controller => 'Rules', :action => 'update_rule_count'
  match '/sensors/:sensor_id/update_rule_category'    , :controller => 'Rules', :action => 'update_rule_category'
  match '/sensors/:sensor_id/update_rule_group'       , :controller => 'Rules', :action => 'update_rule_group'
  match '/sensors/:sensor_id/update_rule_family'      , :controller => 'Rules', :action => 'update_rule_family'
  match '/sensors/:sensor_id/update_rule_details'     , :controller => 'Rules', :action => 'update_rule_details'
  match '/sensors/:sensor_id/search'                  , :controller => 'Rules', :action => 'search', :as => 'sensor_search_rules'
  
  resources :rules do
    collection do
      get  :view
      get  :search
      get  :rule_box
      post :mass_update
      post :rollback
    end
  end

  resources :widgets do
    collection do
      post :change_position
      post :change_visibility
    end
  end

  get 'widgets/:id/reload'    => 'widgets#reload'       ,  :as => 'reload_widget'
  get 'widgets/:id/add'    => 'widgets#add_widget'      ,  :as => 'add_widget'
  get 'widgets/:id/show_table' => 'widgets#show_table'  ,  :as => 'show_table_widget'
  post 'widgets/:id/remove' => 'widgets#remove'         ,  :as => 'remove_widget'

  # This feature is not ready yet
  # resources :notifications

  resources :jobs do
    member do
      get :last_error
      get :handler
    end
  end

  resources :classifications do
    collection do
      get :auto
      get :new_auto
      post :create_auto
      post :update_auto
      post :order_auto
      match 'destroy_auto/:id' => 'classifications#destroy_auto', :via => [:delete]
      match 'edit_auto/:id'    => 'classifications#edit_auto', :via => [:get]
    end
  end

  match 'users/add' => 'users#add', :via => [:put]

  devise_for :users, :path_names => { :sign_in => 'login', 
    :sign_out => 'logout', 
    :sign_up => 'register' }, :controllers => { 
    :registrations => "registrations",
    :sessions => "sessions",
    :passwords => 'passwords'
  } do
    get "/login" => "devise/sessions#new"
    get '/logout', :to => "devise/sessions#destroy"
    get '/reset/password', :to => "devise/passwords#edit"
  end

  match 'users/:id' => 'users#update', :via => [:put]

  root :to => "application#passthrough"
  # root :to => "page#dashboard"
  match '/sensors/update_parent', :controller => 'Sensors', :action => 'update_parent'

  resources :sensors do
  
    resources :rules
    get :update_dashboard_info
    get :update_dashboard_rules
    get :update_dashboard_load
    get :update_dashboard_hardware
    get :update_dashboard_segments
    get :new_trap
    put :add_trap
    post :delete_trap
    post :bypass
 
    collection do
      get :update_parent
      get :search
      get :agent_list
    end

    resources :rules do
      collection do
        get :active_rules
        get :import
        put :import_file
        get :preprocessors_rules
        get :pending_rules
        get :compile_rules
        get :discard_pending_rules
        get :reset_rules
        get :compilations
        post :create_compile
        post :results
      end
    end
    resources :events
    resources :snmps
    resource :snort_stats do
      get :info
    end

    resource :log

    resources :saved_rule_filters do
    
      collection do
        post :title
        post :update
      end

      member do
        get :view
        post :update
      end
    end

  end

  resources :settings do
    collection do
      get :recreate_rsa
      get :restart_worker
      get :start_sensor_cache
      get :start_daily_cache
      get :start_geoip_update
      get :start_rule_update
      get :start_snmp
      get :start_main
      get :start_worker
      get :stop_worker      
      get :new_trap
      put :add_trap
      post :delete_trap    
    end
  end
  
  resources :signatures do
   
    collection do
      get :search
    end     
   
  end
   
  resources :severities do
    
  end

  resources :logs do
    collection do
      get :search
      get :search_sensor
      get :show_sensor
    end
  end
  
  resources :snort_stats do

    collection do
      get :names
      get :search
      get :info
    end
  end

  match '/dashboard', :controller => 'Page', :action => 'dashboard'
  match '/search', :controller => 'Page', :action => 'search'
  match '/results', :controller => 'Page', :action => 'results'
  match '/force/cache', :controller => "Page", :action => 'force_cache'
  match '/cache/status', :controller => "Page", :action => 'cache_status'
  match '/cluster' => 'page#cluster'
  match '/search/json', :controller => "Page", :action => 'search_json'

  get 'dashboard_tabs/:id/add'     => 'page#add_tab'    , :as => 'add_dashboard_tab'
  get 'dashboard_tabs/:id/change'  => 'page#change_tab' , :as => 'change_dashboard_tab'
  get 'dashboard_tabs/:id/delete'  => 'page#delete_tab' , :as => 'delete_dashboard_tab'
  get 'dashboard_tabs/:id/delete'  => 'page#delete_tab' , :as => 'delete_dashboard_tab'
  get 'dashboard_tabs/reorder'     => 'page#reorder_tab', :as => 'reorder_dashboard_tabs'

  get 'snmp_tabs/:id/add'     => 'snmps#add_tab'    , :as => 'add_snmp_tab'
  get 'snmp_tabs/:id/change'  => 'snmps#change_tab' , :as => 'change_snmp_tab'
  get 'snmp_tabs/:id/delete'  => 'snmps#delete_tab' , :as => 'delete_snmp_tab'
  get 'snmp_tabs/:id/delete'  => 'snmps#delete_tab' , :as => 'delete_snmp_tab'
  get 'snmp_tabs/reorder'     => 'snmps#reorder_tab', :as => 'reorder_snmp_tabs'

  get 'event_filter/:id/add'  => 'page#add_filter', :as => 'add_event_filter'
  get 'event_filter/:id/del'  => 'page#del_filter', :as => 'del_event_filter'

  get 'rule_filter/:id/add' => 'rules#add_filter', :as => 'add_rule_filter'
  get 'rule_filter/:id/del' => 'rules#del_filter', :as => 'del_rule_filter'
 
  match ':controller(/:action(/:sid/:cid))', :controller => 'Events'

  resources :events do
    resources :notes do
    end
    collection do
      get :sessions
      get :view
      get :create_mass_action
      post :mass_action
      get :filtered_events
      get :filter_event
      post :create_filter_event
      delete :delete_filter_event
      get :create_email
      post :email
      get :hotkey
      post :export
      get :lookup
      get :rule
      get :packet_capture
      get :history
      post :classify
      post :classify_sessions
      post :mass_update
      get :queue
      post :favorite
      get :last
      get :since
      get :activity
      get :by_sensor
      get :by_source_ip
      get :by_destination_ip
      get :prune_view
      post :prune
      get :update_events_count
      post :show_map
      get :ip_search
    end
    
  end

  resources :asset_names do
    member do
      delete :remove
    end

    collection do
      post :add
      get :lookup
      post :bulk_upload
      get 'get_bulk_upload', action: :get_bulk_upload, as: 'get_bulk_upload'
    end
  end
  
  resources :notes

  resources :users do
    collection do
      post :toggle_settings
      post :remove
      post :add
    end
  end

  resources :page do
    collection do
      get :dashboard
      get :search
      get :results
    end
  end
end

