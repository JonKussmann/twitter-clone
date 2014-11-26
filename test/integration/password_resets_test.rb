require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  
  def setup
  	ActionMailer::Base.deliveries.clear
  	@user = users(:jon)
  end

  test "password resets" do
	get new_password_reset_path
	assert_template 'password_resets/new'
	# Attempt to reset password for an invalid email address
	post password_resets_path, password_reset: {email: "" }
	assert_not flash.empty?
	assert_template 'password_resets/new'
	# Reset password with a valid email address
	post password_resets_path, password_reset: { email: @user.email}
	assert_not_equal @user.reset_digest, @user.reload.reset_digest
	assert_equal 1, ActionMailer::Base.deliveries.size
	assert_not flash.empty?
	assert_redirected_to root_url
	# Get user from the password reset form
	user = assigns(:user)
	# Attempt to reset password with the wrong email
	get edit_password_reset_path(user.reset_token, email: "")
	assert_redirected_to root_url
	#Attempt to reset password of non-activated account
	user.toggle!(:activated)
	get edit_password_reset_path(user.reset_token, email: user.email)
	assert_redirected_to root_url
	#Attempt to reset password with activated account, correct email, WRONG token
	user.toggle!(:activated)
	get edit_password_reset_path('wrong token', email: user.email)
	assert_redirected_to root_url
	# Reset password, all valid fields, get edit password page
	get edit_password_reset_path(user.reset_token, email: user.email)
	assert_template 'password_resets/edit'
	assert_select "input[name=email][type=hidden][value=?]", user.email
	# New password and confirmation do not match
	patch password_reset_path(user.reset_token),
		  email: user.email,
		  user: { password:            "password1",
				password_confirmation: "password2"}
	assert_select 'div#error_explanation'
	# Password and confirmation are blank
	patch password_reset_path(user.reset_token),
          email: user.email,
          user: { password:              "  ",
                  password_confirmation: "  " }
    assert_not flash.empty?
    assert_template 'password_resets/edit' 
    #Valid password and confirmation
    patch password_reset_path(user.reset_token),
          email: user.email,
          user: { password:              "password",
                  password_confirmation: "password" }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
