# Constantes de la API GraphQL interna de X -------------------------------
#
# IDs de operacion, feature flags y variables base de los endpoints GraphQL de
# x.com (https://x.com/i/api/graphql/<opId>/<opName>). X actualiza estos IDs y
# flags cuando redespliega; este es el unico archivo a tocar cuando eso pase.
# Base: el cliente twscrape (https://github.com/vladkens/twscrape).

#' IDs de operacion GraphQL (opId/opName)
#' @noRd
.gql_ops <- list(
  UserByScreenName = list(id = "IGgvgiOx4QZndDHuD3x9TQ", name = "UserByScreenName"),
  UserTweets       = list(id = "54_zVtVXJlQtnIBrY2QSXQ", name = "UserTweets")
)

#' Feature flags para timelines de tweets (UserTweets, SearchTimeline, etc.)
#' @noRd
.gql_features <- list(
  `articles_preview_enabled` = FALSE,
  `c9s_tweet_anatomy_moderator_badge_enabled` = TRUE,
  `communities_web_enable_tweet_community_results_fetch` = TRUE,
  `creator_subscriptions_quote_tweet_preview_enabled` = FALSE,
  `creator_subscriptions_tweet_preview_api_enabled` = TRUE,
  `freedom_of_speech_not_reach_fetch_enabled` = TRUE,
  `graphql_is_translatable_rweb_tweet_is_translatable_enabled` = TRUE,
  `longform_notetweets_consumption_enabled` = TRUE,
  `longform_notetweets_inline_media_enabled` = TRUE,
  `longform_notetweets_rich_text_read_enabled` = TRUE,
  `responsive_web_edit_tweet_api_enabled` = TRUE,
  `responsive_web_enhance_cards_enabled` = FALSE,
  `responsive_web_graphql_exclude_directive_enabled` = TRUE,
  `responsive_web_graphql_skip_user_profile_image_extensions_enabled` = FALSE,
  `responsive_web_grok_community_note_auto_translation_is_enabled` = FALSE,
  `responsive_web_graphql_timeline_navigation_enabled` = TRUE,
  `responsive_web_grok_imagine_annotation_enabled` = FALSE,
  `responsive_web_media_download_video_enabled` = FALSE,
  `responsive_web_profile_redirect_enabled` = TRUE,
  `responsive_web_twitter_article_tweet_consumption_enabled` = TRUE,
  `rweb_tipjar_consumption_enabled` = TRUE,
  `rweb_video_timestamps_enabled` = TRUE,
  `standardized_nudges_misinfo` = TRUE,
  `tweet_awards_web_tipping_enabled` = FALSE,
  `tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled` = TRUE,
  `tweet_with_visibility_results_prefer_gql_media_interstitial_enabled` = FALSE,
  `tweetypie_unmention_optimization_enabled` = TRUE,
  `verified_phone_label_enabled` = FALSE,
  `view_counts_everywhere_api_enabled` = TRUE,
  `responsive_web_grok_analyze_button_fetch_trends_enabled` = FALSE,
  `premium_content_api_read_enabled` = FALSE,
  `profile_label_improvements_pcf_label_in_post_enabled` = FALSE,
  `responsive_web_grok_share_attachment_enabled` = FALSE,
  `responsive_web_grok_analyze_post_followups_enabled` = FALSE,
  `responsive_web_grok_image_annotation_enabled` = FALSE,
  `responsive_web_grok_analysis_button_from_backend` = FALSE,
  `responsive_web_jetfuel_frame` = FALSE,
  `rweb_video_screen_enabled` = TRUE,
  `responsive_web_grok_show_grok_translated_post` = TRUE
)

#' Feature flags para UserByScreenName (set reducido distinto)
#' @noRd
.gql_features_user <- list(
  `highlights_tweets_tab_ui_enabled` = TRUE,
  `hidden_profile_likes_enabled` = TRUE,
  `creator_subscriptions_tweet_preview_api_enabled` = TRUE,
  `hidden_profile_subscriptions_enabled` = TRUE,
  `subscriptions_verification_info_verified_since_enabled` = TRUE,
  `subscriptions_verification_info_is_identity_verified_enabled` = FALSE,
  `responsive_web_twitter_article_notes_tab_enabled` = FALSE,
  `subscriptions_feature_can_gift_premium` = FALSE,
  `profile_label_improvements_pcf_label_in_post_enabled` = FALSE
)
