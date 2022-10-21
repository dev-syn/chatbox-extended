# Changelog

## [Unreleased]

## [0.3.0]
### Added
- Moonwave documentation
- ChatboxExtendedC which is the client version of ChatboxExtended
- ChatCore used by the ChatboxExtended on the server & client
- ChatChannelC to represent the client class of ChatChannel
- ChatChannelC.Messages used to store the message in the ChatChannel
- ChatCore.FindChannel to replace ChatboxExtended.GetChannel
- ChatboxExtendedC.YieldTillChannel used to yield till a ChatChannel exists or it timed out
- ChatConfig.MAX_MESSAGES_SERVER used to limit the cached messages on the server
- Fix RealmCommand.__index missing from RealmCommand
### Changed
- Moved server & client individual type modules into one type module
- Increased default ChatConfig.MAX_MESSAGES to 45
- ChatStyling converted to TextStyling
- RealmCommand Types module require remove extra .Parent
- @module type linker to ChatboxExtended/lib/Types
### Removed
- ChatboxExtendedC.Messages replaced with ChatChannelC.Messages
- ChatboxExtended.GetChannel superseded by ChatCore.FindChannel

## [0.2.0]
### Added
- Export ChatboxExtended types to init.lua for wally-package-types
### Changed
### Removed

## [0.1.0]
### Added
- All starting files
### Changed
### Removed