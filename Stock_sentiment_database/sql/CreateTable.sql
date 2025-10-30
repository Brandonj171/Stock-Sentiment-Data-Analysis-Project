CREATE TABLE stock_sentiment_analysis (
	ticker VARCHAR(10),
	date DATE,
	open_price DECIMAL(10,4),
	high_price DECIMAL(10,4),
	low_price DECIMAL(10,4),
	close_price DECIMAL(10,4),
	volume BIGINT,
	price_change_pct DECIMAL(10,6),
	sentiment_score DECIMAL(10,6),
	healine_count INTEGER,
	sentiment_label VARCHAR(20)
	);