# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

logger = Logger.new(STDOUT)
seed_file = Rails.root.join('config', 'seed.yml')

if File.exist?(seed_file)
  seed = YAML.safe_load(File.open(seed_file))

  admin = Account.create(email: seed['admin']['email'], password: SecureRandom.hex(20), level: 1, role: 'admin', confirmed_at: Time.current)

  logger.info "Admin credentials: #{admin.password}"

  # Create applications from seed
  seed['applications'].each do |app|
    result = Doorkeeper::Application.new(app)

    result.save!
    logger.info "Name: #{result.name}",
                "Application ID: #{result.uid}",
                "Secret: #{result.secret}"
  end
else
  admin_email = ENV.fetch('ADMIN_USER', 'admin@barong.io')
  admin = Account.create(email: admin_email, password: SecureRandom.hex(20), level: 1, role: 'admin', confirmed_at: Time.current)

  logger.info "Admin credentials: #{admin.password}"
end
