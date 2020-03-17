class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :destroy, :pay, :confirm, :done]

  require 'payjp'

  def index
    @items = Item.all.limit(12)
    @images = Image.all
    @image = @images.where(item_id: @items.ids)
  end

  def show
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
    @user = User.find_by(id: @item.user_id)
    @images = Image.where(item_id: @item.id)
    @shipping_day = @item.shipping_days
    @area = @item.area
    @brand = Brand.find(@item.brand_id)
  end

  def confirm
    @images = Image.where(item_id: @item.id)
    card = Card.where(user_id: current_user.id).first
    if card.blank?
      redirect_to controller: "card", action: "new"
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(card.customer_id)
      @default_card_information = customer.cards.retrieve(card.card_id)
    end
  end

  def done
    @images = Image.where(item_id: @item.id)
  end

  def pay
    card = Card.where(user_id: current_user.id).first
    Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
    Payjp::Charge.create(
    :amount => @item.price, 
    :customer => card.customer_id, 
    :currency => 'jpy', 
      )
    redirect_to action: 'done' 
  end

  def new
    @item = Item.new
    @brands = Brand.all
    
    @category_parent_array = ["指定なし"]
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end
  
    @item.images.build
  end

  def create
    @item = Item.new(item_params)
    if @item.save && @item.images.count != 0
      @image = @item.images.create
      redirect_to :root
    else
      flash.now[:alert] = '画像を１枚以上添付してください'
      render :new
    end

  end

  def edit
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show
    end
  end

  def get_category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  private
  def item_params
    params.require(:item).permit(
      :name, :description, :price, :brand_id, :area, :condition, :fee,
      :shipping_days, images_attributes: [:content, :id, :_destroy]
      ).merge(user_id: current_user.id, category_id: params[:category_id], brand_id: params[:item][:brand_id])
  end

  

  def set_item
    @item = Item.find(params[:id])
  end
end