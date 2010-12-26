class RealitycheckController < ApplicationController

  skip_before_filter :verify_authenticity_token
  def ocr
    # convert to bmp
    path = params[:image_file].tempfile.path
    p path 
    `djpeg -bmp #{path}> #{path}.bmp`
    # run tesseract
    `tesseract #{path}.bmp #{path}`
    result = `cat #{path}.txt`
    p result
    #`rm #{path}.*`
    render :text => result
  end
end
