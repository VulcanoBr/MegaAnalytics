class ImportBatch < ApplicationRecord
  has_many :draws, dependent: :restrict_with_error

  enum :status, {
    pending: "pending",
    processing: "processing",
    succeeded: "succeeded",
    failed: "failed"
  }, default: "pending"

  validates :file_name, presence: true
  validates :file_sha256, length: { is: 64 }, allow_nil: true

  # passed | warning | failed | nil (ainda não validado)
  def validation_result
    validation_report["result"]
  end

  def duration_in_seconds
    return unless started_at && finished_at

    (finished_at - started_at).round(2)
  end
end
