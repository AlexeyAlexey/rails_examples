# README

### [Branch: Init required gems](https://github.com/AlexeyAlexey/rails_examples/tree/feature/default-gems)


The following gems will be used to implement **Authentication/Authorization**

* bcrypt

* jwt

* rotp


**rack-cors** gem provides support for Cross-Origin Resource Sharing (CORS) for Rack compatible web applications.


**dotenv-rails** is used to load environment variables from .env into ENV in development/testing environment.


**Testing**

 * factory_bot_rails
 
 * rspec-rails

 * database_cleaner-active_record



**RuboCop** is a Ruby static code analyzer and code formatter.

  * rubocop-performance

  * rubocop-rails

  * rubocop-rspec

  * rubocop-factory_bot



### [Branch: Setting up Rubocop - branch](https://github.com/AlexeyAlexey/rails_examples/tree/feature/rubocop-settuping)


Disabled some styles

Disabled some styles for some parts of code

Fixed some offenses


### [Branch: Added Service Object]()

  You can find a lot of topics about **Rails Service Objects**

  I copied it from [simple_command gem](https://github.com/nebulab/simple_command)



```ruby
module Services
  class AuthenticateUser
    # put ApplicationService before the class' ancestors chain
    prepend ApplicationService

    # optional, initialize the command with some arguments
    def initialize(email, password)
      @email = email
      @password = password
    end

    # mandatory: define a #call method. its return value will be available
    #            through #result
    def call
      begin
        if user = User.find_by(email: @email)&.authenticate(@password)
          return user
        else
          user_readable_errors.add(:base, :failure)
        end
      rescue StandardError => e
        user_readable_errors.add(:base, :failure)
        exceptions.add(:exception, "[#{self.class.name}] #{e.message}")
      end
      nil
    end
  end
end

service = Services::AuthenticateUser.call(user, password)

if service.success?
  # service.result will contain the user instance, if found
  session[:user_token] = service.result.secret_token
  redirect_to root_path
else
  Rails.logger.error service.exceptions.full_messages.join('; ') if service.exceptions.present?

  flash.now[:alert] = service.user_readable_errors[:base].join(' ')

  render :new
end
```

## Access Tokens (JWT) + Refresh Tokens - in progress

There is a branch where I am playing around it.


Branch: **feature/jwt-authorization-authentication**

[Merge Request](https://github.com/AlexeyAlexey/rails_examples/pull/2/files)


[What Are Refresh Tokens and How to Use Them Securely](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/)

I have divided the task into the following tasks

1. Refresh Token
  
  - Token issuing

  - token rotation

  - Automatic **Reuse Detection** (You can read [What Are Refresh Tokens and How to Use Them Securely](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/) topic to know more about it)

  - Refactoring

    - Paritions



2. Access Tokens


3. sign up
  
  - email

  - phone

  - one time password

4. sign in

  - two factor authentication

I will add more information about this task to a README to **feature/jwt-authorization-authentication** branch
