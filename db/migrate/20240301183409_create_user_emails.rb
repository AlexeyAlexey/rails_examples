class CreateUserEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :user_emails, id: :uuid do |t|
      t.references :user, type: :uuid, index: true, foreign_key: true

      t.citext :email, null: false

      # OTP
      t.boolean  :validated_otp, default: false
      t.string   :otp_tail,       null: false, default: ''
      t.string   :otp_secret_key, null: false, default: ''

      t.timestamps
    end

    add_index :user_emails, :email, unique: true
  end
end
