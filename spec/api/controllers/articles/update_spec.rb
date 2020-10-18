RSpec.describe Api::Controllers::Articles::Update, type: :action do
  let(:action) { described_class.new }
  let(:params) { Hash[] }
  let(:article_repository) { ArticleRepository.new }
  let(:user_repository) { UserRepository.new }
  let(:tag_repository) { TagRepository.new }
  let(:user) { user_repository.create(FactoryBot.attributes_for(:user)) }
  let(:user2) { user_repository.create(FactoryBot.attributes_for(:user2)) }
  let(:article) { article_repository.create_with_tags(FactoryBot.attributes_for(:article).merge(author_id: user.id)) }
  let(:article2) { article_repository.create_with_tags(FactoryBot.attributes_for(:article2).merge(author_id: user2.id)) }

  describe "update article" do

    before do
      tag_repository.clear
      user_repository.clear
      article_repository.clear

      user
      article
      article2
    end

    it 'is need authentication' do
      response = action.call(params)
      expect(response[0]).to eq 401
    end

    it 'is successful' do
      params = JSON('
        {
          "article": {
            "title": "How to train your dragon (UPDATED)"
          }
        }
      ')
      response = action.call(params.merge('slug' => 'how-to-train-your-dragon', 'HTTP_AUTHORIZATION' => "Token #{JWTHelper.decode(user)}"))
      expect(response[0]).to eq 200

      response_hash = JSON(response[2][0], symbolize_names: true)
      article_from_response = response_hash[:article]
      expect(article_from_response).to  be_an_instance_of(Hash)
      expect(article_from_response).to include({
        "slug": "how-to-train-your-dragon-updated",
        "title": "How to train your dragon (UPDATED)",
      })
    end

    it 'is can\'t update other authors articles' do
      params = JSON('
        {
          "article": {
            "title": "Did you train your dragon? (UPDATED)"
          }
        }
      ')
      response = action.call(params.merge('slug' => 'how-to-train-your-dragon-2', 'HTTP_AUTHORIZATION' => "Token #{JWTHelper.decode(user)}"))
      expect(response[0]).to eq 403
      expect(JSON(response[2][0])).to include("errors" => { "body" => ['Only author can updated article'] })
    end

    it 'is can\'t revrite other article by title' do
      params = JSON('
        {
          "article": {
            "title": "How to train your dragon 2"
          }
        }
      ')
      response = action.call(params.merge('slug' => 'how-to-train-your-dragon', 'HTTP_AUTHORIZATION' => "Token #{JWTHelper.decode(user)}"))
      expect(response[0]).to eq 422
      expect(JSON(response[2][0])).to include("errors" => { "body" => ['Article with new title already exist'] })
    end

    it 'is article not exist' do
      params = JSON('
        {
          "article": {
            "title": "How to train your dragon (UPDATED)"
          }
        }
      ')
      response = action.call(params.merge('slug' => 'not_exist_slug', 'HTTP_AUTHORIZATION' => "Token #{JWTHelper.decode(user)}"))
      expect(response[0]).to eq 404
      expect(JSON(response[2][0])).to include("errors" => { "body" => ['Article not exist'] })
    end

  end
end