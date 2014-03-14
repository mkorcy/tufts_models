require 'spec_helper'

describe 'catalog/index.html.erb' do
  before do
    @document_list = [SolrDocument.new(id: 'some_id')]
    view.stub current_user: double(admin?: true),
      has_search_parameters?: true,
      render_grouped_response?: false,
      blacklight_config: CatalogController.new.blacklight_config,
      link_to_document: '',
      render_index_doc_actions: ''
    Deprecation.stub(:silence)
    stub_template 'catalog/_search_sidebar.html.erb' => '',
      'catalog/_search_header.html.erb' => '',
      'catalog/_results_pagination.html.erb' => ''
    @response = double(:response, empty?: false, params: {})
  end

  describe 'checkboxes' do
    before do
      view.stub render_document_partial: ''
      render
    end
    it 'submits to the right spot' do
      expect(rendered).to have_selector("form[action*='#{edit_batch_edits_path}']")
    end
    it 'has a box to select all documents' do
      expect(rendered).to have_selector("input#check_all[type=checkbox]")
    end
    it 'has an edit button' do
      expect(rendered).to have_selector("button#batch-edit")
    end
    it 'lets you select individual documents' do
      expect(rendered).to have_selector("input[type=checkbox][name='batch_document_ids[]'][value='#{@document_list.first.id}']")
    end
  end

  describe 'with a document that is an image' do
    before do
      @document_list = [SolrDocument.new(id: 'id2', has_model_ssim: ['fedora/cm:Image.4DS'])]
      render
    end
    it 'displays thumbnails' do
      src = download_path(@document_list.first.id, datastream_id: 'Thumbnail.png')
      expect(rendered).to have_selector("#documents .document-thumbnail img[src='#{src}']")
    end
  end
end