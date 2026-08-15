class ClientOperationsReportQuery
  class Unprocessable < StandardError; end

  def initialize(client:, params: {})
    @client = client
    @params = params
  end

  def call
    scope = client.cards.includes(product: :brand).order(created_at: :desc)
    case params[:status].to_s
    when "spending"
      scope.issued
    when "cancellations"
      scope.cancelled
    else
      scope
    end
  end

  private

  attr_reader :client, :params
end
