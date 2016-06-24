class PaymentController < ApplicationController
  
  def index
    # get from paypal
    # @payments = Payment.all
  end
  
  def new
    product = Product.find(payment_params[:product])
    
    if product
      total = product.price * payment_params[:quantity].to_d
      
      case params[:payment_method]
        
        when "paypal"
          
          return_path = home_index_path;
          values = {
              business: "normallstory-balton@gmail.com",
              cmd: "_xclick",
              upload: 1,
              return: "#{Rails.application.secrets.app_host}#{return_path}",
              amount: total,
              item_name: product.name,
              quantity: payment_params[:quantity],
              #notify_url: "#{Rails.application.secrets.app_host}/hook"
          }
          paypal_url = "#{Rails.application.secrets.paypal_host}/cgi-bin/webscr?" + values.to_query
          # go to paypal page
          redirect_to paypal_url
          
        else # credit card
          
          if purchase(total)
            redirect_to home_index_path, notice: 'This transaction is success'
          else
            redirect_to home_index_path, alert: 'This transaction cannot be processed'
          end
          
      end
      
    else
      # go to home page
      redirect_to home_index_path
    end
    
  end
  
  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def payment_params
      params.permit(:product, :method, :quantity,:payment_method)
    end
    
    def card_params
        params.require(:card).permit( :first_name, :last_name, :card_type, :card_number, :card_verification, :card_expires_on)
    end
    
    def purchase(price_in_cents)
      card = card_params
      month = Date.civil(*params[:card][:card_expires_on].sort.map(&:last).map(&:to_i)).month
      year = Date.civil(*params[:card][:card_expires_on].sort.map(&:last).map(&:to_i)).year
      credit_card = ActiveMerchant::Billing::CreditCard.new(
          type:                card[:card_type],
          number:              card[:card_number],
          verification_value:  card[:card_verification],
          month:               month,
          year:                year,
          first_name:          card[:first_name],
          last_name:           card[:last_name],
      )
      response = GATEWAY.purchase(price_in_cents, credit_card, purchase_options)
      response.success?
    end
    
    def purchase_options
    {
        ip: request.remote_ip,
        billing_address: {
            name:      "Flaying Cakes",
            address1:  "123 5th Av.",
            city:      "New York",
            state:     "NY",
            country:   "US",
            zip:       "10001"
        }
    }
    end
    
end
