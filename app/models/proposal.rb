class Proposal < ActiveRecord::Base
  belongs_to :proposer, :class_name => 'User'
  has_many :suggestions

  validates :title, :presence => true

  scope :without_suggestions_from, lambda { |user|
    if user.suggestions.any?
      where('id NOT IN (?)', user.suggestions.map{ |s| s.proposal_id }.uniq)
    end
  }

  scope :not_proposed_by, lambda { |user|
    where('proposer_id != ?', user.id)
  }

  scope :active, where(withdrawn: false)
  scope :withdrawn, where(withdrawn: true)

  def self.available_for_selection_by(user)
    active.reject { |p| Selection.where(proposal_id: p.id, user_id: user.id).exists? }
  end

  after_create :update_proposer_score

  def last_modified
    new_suggestions.any? ? new_suggestions.maximum(:updated_at) : last_modified_by_proposer
  end

  def proposed_by?(user)
    proposer == user
  end

  def new_suggestions
    suggestions.after(last_modified_by_proposer)
  end

  def withdraw!
    update_attribute(:withdrawn, true)
  end

  private

  def last_modified_by_proposer
    [suggestions.by(proposer).maximum(:updated_at), updated_at].compact.max
  end

  def update_proposer_score
    proposer.save
  end
end
