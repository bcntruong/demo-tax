# frozen_string_literal: true

# Đảm bảo thư mục services được tự động load
Rails.application.config.autoload_paths += %W[#{Rails.root}/app/services]
