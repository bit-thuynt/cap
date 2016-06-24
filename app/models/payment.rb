class Payment < ActiveRecord::Base
  has_many :cards
  accepts_nested_attributes_for 
  serialize :notification_params, Hash
  validates :order_id,  presence: true, uniqueness: { case_sensitive: false }
  validates :total,  presence: true
  validates :method,  presence: true
  # validates_associated :cards, if: :paid_with_card?
  # validates :cards, :presence => true, if: :paid_with_card?
  
  def paypal_url(return_path)
    values = {
        business: "normallstory-merchant@gmail.com",
        cmd: "_xclick",
        upload: 1,
        return: "#{Rails.application.secrets.app_host}#{return_path}",
        invoice: self.order_id,
        amount: self.total,
        item_name: "Pancake",
        item_number: 11,
        quantity: '1',
        notify_url: "#{Rails.application.secrets.app_host}/hook"
    }
    "#{Rails.application.secrets.paypal_host}/cgi-bin/webscr?" + values.to_query
  end
  
  def paypal_transaction_search
    values = {
        user: "normallstory-merchant_api1.gmail.com",
        pwd: "3NJQEYPH9ADGSKTC",
        signature: "AIVgWgUR7rLiiGrRzHN6UWUlWAvGAz7zbea6k-xIEIwbEDg5U.TY6eDJ",
        method: "TransactionSearch",
        startdate: '2012-01-01T05:38:48Z' ,   #Start date of the time range for the search
        enddate: '2012-01-31T05:38:48Z' ,    #End date of the time range for the search
        version: 94,
    }
    "https://api-3t.sandbox.paypal.com/nvp?" + values.to_query
  end
  
  def paid_with_card?
    self.method == 2
  end
  
end
