require 'migration/iiif'

RSpec.describe Migration::IIIF do
  let(:instance) { described_class.new('http://test.host') }

  before do
    expect(File).to receive(:new).and_return(double)
  end

  context '#migrate_featured_images' do
    let!(:old_exhibit_thumbnail) { FactoryGirl.create(:featured_image, type: nil, iiif_tilesource: nil) }
    let!(:exhibit) { FactoryGirl.create(:exhibit, thumbnail_id: old_exhibit_thumbnail.id) }
    let(:updated_thumb) { Spotlight::FeaturedImage.find(old_exhibit_thumbnail.id) }

    context "when it's an exhibit thumbnail" do
      it 'migrates to an ExhibitThumbnail class and stores the image in the correct directory' do
        instance.run
        expect(updated_thumb.class).to eq Spotlight::ExhibitThumbnail
        expect(Spotlight::Exhibit.find(exhibit.id).thumbnail).to eq updated_thumb
      end

      it 'stores the image in the correct directory for the ExhibitThumbnail class' do
        instance.run
        expect(updated_thumb.image.file.file).to match(%r{/spotlight/exhibit_thumbnail/image/#{old_exhibit_thumbnail.id}})
      end
    end

    context "when it's any FeaturedImage" do
      it 'updates the iiif_tilesource attribute based on the given host and image resource' do
        instance.run
        expect(updated_thumb.iiif_tilesource).to eq "http://test.host/images/#{updated_thumb.id}/info.json"
      end

      it 'returns a nil region if one was not set' do
        instance.run
        expect(updated_thumb.iiif_region).to be_nil
      end

      it 'updates the iiif_region attribute based on the legacy crop coordinates' do
        old_exhibit_thumbnail.image_crop_x = '1'
        old_exhibit_thumbnail.image_crop_y = '1'
        old_exhibit_thumbnail.image_crop_w = '400'
        old_exhibit_thumbnail.image_crop_h = '400'
        old_exhibit_thumbnail.save

        instance.run
        expect(updated_thumb.iiif_region).to eq '1,1,400,400'
      end
    end
  end

  describe '#migrate_contact_avatars' do
    let(:file) { double }
    let(:contact1) { Spotlight::Contact.create }
    let(:contact2) { Spotlight::Contact.create }
    before do
      allow(File).to receive(:new).and_return(file)
      allow(contact1).to receive('read_attribute_before_type_cast').and_call_original
      allow(contact2).to receive('read_attribute_before_type_cast').and_call_original
      allow(contact1).to receive('read_attribute_before_type_cast').with('avatar').and_return('file1.jpg')
      allow(contact2).to receive('read_attribute_before_type_cast').with('avatar').and_return('file2.jpg')
    end
    it 'migrates' do
      expect do
        instance.send :migrate_contact_avatars
      end.to change { Spotlight::FeaturedImage.count }.by(2)
      expect(Spotlight::Contact.all.pluck(:avatar_id)).to eq Spotlight::FeaturedImage.all.pluck(:id)
    end
  end
end
