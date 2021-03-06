module ApplicationHelper
  include CloudinaryHelper
  def image_url_with_fallback(image_url)
    if image_url.strip.empty?
      image_path 'social/home_facebook_card.png'
    else
      image_url.strip
    end
  end

  def markdown(content)
    return "" if content.blank?
    @markdown ||= (
      renderer = Redcarpet::Render::HTML.new
      Redcarpet::Markdown.new(renderer, extensions = {})
    )
    @markdown.render(content).html_safe
  end

  def structure(hash)
    object = JSON.parse(hash.to_json, object_class: OpenStruct)
  end

  def locale_current_url_for(locale)
    if locale == I18n.default_locale
      begin
        return url_for(controller: params[:controller], action: params[:action], locale: nil)
      rescue ActionController::UrlGenerationError
      end
    end
    url_for(controller: params[:controller], action: params[:action], locale: locale)
  rescue ActionController::UrlGenerationError => e
    puts e.message
  end

  def prerender?
    ENV['PRERENDER'] == 'false' ? false : true
  end

  def cl_adaptive_image_tag(image_path, opt={})
    w = opt[:width]
    h = opt[:height]
    image_url_2x = cloudinary_url image_path, width: 2 * w, height: 2 * h, crop: :fill
    image_url = cloudinary_url image_path, width: w, height: h, crop: :fill
    opt[:srcset] = "#{image_url} 1x, #{image_url_2x} 2x"
    return cl_image_tag image_path, opt
  end
end
