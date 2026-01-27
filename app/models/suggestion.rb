class Suggestion < ApplicationRecord
  belongs_to :message
  belongs_to :drug
end
