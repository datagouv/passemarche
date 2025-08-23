module Completable
  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.zone.now)
  end
end
