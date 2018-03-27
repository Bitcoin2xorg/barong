# frozen_string_literal: true

seed_file = File.join(Rails.root, 'config', 'seed.yml')

if File.exist?(seed_file)
  seed = YAML.load(File.open(seed_file))

  admin = Account.create(
    email: seed['admin']['email'],
    password: seed['admin']['password'] || SecureRandom.hex(20),
    level: 1,
    role: 'admin',
    confirmed_at: Time.now
  )
  puts 'Admin credentials: %s' % [admin.password]

  # Create applications from seed
  seed['applications'].each do |app|
    result = Doorkeeper::Application.create(app)
    puts 'Name: %s' % [result.name]
    puts "Application ID: %s\nSecret: %s" % [result.uid, result.secret]
  end
else
  admin = Account.create(
    email: ENV.fetch('ADMIN_USER', 'admin@barong.io'),
    password: ENV.fetch('ADMIN_PASSWORD', SecureRandom.hex(20)),
    level: 1,
    role: 'admin',
    confirmed_at: Time.now
  )

  puts 'Admin credentials: %s' % [admin.password]
end
