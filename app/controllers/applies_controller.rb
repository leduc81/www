# == Schema Information
#
# Table name: applies
#
#  id         :integer          not null, primary key
#  first_name :string
#  last_name  :string
#  age        :integer
#  email      :string
#  phone      :string
#  motivation :text
#  batch_id   :integer
#  city_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tracked    :boolean          default(FALSE), not null
#  source     :string
#

class AppliesController < ApplicationController
  include MoneyRails::ActionViewExtension

  def new
    prepare_apply_form
    if @city.nil?
      redirect_to send(:"apply_#{locale.to_s.underscore}_path", city: @applicable_cities.first['slug'])
    elsif params[:city].blank?
      redirect_to send(:"apply_#{locale.to_s.underscore}_path", city: @city['slug'])
    else
      @application = Apply.new(source: params[:source])
    end
  end

  def create
    @application = Apply.new(application_params)
    if @application.save
      session[:apply_id] = @application.id
      redirect_to send(:"thanks_#{I18n.locale.to_s.underscore}_path")
    else
      prepare_apply_form
      render :new
    end
  end

  private

  def prepare_apply_form
    @applicable_cities = @cities.select{ |city| !city['batches'].empty? }.each do |city|
      city['batches'].sort_by! { |batch| batch['starts_at'].to_date }
      first_available_batch = city['batches'].find { |b| !b['full'] }
      city['first_batch_date'] = first_available_batch.nil? ? nil : first_available_batch['starts_at'].to_date

      city['batches'].each do |batch|
        batch['starts_at'] = I18n.l batch['starts_at'].to_date, format: :apply
        batch['ends_at'] = I18n.l batch['ends_at'].to_date, format: :apply
        batch['price'] = humanized_money_with_symbol Money.new(batch['price_cents'], batch['price_currency'])
      end
    end

    @applicable_cities = @applicable_cities.reject { |c| c['first_batch_date'].nil? }

    # Sort by first available batch
    @applicable_cities.sort! do |city_a, city_b|
      if city_a['first_batch_date'] == city_b['first_batch_date']
        city_a['name'] <=> city_b['name']
      else
        city_a['first_batch_date'] <=> city_b['first_batch_date']
      end
    end

    if params[:city]
      @city = @applicable_cities.find { |city| city['slug'] == params[:city] }
    elsif session[:city]
      @city = @applicable_cities.find { |city| city['slug'] == session[:city] }
    end

    @city_groups.each do |city_group|
      slugs = city_group['cities'].map { |city| city['slug'] }
      city_group['cities'] = @applicable_cities.select { |applicable_city| slugs.include?(applicable_city['slug']) }
    end

    @city_group = @city_groups.find { |city_group| city_group['cities'].map { |city| city['slug'] }.include?(@city['slug']) } unless @city.nil?
  end

  def application_params
    params.require(:application).permit(:first_name, :last_name, :email, :age, :phone, :motivation, :source, :batch_id, :city_id)
  end
end
