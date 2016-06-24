json.array!(@products) do |product|
  json.extract! product, :id, :name, :desc, :price, :image, :recurring, :del_flg
  json.url product_url(product, format: :json)
end
