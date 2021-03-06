class PortAuthority::Session

  attr_accessor :request, :response, :mailer, :logger

  def index(message)
    @users = User.all(:active => true) if @request.environment == "development"
    @response.message("success", message) if message
    @response.render("session/index", :users => @users, :referrer => referrer)
  end

  def create(login, password)
    if (status = @request.session.authenticate(login, password)).success?
      # audit "Login"
      @response.redirect(referrer)
    else
      # audit "FailedLogin", [login, password]
      @users = User.all(:active => true) if @request.environment == "development"
      @request.params["status"] = status

      if PortAuthority::redirect_failed_logins_to_referrer?
        @response.redirect(referrer, :error => status)
      else
        @response.render "session/index", :error => status, :users => @users, :referrer => referrer
      end
    end
  end

  def delete
    # audit "Logout"
    @request.session.abandon!
    @response.redirect "/session"
  end

  private

  def referrer
    if @request.params["referrer"]
      @request.params["referrer"]
    elsif @request.referrer !~ /\/(session|(account\/(password|reset_password)))/
      @request.referrer
    else
       "/"
    end
  end

end
