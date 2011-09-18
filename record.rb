module User
  module Query
    def self.by_id(id)
      puts 5
    end
  end

  module Record
  end
end

User = Class.new(ActiveRecord::Base)
User.extend(Query)
User.include(Record)

# objects

User::Query.by_id(1234)
User.find_by_id(1234)

Coupon::Query.by_user(alice)
Coupon.by_user(alice)

#User::Record.new(:a => 1, :b => 2)

