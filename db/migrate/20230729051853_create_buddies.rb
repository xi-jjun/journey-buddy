class CreateBuddies < ActiveRecord::Migration[7.0]
  def change
    create_table :buddies do |t|
      t.string :name
      t.string :profile_image_url
      t.string :display_name
      t.integer :gender, limit: 1
      t.integer :age
      t.string :display_description
      t.text :description, comment: '역할 설정 스크립트 저장컬럼(Peronality의 모든 description을 저장)'

      t.timestamps
    end
  end
end
