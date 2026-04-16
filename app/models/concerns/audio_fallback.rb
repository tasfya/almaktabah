module AudioFallback
  extend ActiveSupport::Concern

  # Returns the best available audio attachment
  # Priority: final_audio > audio > nil
  def best_audio
    return final_audio if has_final_audio?
    return audio if has_audio?
    nil
  end

  def has_any_audio?
    has_final_audio? || has_audio?
  end

  def has_final_audio?
    respond_to?(:final_audio) && final_audio.attached?
  end

  def has_audio?
    respond_to?(:audio) && audio.attached?
  end

  def audio_url
    return nil unless has_any_audio?

    attachment_url(best_audio)
  end

  def best_audio_dom_id
    return nil unless has_any_audio?

    if has_final_audio?
      ActionView::RecordIdentifier.dom_id(self, :final_audio)
    elsif has_audio?
      ActionView::RecordIdentifier.dom_id(self, :audio)
    else
      nil
    end
  end
end
