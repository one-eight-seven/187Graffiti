-- 187Graffiti — Database schema
-- Import this file once before starting the resource

CREATE TABLE IF NOT EXISTS `187graffiti_walls` (
    `id`            INT           NOT NULL,
    `owner_gang`    VARCHAR(50)   DEFAULT NULL,
    `tag_style`     VARCHAR(50)   DEFAULT NULL,
    `contest_gang`  VARCHAR(50)   DEFAULT NULL,
    `contest_count` INT           NOT NULL DEFAULT 0,
    `last_tagged`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `187graffiti_stats` (
    `identifier`  VARCHAR(60)  NOT NULL,
    `gang`        VARCHAR(50)  DEFAULT NULL,
    `walls_tagged` INT         NOT NULL DEFAULT 0,
    `walls_lost`   INT         NOT NULL DEFAULT 0,
    `total_sprays` INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
