require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  
  def setup
  	@user = users(:jon)
  end

  test "micropost interface" do 
  	#log in as user go to root path and verify pagination
  	log_in_as(@user)
  	get root_path
  	assert_select 'div.pagination'
  	#prevent invalid microposts
  	assert_no_difference 'Micropost.count' do
  		post microposts_path, micropost: { content: "" }
  	end
  	assert_select 'div#error_explanation'
  	#accept valid submissions
  	content = "Text for valid submission"
  	assert_difference 'Micropost.count', 1 do
  		post microposts_path, micropost: { content: content}
  	end
  	#check micropost is now being show
  	assert_redirected_to root_url
  	follow_redirect!
  	assert_match content, response.body
  	#check that microposts can be deleted 
  	assert_select 'a', text: 'delete'
  	first_micropost = @user.microposts.paginate(page: 1).first
  	assert_difference 'Micropost.count',  -1 do
  		delete micropost_path(first_micropost)
  	end
  	# check microposts cannot be deleted from another user
  	get user_path(users(:archer))
  	assert_select 'a', text: 'delete', count: 0
  end

  test "micropost sidebar count" do
    log_in_as(@user)
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body
    # User with zero microposts
    other_user = users(:mallory)
    log_in_as(other_user)
    get root_path
    assert_match "0 microposts", response.body
    other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match "1 micropost", response.body
  end

end
