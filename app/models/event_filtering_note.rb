class EventFilteringNote < MainNote

  belongs_to :event_filtering, :child_key => [ :discriminator_id ]

end