// Audio Player Helper Functions
// These functions provide a simple interface to the global audio player

window.AudioPlayer = {
  // Main play function
  play(audioUrl, title = 'Unknown Title', author = 'Unknown Author', artwork = '') {
    if (!audioUrl) {
      console.warn('No audio URL provided');
      return;
    }
    
    // Use the App.audioPlayer if available
    if (window.App && window.App.audioPlayer) {
      window.App.audioPlayer.play(audioUrl, title, author, artwork);
    } else {
      console.warn('Global audio player not available');
    }
  },
  
  // Pause current audio
  pause() {
    if (window.App && window.App.audioPlayer) {
      window.App.audioPlayer.pause();
    }
  },
  
  // Stop current audio
  stop() {
    if (window.App && window.App.audioPlayer) {
      window.App.audioPlayer.stop();
    }
  },
  
  // Check if audio is currently playing
  isPlaying() {
    const controller = this.getController();
    return controller ? controller.isPlaying : false;
  },
  
  // Get the audio controller instance
  getController() {
    if (window.App && window.App.audioPlayer) {
      return window.App.audioPlayer.getController();
    }
    return null;
  }
};

// Helper function for inline use in HTML
window.playAudio = function(audioUrl, title, author, artwork) {
  window.AudioPlayer.play(audioUrl, title, author, artwork);
};

// Export for module use if needed
if (typeof module !== 'undefined' && module.exports) {
  module.exports = window.AudioPlayer;
}
