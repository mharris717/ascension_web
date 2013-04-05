class CoffeeGetAccess < Sprockets::Processor
  def evaluate(context,locals)
    body = data
    
    body = body.gsub(/@\$(\w+)/) do |str| 
      var = str[2..-1]
      "@get('#{var}')"
    end
    body = body.gsub(/\.\$(\w+)/) do |str| 
      var = str[2..-1]
      ".get('#{var}')"
    end
    
    body
  end
end

#Rails.application.assets.register_preprocessor 'application/javascript', CoffeeGetAccess