# frozen_string_literal: true

class IndexController < ApplicationController
  def index
    redirect_to new_account_session_url unless account_signed_in?
    return if current_account.blank?

    case current_account.level
      when 1
        redirect_to new_phone_path
      when 2 && !current_account.profile.try(:documents)
        redirect_to new_profile_path
    end
  end
end
