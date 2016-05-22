class CrawlerService

  def initialize(itens_to_index)
    @itens_to_index = itens_to_index
  end

  def create_merchant_from_yellow_pages
    @itens_to_index.each do |iten|
      sleep(2.seconds)
      url = "http://api.sandbox.yellowapi.com/FindBusiness/?what=#{iten}&where=Vancouver&pg=1&dist=1&fmt=JSON&lang=en&UID=mg5twsw7yws8tbupev6vhad2&apikey=mg5twsw7yws8tbupev6vhad2"

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
    end
  end

  def self.create_products_randomicaly
    product_name_array = []
    File.readlines("#{Rails.root}/lib/data/products_name.txt").each do |line|
      product_name_array.push(line.gsub("\n",""))
    end

    Merchant.all.each do |merchant|
      products = rand(100)
      i = 0
      if merchant.products.empty?
        puts "Finding products for #{merchant.name}"
        while i < products  do
          sleep(1.seconds)
          product_name = product_name_array[rand(product_name_array.size)]
          url = "http://api.duckduckgo.com/?q=#{product_name}&format=json&pretty=1"
          
          response = HTTParty.get(NormalizeUrl.process(url))
          json = response.body
          answer = json && json.length >= 2 ? JSON.parse(json) : nil

          description = ""
          image_url = ""
          if answer.present? && answer["RelatedTopics"].present?
            topics = answer["RelatedTopics"]
            if topics.present?
              topic = topics[rand(0..answer["RelatedTopics"].size-1)]
              description = topic["Text"] 
              if topic["Icon"].present?
                image_url = topic["Icon"]["URL"]
              end
            end
          else
            description = Faker::Company.catch_phrase + " " + Faker::Lorem.sentence
          end
          Product.create({
            name: product_name,
            description: description,
            price: rand(1..10),
            image_url: image_url,
            merchant_id: merchant.id
          })
          i += 1
        end
      end
    end
  end

  def self.create_rate_randomicaly
    Merchant.all.each do |merchant|
      merchant.update_attributes({
        stars: rand(1..5),
        rate_score: (rand Math::E..Math::PI).round(2)
      })
      merchant.products.each{ |product|
        product.update_attributes({
          price: (rand Math::E..100.99).round(2)
        })
      }
    end
  end

  def self.find_products_images
    Product.all.each{ |product|
      name = product.name.split(" ")[0].gsub(/[^0-9A-Za-z]/, '')
      url = "https://pixabay.com/api/?key=2614199-8667051b6952c194574bdfa73&q=#{name}&image_type=photo&pretty=true"
 
      response = HTTParty.get(NormalizeUrl.process(url))
      json = response.body
      answer = json && json.length >= 2 ? JSON.parse(json) : nil

      if !answer["hits"].empty?
        hit = answer["hits"][rand(0..answer["hits"].size-1)]
        
        product.update_attributes({
          image_url: hit["webformatURL"]
        })
      end
    }
  end
end
