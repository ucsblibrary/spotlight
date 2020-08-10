# frozen_string_literal: true

FactoryBot.define do
  factory :search, class: 'Spotlight::Search' do
    exhibit
    sequence(:title) { |n| "Exhibit Search #{n}" }
    sequence(:slug) { |n| "Search#{n}" }

    after(:build) { |search| search.thumbnail = FactoryBot.create(:featured_image) }
  end

  factory :published_search, parent: :search do
    published { true }
  end

  factory :default_search, class: 'Spotlight::Search' do
    exhibit
    title { 'All exhibit items' }
    long_description { 'All items in this exhibit.' }

    after(:build) { |search| search.thumbnail = FactoryBot.create(:featured_image) }
  end
end
