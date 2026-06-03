# 08 · Age Rating

App Store Connect → App Information → Age Rating. Apple computes the rating from your answers; for a sensor utility the right outcome is **4+** (the lowest, "no objectionable content"). Below is every question with the recommended answer and reasoning.

If any answer is wrong, you'll either get a higher rating than necessary (worse for discovery) or a rejection for incorrect rating.

## Apple Connect Age Rating questionnaire

Answer "**None**" unless otherwise noted.

| Category                                         | Answer | Why                                                       |
|--------------------------------------------------|--------|-----------------------------------------------------------|
| Cartoon or Fantasy Violence                      | None   | No violence content.                                       |
| Realistic Violence                               | None   | No violence content.                                       |
| Sexual Content or Nudity                         | None   |                                                            |
| Profanity or Crude Humor                         | None   |                                                            |
| Alcohol, Tobacco, or Drug Use or References     | None   |                                                            |
| Mature/Suggestive Themes                         | None   |                                                            |
| Horror/Fear Themes                               | None   |                                                            |
| Prolonged Graphic or Sadistic Realistic Violence | None   |                                                            |
| Graphic Sexual Content and Nudity                | None   |                                                            |
| Medical/Treatment Information                    | None   | The Health tab displays HealthKit data; it is not medical advice and the description does not claim diagnosis or treatment. |
| Gambling                                         | None   |                                                            |
| Contests                                         | None   |                                                            |
| Unrestricted Web Access                          | No     | The app has no web view. Only one outbound HTTP request to a fixed domain (1.1.1.1), user-initiated. |
| Made for Kids?                                    | No     | Not directed at children. The app uses general-purpose iOS APIs.|

## "Made for Kids" — answer NO

This is critical. The "Made for Kids" program has additional restrictions (no third-party SDKs unless approved, no internet links to external content, no sign-in via third parties). All Sensors is a general-audience utility — answer **No**.

## Gambling, contests, content concerns

Apple now also asks supplementary questions about lotteries, contests, sweepstakes, and user-generated content. All answers: **No / None**.

## Final computed rating

With the answers above, Apple will display **4+** ("Suitable for all ages") on the App Store.

## If your rating comes out higher than 4+

That means a question got answered "Infrequent/Mild" or higher somewhere. Re-open the questionnaire and double-check each row. The most common mistake is checking "Medical/Treatment Information" — leave that None. The Health tab displays your data; it does not provide medical advice.
