class CrawlerService

  def initialize(itens_to_index)
    @itens_to_index = itens_to_index
  end

  def create_merchant_from_yellow_pages
    @itens_to_index.each do |iten|
      sleep(2.seconds)
      url = "http://api.sandbox.yellowapi.com/FindBusiness/?what=#{iten}&where=Vancouver&pg=1&dist=1&fmt=JSON&lang=en&UID=mg5twsw7yws8tbupev6vhad2&apikey=mg5twsw7yws8tbupev6vhad2"
      # url = "http://api.yellowapi.com/FindBusiness/?what=shoes&where=Vancouver&pgLen=5&pg=1&dist=1&fmt=JSON&lang=en&UID=6h6zy72hrz6wcsmubmpzv7yn&apikey=6h6zy72hrz6wcsmubmpzv7yn"

      response = HTTParty.get(url)
      answer = JSON.parse(response.body)
      answer["listings"].each{ | store |
        address = store["address"]
        geoCode = store["geoCode"]
        params = {
          name: store["name"],
          street: address["street"],
          city: address["city"],
          prov: address["prov"],
          pcode: address["pcode"],
          category: iten
        }

        if geoCode.present?
          params[:latitude] = geoCode["latitude"]
          params[:longitude] = geoCode["longitude"]
        end

        Merchant.where(params).first_or_create
      }
      sleep(2.seconds)
    end
  end

  def self.create_products_randomicaly
    product_name_array = []
    File.readlines("#{Rails.root}/lib/data/products_name.txt").each do |line|
      product_name_array.push(line.gsub("\n",""))
    end

    Merchant.all.each do |merchant|
      products = rand(1000)
      i = 0
      puts "-- #{merchant.products.size}"
      if merchant.products.empty?
        puts "Finding products to #{merchant.name}"
        while i < products  do
          begin
            product_name = product_name_array[rand(product_name_array.size)]
            url = "http://api.duckduckgo.com/?q=#{product_name}&format=json&pretty=1"
            
            response = HTTParty.get(url)
            json = response.body
            answer = json && json.length >= 2 ? JSON.parse(json) : nil

            description = ""
            image_url = ""
            if answer["RelatedTopics"].present?
              topic = answer["RelatedTopics"][rand(0..answer["RelatedTopics"].size)]
              description = topic["Text"]
              if topic["Icon"].present?
                image_url = topic["Icon"]["URL"]
              end
            else
              description = Faker::Company.catch_phrase + " " + Faker::Lorem.sentence
            end
            product = {
              name: product_name,
              description: description,
              price: rand(1..10),
              image_url: image_url,
              merchant_id: merchant.id
            }
            Product.create(product)
            i += 1
          rescue Exception => e  
            puts e.message
          end  
        end
      end
    end
  end
end
