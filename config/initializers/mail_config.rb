# Snorby Mail Configuration

# #
# Gmail Example:
#a
 ActionMailer::Base.delivery_method = :smtp
 ActionMailer::Base.smtp_settings = {
   :address              => "mail.example.com",
   :port                 => 25,
#   :user_name            => "user_name@domain.com",
#   :password             => "password",
#   :authentication       => "login",
#   :enable_starttls_auto => true      #(optional)
 }
# 
# At the general setting the Company Email sould be the same as the specified above
# By default is admin@redborder.net

# #
# Sendmail Example:
# 
# ActionMailer::Base.delivery_method = :sendmail
# ActionMailer::Base.sendmail_settings = {
#   :location => '/usr/sbin/sendmail',
#   :arguments => '-i -t'
# }
#
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = false

# Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
