class ReputationNote < MainNote

  belongs_to :reputation, :child_key => [ :discriminator_id ]

end