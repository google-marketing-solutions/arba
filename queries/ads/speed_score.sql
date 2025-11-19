--  metrics.speed_score
SELECT
  campaign.id AS campaign_id,
  landing_page_view.unexpanded_final_url AS url,
  metrics.speed_score AS speed_score
FROM landing_page_view
