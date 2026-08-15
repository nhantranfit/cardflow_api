module Api
  module V1
    class CardsController < ApplicationController
      before_action :set_card, only: :cancel

      def index
        authorize Card

        cards = current_user.cards.all

        render json: cards, each_serializer: CardSerializer
      end

      def create
        authorize Card

        card = IssueCard.new(
          client: current_user,
          product_id: card_params[:product_id]
        ).call

        log_action("create", card)
        render json: card, serializer: CardSerializer, status: :created
      rescue IssueCard::Forbidden => e
        render json: { error: "Forbidden", message: e.message }, status: :forbidden
      rescue IssueCard::Unprocessable => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      def cancel
        authorize @card

        if @card.issued?
          @card.update!(
            status: :cancelled,
            cancelled_at: Time.current
          )
          log_action("cancel", @card)

          render json: @card, serializer: CardSerializer
        else
          render json: { error: "Card is already cancelled" },
                 status: :unprocessable_content
        end
      end

      private

      def set_card
        @card ||= Card.find(params[:id])
      end

      def card_params
        params.require(:card).permit(:product_id)
      end
    end
  end
end
