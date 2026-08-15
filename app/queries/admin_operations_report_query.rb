class AdminOperationsReportQuery
  def initialize(params: {})
    @params = params
  end

  def call
    ensure_filters_exist!

    scope = Card.includes(:client, product: :brand).order(created_at: :desc)
    scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
    scope = scope.joins(:product).where(products: { brand_id: params[:brand_id] }) if params[:brand_id].present?
    apply_status(scope)
  end

  private

  attr_reader :params

  def ensure_filters_exist!
    Brand.find(params[:brand_id]) if params[:brand_id].present?
    User.client.find(params[:client_id]) if params[:client_id].present?
  end

  def apply_status(scope)
    case params[:status].to_s
    when "spending"
      scope.issued
    when "cancellations"
      scope.cancelled
    else
      scope
    end
  end
end
