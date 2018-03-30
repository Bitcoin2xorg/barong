# frozen_string_literal: true

FactoryBot.define do
  factory :doorkeeper_application, class: Doorkeeper::Application do
    name { Faker::RickAndMorty.character }
    redirect_uri { Faker::Internet.url }
  end
end
