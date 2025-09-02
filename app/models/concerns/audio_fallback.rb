module AudioFallback
  extend ActiveSupport::Concern

  # Returns the best available audio attachment
  # Priority: optimized_audio > audio > nil
  def best_audio
    return optimized_audio if has_optimized_audio?
    return audio if has_audio?
    nil
  end

  def has_any_audio?
    has_optimized_audio? || has_audio?
  end

  def has_optimized_audio?
    respond_to?(:optimized_audio) && optimized_audio.attached?
  end

  def has_audio?
    respond_to?(:audio) && audio.attached?
  end

  def best_audio_dom_id
    return nil unless has_any_audio?

    if has_optimized_audio?
      ActionView::RecordIdentifier.dom_id(self, :optimized_audio)
    elsif has_audio?
      ActionView::RecordIdentifier.dom_id(self, :audio)
    else
      nil
    end
  end
end
