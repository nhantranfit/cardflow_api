class IssueCard
  class Error < StandardError; end
  class Forbidden < Error; end
  class Unprocessable < Error; end

  MAX_ACTIVATION_RETRIES = 5

  def initialize(client:, product_id:)
    @client = client
    @product_id = product_id
  end

  def call
    product = find_product!
    ensure_product_accessible!(product)
    ensure_product_active!(product)

    create_card!(product)
  end

  private

  attr_reader :client, :product_id

  def find_product!
    Product.find(product_id)
  end

  def ensure_product_accessible!(product)
    return if client.accessible_products.exists?(id: product.id)

    raise Forbidden, "You do not have access to this product"
  end

  def ensure_product_active!(product)
    return if product.active?

    raise Unprocessable, "Product is not active"
  end

  def create_card!(product)
    purchase_amount = calculate_purchase_amount(product)
    attempts = 0

    begin
      attempts += 1
      Card.create!(
        client: client,
        product: product,
        purchase_amount: purchase_amount,
        activation_number: generate_activation_number,
        pin: generate_pin,
        status: :issued
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      retry if activation_collision?(e) && attempts < MAX_ACTIVATION_RETRIES
      raise
    end
  end

  def calculate_purchase_amount(product)
    (product.price * client.payout_rate).round(2)
  end

  def generate_activation_number
    SecureRandom.alphanumeric(16).upcase
  end
  def generate_pin
    SecureRandom.random_number(10_000).to_s.rjust(4, "0")
  end

  def activation_collision?(error)
    case error
    when ActiveRecord::RecordNotUnique
      error.message.include?("activation_number")
    when ActiveRecord::RecordInvalid
      error.record.errors.of_kind?(:activation_number, :taken)
    else
      false
    end
  end
end
