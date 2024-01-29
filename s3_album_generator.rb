require 'aws-sdk-s3'
require 'jekyll'

paypal_merchant_id = "your_paypal_merchant_id"
photo_price = "10.00"  # Price for individual photos
album_price = "100.00"  # Price for the entire album

module Jekyll
  class S3AlbumGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      # Initialize the S3 client
      s3_client = Aws::S3::Client.new(region: 'your-region')

      site.data['albums'].each do |album|
        s3_bucket, s3_path = album['s3_path'].split('/', 2)
        objects = s3_client.list_objects_v2(bucket: s3_bucket, prefix: s3_path).contents

        # Generate PayPal URLs
        image_purchase_urls = image_urls.map do |url|
            "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=#{paypal_merchant_id}&amount=#{photo_price}&item_name=Photo:#{File.basename(url)}"
          end
  
        album_purchase_url = "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=#{paypal_merchant_id}&amount=#{album_price}&item_name=Album:#{album['title']}"

        # Add PayPal URLs to album page data
        album_page.data['image_purchase_urls'] = image_purchase_urls
        album_page.data['album_purchase_url'] = album_purchase_url

        image_urls = objects.map do |object|
          "https://#{s3_bucket}.s3.your-region.amazonaws.com/#{object.key}"
        end

        # Generate an album page using Jekyll's Page class
        album_page = PageWithoutAFile.new(site, site.source, '_layouts', 'album.html')
        album_page.data['title'] = album['title']
        album_page.data['images'] = image_urls
        album_page.render(site.layouts, site.site_payload)
        album_page.write(site.dest)

        # Ensure the generated page is added to the site pages
        site.pages << album_page
      end
    end
  end
end
