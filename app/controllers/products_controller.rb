require 'net/http'
require 'open-uri'
# require "system_timer"
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  helper_method :setup_payment
  
  PAYPAL_END_POINT_URL_TEST = "https://api-3t.sandbox.paypal.com/nvp"
  LOGIN = URI.escape("normallstory-merchant_api1.gmail.com")
  PASSWORD = URI.escape("3NJQEYPH9ADGSKTC")
  SIGNATURE = URI.escape("AIVgWgUR7rLiiGrRzHN6UWUlWAvGAz7zbea6k-xIEIwbEDg5U.TY6eDJ")

  # needs an array of hashes to be passed as the users list
  # ------------------------Example------------------------------------------------
  #user_1 = {:email=>"buyer_1254479426_per_1257321861_per@XXXXX.com",
  #          :amount=>10, :unique_id=>"020484", :note=>"Heres your money"}
  #user_2={:email=>"buyer2_1254493228_per@XXXXX.com", :amount=>10,
  #         :unique_id=>"270484", :note=>"more money for you"}
  #user_list = [user_1, user_2]
  #setup_payment (user_list)
  #----------------------------------------------------------------------------------

  def setup_payment(user_list)
    response = nil
    header = {"Content-Type"=>"application/x-www-form-urlencoded"}
    email_subject = URI.escape("Payment Notification")
    receiver_type =URI.escape("EmailAddress")
    currency = URI.escape("USD")
    version = URI.escape("56")
    method =URI.escape("MassPay")
    end_point_url = paypal_end_point
    user_information =  payable_info(user_list)
     final_url_string = "#{end_point_url}?METHOD=#{method}" +
          "&PWD=#{PASSWORD}" +
          "&USER=#{LOGIN}" +
           "&SIGNATURE=#{SIGNATURE}"+
            "&VERSION=#{version}"+
            "&EMAILSUBJECT=#{email_subject}"+
             "&CURRENCYCODE=#{currency}"+
             "&RECEIVERTYPE=#{receiver_type}"+
              "#{user_information}"

        # SystemTimer.timeout_after(20.seconds) do
          response = open(final_url_string)
        # end

  rescue OpenURI::HTTPError => error
   status_code = error.io.status[0]
   logger.error "[ERROR][Paypal] #{error.message }  :  #{error.backtrace} "
  rescue Timeout::Error=>time_out_error
   logger.error "[ERROR][Timeout Error] #{time_out_error.message} : #{time_out_error.backtrace}"
  rescue =>err
   logger.error "[ERROR][Something went wrong] #{err.message} : #{err.backtrace}"
  end

  #accepts an array of hash
  def payable_info(user_values)
    final_url_string=""
    array_size = user_values.size - 1
      0.upto(array_size) do  |index|
       final_url_string += "&L_EMAIL" + index.to_s + "=#{URI.escape(user_values[index][:email])}"
       final_url_string += "&L_AMT" + index.to_s + "=#{(user_values[index][:amount])}"
       final_url_string += "&L_UNIQUEID" + index.to_s + "=#{URI.escape(user_values[index][:unique_id])}"
       final_url_string += "&L_NOTE" + index.to_s + "=#{URI.escape(user_values[index][:note])}"
     end
     final_url_string
  end

  # defines the paypal_end_point
  def paypal_end_point
    (ENV['RAILS_ENV'] == 'development') ? PAYPAL_END_POINT_URL_TEST : "something else"
  end
  
  # GET /products
  # GET /products.json
  def index
    @products = Product.all
    
    # user_list = [{:email=>"normallstory-buyer@gmail.com", :amount=>10, :unique_id=>"020484", :note=>"Heres your money"}]
    # setup_payment(user_list)
    
    #########################################
    # mass payment
    #########################################
    # require 'paypal-sdk-merchant'
#     
    # @api = PayPal::SDK::Merchant::API.new
#     
    # # Build request object
    # @mass_pay = @api.build_mass_pay({
        # :ReceiverType => "EmailAddress",
        # :MassPayItem => [{
            # :ReceiverEmail => "normallstory-buyer@gmail.com",
            # :Amount => {
                # :currencyID => "EUR",
                # :value => "3.00"
            # }
        # }]
    # })
#     
    # # Make API call & get response
    # @mass_pay_response = @api.mass_pay(@mass_pay)
#     
    # # Access Response
    # if @mass_pay_response.success?
    # else
      # @mass_pay_response.Errors
    # end
    
    #########################################
    
    #########################################
    # Adaptive payment
    #########################################
    require 'paypal-sdk-adaptivepayments'
    # PayPal::SDK.configure(
      # :mode      => "sandbox",  # Set "live" for production
      # :app_id    => "APP-80W284485P519543T",
      # :username  => "jb-us-seller_api1.paypal.com",
      # :password  => "WX4WTU3S8MY44S7F",
      # :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31A7yDhhsPUU2XhtMoZXsWHFxu-RWy" )
    
    @api = PayPal::SDK::AdaptivePayments.new
    
    paykey = {:pay_key => "AP-8ER24381X2446471E" }
    @payment_details = @api.build_payment_details( paykey || default_api_value)
    @payment_details_response = @api.payment_details(@payment_details) if request.post?
    render plain: @payment_details_response.inspect
      return
      
    # Build request object
    @pay = @api.build_pay({
      :actionType => "PAY",
      :cancelUrl => "http://localhost:3000/products/show",
      :currencyCode => "USD",
      :feesPayer => "SENDER",
      :ipnNotificationUrl => "http://localhost:3000/products/show",
      :receiverList => {
        :receiver => [{
          :amount => 1.0,
          :email => "normallstory-buyer@gmail.com" }] },
      :returnUrl => "http://localhost:3000/products/show" })
    
    # Make API call & get response
    @response = @api.pay(@pay)
    puts "payment"
    puts @response.inspect
    # Access response
    if @response.success? && @response.payment_exec_status != "ERROR"
      @response.payKey
      # render plain: @response.inspect
      # return
      redirect_to @api.payment_url(@response)  # Url to complete payment
    else
      @response.error[0].message
      puts "message"
    end
    #########################################
     payment_details
  end
  
  def payment_details
    
  end

  # GET /products/1
  def order
    @product = Product.find(params[:id])
  end
  
  # GET /products/1
  # GET /products/1.json
  def show
    render plain: params.inspect
    return
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:name, :desc, :price, :image, :recurring, :del_flg)
    end
end
