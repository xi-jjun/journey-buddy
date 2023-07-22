class TestApiController < ApplicationController
  def test_def
    puts "check test_def start"
    Rails.cache.write('ke2y_2', 'value-2', expires_in: 1.minute)
    data = Rails.cache.read('key_1')
    puts "find data=#{data}"
    puts "check test_def end\n"
  end

  def send_post_data
    file = params[:file]
    file_info = { file: file, extension: File.extname(file.original_filename) }

    result = S3BucketManager.upload_file_to_s3(file_info)

    render json: result
  end
end
