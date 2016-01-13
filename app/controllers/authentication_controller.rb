require "resolv"

class AuthenticationController < ApplicationController
  layout 'small_normal'
  skip_before_filter :authentication, :authorization, :legal
  
  def form
    render :layout => 'small_normal_bare'
  end
  
  def password_forgotten
    render :layout => 'small_normal_bare'
  end
  
  def personal_password_reset
    @user = User.find_by_email(params['email'])
    
    if @user && !@user.admin?
      flash[:notice] = I18n.t('notices.personal_password_reset_success')
      @user.reset_password
      @user.save
      UserMailer.reset_password(@user).deliver
    else
      flash[:error] = I18n.t('errors.personal_password_reset_mail_not_found')
    end
    
    redirect_to :action => 'form'
  end
  
  def login
    account_without_password = User.find_by_name(params[:username])
    if account_without_password && account_without_password.too_many_login_attempts?
      flash[:error] = I18n.t('errors.too_many_login_attempts')
      redirect_to :action => 'form'
    else
      account = Kor::Auth.login(params[:username], params[:password])

      if account
        account.update_attributes(:login_attempts => [])

        if account.expires_at && (account.expires_at <= Time.now)
          flash[:error] = I18n.t("errors.account_expired")
          redirect_to :action => "form"
        elsif !account.active
          reset_session
          flash[:error] = I18n.t("errors.account_inactive")
          redirect_to :action => "form"
        else
          session[:expires_at] = Kor.session_expiry_time
          session[:user_id] = account.id
          account.update_attributes(:last_login => Time.now)
          r_to = (back || current_user.home_page) || Kor.config['app.default_home_page'] || root_path

          if params[:fragment].present?
            params[:fragment] = nil if params[:fragment].match('{{')
            r_to += "##{params[:fragment]}" if params[:fragment].present?
          end

          redirect_to r_to
        end
      else
        if account_without_password
          account_without_password.add_login_attempt
          account_without_password.save
        end
        # reset_session cant be done here because of http://railsforum.com/viewtopic.php?id=1611
        # reset_session
        flash[:error] = I18n.t("errors.user_or_pass_refused")
        redirect_to :action => "form"
      end
    end
  end
  
  def logout
    reset_session
    flash[:notice] = I18n.t("notices.logged_out")    
    redirect_to root_path
  end
  
  def denied
    respond_to do |format|
      format.html do
        if !current_user
          redirect_to :controller => 'authentication', :action => 'form'
        else
          render :layout => 'normal_small'
        end
      end
      format.json do
        render :json => {:message => I18n.t('notices.access_denied')}, :status => 403
      end
    end
  end

  private
    def remote_ip_with_name
      "#{request.ip} (#{Resolv.getname(request.ip)})"
    rescue Resolv::ResolvError => e
      request.ip
    end

end
