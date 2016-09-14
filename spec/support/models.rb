class User < ActiveRecord::Base

  search_syntax do

    search_by :text do |scope, phrases|
      scope.where_like([:name, :email, :city] => phrases)
    end

    search_by :city do |scope, city|
      # scope.scoped(:conditions => { :city => city })
      # scope.scoped(:conditions => ['city = ?', city]) #:conditions => { :city => city })
      scope.scoped(:conditions => { :city => city })
    end

    search_by :email do |scope, email|
      scope.scoped(:conditions => { :email => email })
    end

  end

  search_syntax do # multiple search_syntax directives are allowed

    search_by :role do |scope, role|
      scope.scoped(:conditions => { :role => role })
    end

    search_by :name_and_city_regex do |scope, regex|
      # Example for regexes that need to be and'ed together by syntax#build_exclude_scope
      regexp_operator = Minidusen::Util.regexp_operator(scope)
      first = scope.where("users.name #{regexp_operator} ?", regex)
      second = scope.where("users.city #{regexp_operator} ?", regex)
      first.merge(second)
    end

  end

end


class Recipe < ActiveRecord::Base

  validates_presence_of :name

  has_many :ingredients, :class_name => 'Recipe::Ingredient', :inverse_of => :recipe
  belongs_to :category, :class_name => 'Recipe::Category', :inverse_of => :recipes


  search_syntax do

    search_by :text do |scope, text|
      scope.where_like(:name => text)
    end

    search_by :category do |scope, category_name|
      scope.joins(:category).where('recipe_categories.name = ?', category_name)
    end

  end

end


class Recipe::Category < ActiveRecord::Base

  self.table_name = 'recipe_categories'

  validates_presence_of :name

  has_many :recipes, :inverse_of => :category

end


class Recipe::Ingredient < ActiveRecord::Base

  self.table_name = 'recipe_ingredients'

  validates_presence_of :name

  belongs_to :recipe, :inverse_of => :ingredients

end
