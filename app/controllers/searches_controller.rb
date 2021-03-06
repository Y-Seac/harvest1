class SearchesController < ApplicationController
  before_action :set_search, only: [:show, :edit, :update, :destroy]
  before_action :get_ip,
  # GET /searches
  # GET /searches.json
  def index
    #Does a full text search on each model: Products, Markets, and Stores.
    query = preprocess(params[:q])
    if query == nil or query == ""
      query = nil
    end
    @query = params[:q]
    @page = 0

    # search products
    @search = Product.solr_search do
       fulltext params[:q]
       order_by :popularity, :desc
       paginate :page => 1, :per_page => Product.all.count
     end
    @products = @search.results

    if params[:tag].present?
      tag = params[:tag]
      @products = @products.select{ |product| product.tag.include?(tag)}
    end

    if params[:group].present?
      gro = params[:group]
      @products = @products.select{ |product| product.group.include?(gro)}
    end

    if params[:speciality].present?
      # search products
      @search1 = Product.solr_search do
         fulltext query
         paginate :page => 1, :per_page => Product.all.count
       end

      @search2 = Product.solr_search do
          fulltext preprocess(params[:speciality])
          paginate :page => 1, :per_page => Product.all.count
        end
      @products = @search1.results & @search2.results
    end

    # search stores
    @search = Store.solr_search do
        fulltext query
        paginate :page => 1, :per_page => Store.all.count
    end
    @stores = @search.results

    # search markets
    @search = Market.solr_search do
       fulltext query
       paginate :page => 1, :per_page => Market.all.count
    end
    @markets =  @search.results

    #Filters results based on selected option.
    if params[:option] == "Stores"
        @markets = []
        @products= []
        @stores = dst_SortStores(@stores)
        render "stores/index"
    elsif params[:option] == "Products"
        @markets = []
        @stores= []
        @products.reverse!
        # @products = @products.order("popularity DESC")
        @results = @products

        render "index"
    elsif params[:option] == "Markets"
        @products = []
        @stores= []
        @markets = dst_SortMarkets(@markets)
        @markets.each do |mkt|
          puts mkt.name
        end
        render "markets/index"
    else
        @products.reverse!
        # @products = @products.order("popularity DESC")
        render "index"
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
  end

  # GET /searches/new
  def new
    @search = Search.new
  end

  # GET /searches/1/edit
  def edit
  end

  # POST /searches
  # POST /searches.json
  def create
  end

  # PATCH/PUT /searches/1
  # PATCH/PUT /searches/1.json
  def update
    respond_to do |format|
      if @search.update(search_params)
        format.html { redirect_to @search, notice: 'Search was successfully updated.' }
        format.json { render :show, status: :ok, location: @search }
      else
        format.html { render :edit }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    @search.destroy
    respond_to do |format|
      format.html { redirect_to searches_url, notice: 'Search was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_search
      @search = Search.find(params[:id])
    end

    def get_ip
      @ip = request.remote_ip
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def search_params
      params.fetch(:search, {})
    end

    #input products list; output [product distance] in order of distance
    def dst_SortProducts(products)

      distances = []
      distProd = Hash.new

      products.each do |prod|
        if !distances.include? p_calculateDistance(prod)
          distances.push p_calculateDistance(prod)
          distProd[p_calculateDistance(prod)] = []
        end
        distProd[p_calculateDistance(prod)] = distProd[p_calculateDistance(prod)].push prod
      end

      distances.each do |d|
        distProd[d].sort!
      end

      distances.sort!
      sortedProducts = []
      distances.each do |d|
        sortedProducts.push *distProd[d]
      end
      return sortedProducts
    end

    #input products list; output [product distance] in order of distance
    #same algo as above
    def dst_SortStores(stores)
      distances = []
      distStores = Hash.new

      stores.each do |str|
        if !distances.include? s_calculateDistance(str)
          distances.push s_calculateDistance(str)
          distStores[s_calculateDistance(str)] = []
        end
        distStores[s_calculateDistance(str)] = distStores[s_calculateDistance(str)].push str
      end

      distances.each do |d|
        distStores[d].sort!
      end

      distances.sort!
      sortedStores = []
      distances.each do |d|
        sortedStores.push *distStores[d]
      end
      return sortedStores
    end

    #input products list; output [product distance] in order of distance
    #same algo as above
    def dst_SortMarkets(markets)
      distances = []
      distMark = Hash.new

      markets.each do |mkt|

        distMark[mkt] = m_calculateDistance(mkt)

      end
      sortedMarkets = []
      distMark.each do |key,value|
        puts key.name
        puts value
      end
      sorted_hash = distMark.sort_by {|_key, value| value}

      sorted_hash.each do |item|
        sortedMarkets.push item[0]
      end
      return sortedMarkets
    end

    def p_calculateDistance(product)
      distance = 12425 #fun trvia, farthest distance two cities can be in the world#returns the most closest market
      product.store.markets.each do |market|
        if Geocoder::Calculations.distance_between(Geocoder.coordinates(market.address + market.city + market.state), Geocoder.coordinates(remote_ip)) < distance #request.remote_ip instead of remote_ip
          distance = Geocoder::Calculations.distance_between(Geocoder.coordinates(market.address + market.city + market.state), Geocoder.coordinates(remote_ip))
        end
      end
      return distance
    end

    def s_calculateDistance(store)
      distance = 12425
      store.markets.each do |market|
        if Geocoder::Calculations.distance_between(Geocoder.coordinates(market.address + market.city + market.state), Geocoder.coordinates(remote_ip)) < distance#request.remote_ip instead of remote_ip
          distance = Geocoder::Calculations.distance_between(Geocoder.coordinates(market.address + market.city + market.state), Geocoder.coordinates(remote_ip))
        end
      end
      return distance
    end

    def m_calculateDistance(market)
      return distance = Geocoder::Calculations.distance_between(Geocoder.coordinates(market.address + market.city + market.state), Geocoder.coordinates(remote_ip)) #request.remote_ip instead of remote_ip
    end

    def preprocess(query)
      require 'rubygems'
      require 'fast_stemmer'
      # queries = query.split(" ").each do |word|
      #   if word == nil
      #     word = ""
      #   end
      #   Stemmer::stem_word(word)
      # end
      if query == nil
        query = ""
      end
      Stemmer::stem_word(query)
 # -> 'run'
    end
end
