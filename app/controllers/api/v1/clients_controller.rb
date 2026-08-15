module Api
  module V1
    class ClientsController < ApplicationController
      before_action :set_client, only: %i[update destroy]

      def index
        authorize User, policy_class: ClientPolicy
        render json: User.client.order(:email), each_serializer: ClientSerializer, root: "clients"
      end

      def create
        authorize User, policy_class: ClientPolicy
        client = User.new(client_params.merge(role: :client))

        if client.save
          log_action("create", client)
          render json: client, serializer: ClientSerializer, root: "client", status: :created
        else
          render_validation_errors(client)
        end
      end

      def update
        authorize @client, policy_class: ClientPolicy

        if @client.update(client_params)
          log_action("update", @client)
          render json: @client, serializer: ClientSerializer, root: "client"
        else
          render_validation_errors(@client)
        end
      end

      def destroy
        authorize @client, policy_class: ClientPolicy

        if @client.destroy
          log_action("destroy", @client)
          render json: { message: "Client deleted successfully" }, status: :ok
        else
          render_validation_errors(@client)
        end
      end

      private

      def set_client
        @client = User.client.find(params[:id])
      end

      def client_params
        params.require(:client).permit(:email, :password, :payout_rate).tap do |permitted|
          permitted.delete(:password) if permitted[:password].blank?
        end
      end
    end
  end
end
