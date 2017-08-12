# frozen_string_literal: true

class AuthorizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_authorization

  def destroy
    @authorization.destroy
    redirect_to account_path, notice: 'Disconnected!'
  end

  private

  def set_authorization
    @authorization = current_user.authorizations.find(params[:id])
  end
end
