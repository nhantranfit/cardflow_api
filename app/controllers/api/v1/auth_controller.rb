module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!, only: :login

      def login
        user = User.find_by(email: params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password].to_s)
          render json: {
            token: JsonWebToken.encode({ sub: user.id, role: user.role }),
            user: user_json(user)
          }
        else
          render_unauthorized("Invalid email or password")
        end
      end

      def me
        render json: { user: user_json(current_user) }
      end
    end
  end
end
