SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT=0;
START TRANSACTION;
SET time_zone = "+00:00";
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
DROP DATABASE IF EXISTS `mailserver`;
CREATE DATABASE IF NOT EXISTS `mailserver` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
USE `mailserver`;
DROP TABLE IF EXISTS `virtual_aliases`;
CREATE TABLE IF NOT EXISTS `virtual_aliases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) NOT NULL,
  `source` varchar(100) NOT NULL,
  `destination` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `domain_id` (`domain_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=4 ;
--
-- RELATIONS FOR TABLE `virtual_aliases`:
--   `domain_id`
--       `virtual_domains` -> `id`
--
INSERT INTO `virtual_aliases` (`id`, `domain_id`, `source`, `destination`) VALUES
(1, 1, 'jack@example.org', 'john@example.org'),
(2, 1, 'pippo@topolinia.org', 'paperino@paperopoli.org');

DROP TABLE IF EXISTS `virtual_domains`;
CREATE TABLE IF NOT EXISTS `virtual_domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;
INSERT INTO `virtual_domains` (`id`, `name`) VALUES
(1, 'example.org');

DROP TABLE IF EXISTS `virtual_users`;
CREATE TABLE IF NOT EXISTS `virtual_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) NOT NULL,
  `password` varchar(32) NOT NULL,
  `email` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `domain_id` (`domain_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2 ;
--
-- RELATIONS FOR TABLE `virtual_users`:
--   `domain_id`
--       `virtual_domains` -> `id`
--
INSERT INTO `virtual_users` (`id`, `domain_id`, `password`, `email`) VALUES
(1, 1, '14cbfb845af1f030e372b1cb9275e6dd', 'john@example.org');

ALTER TABLE `virtual_aliases`
  ADD CONSTRAINT `virtual_aliases_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`) ON DELETE CASCADE;
ALTER TABLE `virtual_users`
  ADD CONSTRAINT `virtual_users_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`) ON DELETE CASCADE;
COMMIT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

