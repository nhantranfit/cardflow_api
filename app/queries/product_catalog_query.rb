class ProductCatalogQuery
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    scope = accessible_products
    scope = filter_by_brand(scope)
    scope = search_by_name(scope)
    scope = filter_by_status(scope)

    scope.order(:name)
  end

  private

  attr_reader :user, :params

  def accessible_products
    user.accessible_products
        .active
        .includes(:brand)
  end

  def filter_by_brand(scope)
    return scope if params[:brand_id].blank?

    scope.where(brand_id: params[:brand_id])
  end

  def search_by_name(scope)
    return scope if params[:search].blank?

    keyword = ActiveRecord::Base.sanitize_sql_like(params[:search])

    scope.where("products.name ILIKE ?", "%#{keyword}%")
  end

  def filter_by_status(scope)
    return scope if params[:status].blank?

    scope.where(status: params[:status])
  end
end
