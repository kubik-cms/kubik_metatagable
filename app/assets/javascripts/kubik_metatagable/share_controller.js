import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['label', 'status'];

  static values = {
    title: String,
    text: String,
    url: String,
    copyLabel: { type: String, default: 'Copy link to share' },
    copiedLabel: { type: String, default: 'Link copied' }
  };

  async share(event) {
    event.preventDefault();
    await this.copyLink();
  }

  async copyLink() {
    const url = this.urlValue || window.location.href;

    try {
      await navigator.clipboard.writeText(url);
      this.showCopiedFeedback();
    } catch {
      this.showFeedback('Could not copy link');
    }
  }

  showCopiedFeedback() {
    if (this.hasLabelTarget) {
      const original = this.copyLabelValue || this.labelTarget.textContent;
      this.labelTarget.textContent = this.copiedLabelValue;
      window.clearTimeout(this.labelTimeout);
      this.labelTimeout = window.setTimeout(() => {
        this.labelTarget.textContent = original;
      }, 3000);
      return;
    }

    this.showFeedback(this.copiedLabelValue);
  }

  showFeedback(message) {
    if (!this.hasStatusTarget) {
      return;
    }

    this.statusTarget.textContent = message;
    window.clearTimeout(this.statusTimeout);
    this.statusTimeout = window.setTimeout(() => {
      this.statusTarget.textContent = '';
    }, 3000);
  }
}
