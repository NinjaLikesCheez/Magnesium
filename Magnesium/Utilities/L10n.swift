//
//  L10n.swift.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-13.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

enum L10n {
    // MARK: Actions

    static var ok: String {
        return NSLocalizedString("action_ok", comment: "OK")
    }

    static var add: String {
        return NSLocalizedString("action_add", comment: "Add")
    }

    static var cancel: String {
        return NSLocalizedString("action_cancel", comment: "Cancel")
    }

    static var pause: String {
        return NSLocalizedString("action_pause", comment: "Pause")
    }

    static var resume: String {
        return NSLocalizedString("action_resume", comment: "Resume")
    }

    static var setLabel: String {
        return NSLocalizedString("action_set_label", comment: "Set Label")
    }

    static var verifyFiles: String {
        return NSLocalizedString("action_verify_files", comment: "Verify Files")
    }

    static var updateTrackers: String {
        return NSLocalizedString("action_update_trackers", comment: "Update Trackers")
    }

    static var remove: String {
        return NSLocalizedString("action_remove", comment: "Remove")
    }

    static var save: String {
        return NSLocalizedString("action_save", comment: "Save")
    }

    static var deleteServer: String {
        return NSLocalizedString("action_delete_server", comment: "Delete Server")
    }

    static var delete: String {
        return NSLocalizedString("action_delete", comment: "Delete")
    }

    static var moveDownloadFolder: String {
        return NSLocalizedString("action_move_download_folder", comment: "Move Download Folder")
    }

    // MARK: Screens

    static var torrentInfoScreenTitle: String {
        return NSLocalizedString("torrent_info_screen_title", comment: "Info")
    }

    static var filterScreenTitle: String {
        return NSLocalizedString("filter_screen_title", comment: "Filter")
    }

    static var settingsScreenTitle: String {
        return NSLocalizedString("settings_screen_title", comment: "Settings")
    }

    static var addServerScreenTitle: String {
        return NSLocalizedString("add_server_screen_title", comment: "Add Server")
    }

    static var editServerScreenTitle: String {
        return NSLocalizedString("edit_server_screen_title", comment: "Edit Server")
    }

    static var refreshIntervalScreenTitle: String {
        return NSLocalizedString("refresh_interval_screen_title", comment: "Refresh Interval")
    }

    // MARK: Error

    static var pauseError: String {
        return NSLocalizedString("error_pause", comment: "Failed to Pause")
    }

    static var resumeError: String {
        return NSLocalizedString("error_resume", comment: "Failed to Resume")
    }

    static var removeError: String {
        return NSLocalizedString("error_remove", comment: "Failed to Remove")
    }

    static var verifyFilesError: String {
        return NSLocalizedString("error_verify_files", comment: "Failed to Verify Files")
    }

    static var setLabelError: String {
        return NSLocalizedString("error_set_label", comment: "Failed to Set Label")
    }

    static var updateTrackersError: String {
        return NSLocalizedString("error_update_trackers", comment: "Failed to Update Trackers")
    }

    static var refreshError: String {
        return NSLocalizedString("error_refresh", comment: "Update Failed")
    }

    static var torrentLinkValidationError: String {
        return NSLocalizedString("error_torrent_link_validation", comment: "Unable to Add Link")
    }

    static var torrentLinkValidationErrorDescription: String {
        return NSLocalizedString(
            "error_torrent_link_validation_description",
            comment: "That link doesn't appear to be valid."
        )
    }

    static var addTorrentError: String {
        return NSLocalizedString("error_add_torrent", comment: "Failed to Add Torrent")
    }

    static var addServerError: String {
        return NSLocalizedString("error_add_server", comment: "Unable to Add Server")
    }

    static var saveServerError: String {
        return NSLocalizedString("error_save_server", comment: "Unable to Save Server")
    }

    static var authenticationError: String {
        return NSLocalizedString("error_authentication", comment: "Authentication Failed")
    }

    static var serverURLValidationErrorDescription: String {
        return NSLocalizedString(
            "error_server_url_validation_description",
            comment: "The server URL is invalid. Ensure the URL begins with \"http://\" or \"https://\"."
        )
    }

    static var unauthenticatedErrorDescription: String {
        return NSLocalizedString(
            "error_unauthenticated_description",
            comment: "Unable to authenticate. Verify that your credentials are correct."
        )
    }

    static var unexpectedResponseErrorDescription: String {
        return NSLocalizedString(
            "error_unexpected_response_description",
            comment: "The server returned an unexpected response."
        )
    }

    static var serverErrorDescription: String {
        return NSLocalizedString("error_server_description", comment: "The server returned an error.")
    }

    static func serverMessageErrorDescription(_ message: String) -> String {
        let format = NSLocalizedString(
            "error_server_message_description",
            comment: "The server returned an error: {serverMessage}."
        )
        return .localizedStringWithFormat(format, message)
    }

    static var noSessionIDErrorDescription: String {
        return NSLocalizedString("error_no_session_id", comment: "Unable to retrieve Session ID.")
    }

    static func unexpectedStatusCodeErrorDescription(_ statusCode: Int) -> String {
        let format = NSLocalizedString(
            "error_unexpected_status_code_description",
            comment: "The server returned an unexpected status code ({statusCode})."
        )
        return .localizedStringWithFormat(format, statusCode)
    }

    static var moveDownloadFolderError: String {
        return NSLocalizedString("error_move_download_folder", comment: "Failed to Move Download Folder")
    }

    // MARK: Servers

    static var deluge: String {
        return NSLocalizedString("server_deluge", comment: "Deluge")
    }

    static var transmission: String {
        return NSLocalizedString("server_transmission", comment: "Transmission")
    }

    // MARK: Sort Properties

    static var sortPropertyDateAdded: String {
        NSLocalizedString("sort_property_date_added", comment: "Date Added")
    }

    static var sortPropertyName: String {
        return NSLocalizedString("sort_property_name", comment: "Name")
    }

    static var sortPropertyDownloadSpeed: String {
        return NSLocalizedString("sort_property_download_speed", comment: "Download Speed")
    }

    static var sortPropertyUploadSpeed: String {
        return NSLocalizedString("sort_property_upload_speed", comment: "Upload Speed")
    }

    // MARK: Add Torrent

    static var addTorrentAlertTitle: String {
        return NSLocalizedString("add_torrent_alert_title", comment: "Add Torrent")
    }

    static func addTorrentToServerConfirmation(fileName: String, serverName: String) -> String {
        let format = NSLocalizedString(
            "add_torrent_file_to_server_confirmation",
            comment: "Add {fileName} to {serverName}?"
        )
        return .localizedStringWithFormat(format, fileName, serverName)
    }

    static var addTorrentAlertPrompt: String {
        return NSLocalizedString("add_torrent_alert_prompt", comment: "How would you like to add the torrent?")
    }

    static var addTorrentMethodLink: String {
        return NSLocalizedString("add_torrent_method_link", comment: "Add Link")
    }

    static var addTorrentMethodFile: String {
        return NSLocalizedString("add_torrent_method_file", comment: "Add File")
    }

    static var addTorrentLinkAlertTitle: String {
        return NSLocalizedString("add_torrent_link_alert_title", comment: "Enter a URL")
    }

    static var addTorrentLinkAlertMessage: String {
        return NSLocalizedString(
            "add_torrent_link_alert_message",
            comment: "This can be either a link to a torrent or a magnet link."
        )
    }

    // MARK: Torrent Propreties

    static func torrentDownloadSpeed(_ downloadSpeed: String) -> String {
        let format = NSLocalizedString("torrent_download_speed", comment: "↓ {bytes}/s")
        return .localizedStringWithFormat(format, downloadSpeed)
    }

    static func torrentUploadSpeed(_ uploadSpeed: String) -> String {
        let format = NSLocalizedString("torrent_upload_speed", comment: "↑ {bytes}/s")
        return .localizedStringWithFormat(format, uploadSpeed)
    }

    static func torrentProgress(downloaded: String, size: String, progress: String) -> String {
        let format = NSLocalizedString("torrent_progress", comment: "{downloaded} / {uploaded} ({percentage})")
        return .localizedStringWithFormat(format, downloaded, size, progress)
    }

    static func torrentRatio(_ ratio: String) -> String {
        let format = NSLocalizedString("torrent_ratio", comment: "Ratio: {number}")
        return .localizedStringWithFormat(format, ratio)
    }

    static func torrentStatusAndProgress(status: String, progress: String) -> String {
        let format = NSLocalizedString("torrent_status_and_progress", comment: "{status} ({percentage})")
        return .localizedStringWithFormat(format, status, progress)
    }

    static func torrentPeers(peers: Int, totalPeers: Int) -> String {
        let format = NSLocalizedString("torrent_peers", comment: "{connectedPeers} ({totalPeers})")
        return .localizedStringWithFormat(format, peers, totalPeers)
    }

    // MARK: Torrent State

    static var downloadingState: String {
        return NSLocalizedString("torrent_state_downloading", comment: "Downloading")
    }

    static var seedingState: String {
        return NSLocalizedString("torrent_state_seeding", comment: "Seeding")
    }

    static var pausedState: String {
        return NSLocalizedString("torrent_state_paused", comment: "Paused")
    }

    static var queuedState: String {
        return NSLocalizedString("torrent_state_queued", comment: "Queued")
    }

    static var checkingState: String {
        return NSLocalizedString("torrent_state_checking", comment: "Checking")
    }

    static var errorState: String {
        return NSLocalizedString("torrent_state_error", comment: "Error")
    }

    // MARK: Remove Torrent

    static var removeTorrentOptionKeepData: String {
        return NSLocalizedString("remove_torrent_option_keep_data", comment: "Keep Data")
    }

    static var removeTorrentOptionRemoveData: String {
        return NSLocalizedString("remove_torrent_option_remove_data", comment: "Remove Data")
    }

    // MARK: Torrent List

    static func selectedCount(_ count: Int) -> String {
        let format = NSLocalizedString("selected_count", comment: "{number} Selected")
        return .localizedStringWithFormat(format, count)
    }

    static func torrentCount(_ count: Int) -> String {
        let format = NSLocalizedString("torrent_count", comment: "{number} Torrents")
        return .localizedStringWithFormat(format, count)
    }

    // MARK: Torrent Info

    static var torrentInfoSectionInfo: String {
        return NSLocalizedString("torrent_info_section_info", comment: "Information")
    }

    static var torrentInfoSectionTrackers: String {
        return NSLocalizedString("torrent_info_section_trackers", comment: "Trackers")
    }

    static var torrentInfoSectionFiles: String {
        return NSLocalizedString("torrent_info_section_files", comment: "Files")
    }

    static var torrentInfoSize: String {
        return NSLocalizedString("torrent_info_size", comment: "Size")
    }

    static var torrentInfoDownloadSpeed: String {
        return NSLocalizedString("torrent_info_download_speed", comment: "Download Speed")
    }

    static var torrentInfoUploadSpeed: String {
        return NSLocalizedString("torrent_info_upload_speed", comment: "Upload Speed")
    }

    static var torrentInfoDownloaded: String {
        return NSLocalizedString("torrent_info_downloaded", comment: "Downloaded")
    }

    static var torrentInfoUploaded: String {
        return NSLocalizedString("torrent_info_uploaded", comment: "Uploaded")
    }

    static var torrentInfoETA: String {
        return NSLocalizedString("torrent_info_eta", comment: "ETA")
    }

    static var torrentInfoRatio: String {
        return NSLocalizedString("torrent_info_ratio", comment: "Ratio")
    }

    static var torrentInfoPeers: String {
        return NSLocalizedString("torrent_info_peers", comment: "Peers")
    }

    static var torrentInfoSeed: String {
        return NSLocalizedString("torrent_info_seeds", comment: "Seeds")
    }

    static var torrentInfoDownloadFolder: String {
        return NSLocalizedString("torrent_info_download_folder", comment: "Download Folder")
    }

    // MARK: Label

    static var noneLabel: String {
        return NSLocalizedString("label_none", comment: "None")
    }

    // MARK: Filter

    static var allFilter: String {
        return NSLocalizedString("filter_all", comment: "All")
    }

    static var filterOptionSort: String {
        return NSLocalizedString("filter_option_sort", comment: "Sort")
    }

    static var filterOptionState: String {
        return NSLocalizedString("filter_option_state", comment: "State")
    }

    static var filterOptionLabel: String {
        return NSLocalizedString("filter_option_label", comment: "Label")
    }

    static var sortByAlertTitle: String {
        return NSLocalizedString("sort_by_alert_title", comment: "Sort by")
    }

    static var sortByAlertMessage: String {
        return NSLocalizedString(
            "sort_by_alert_message",
            comment: "Select the current sort option to sort in the opposite direction."
        )
    }

    static var filterLabelAlertTitle: String {
        return NSLocalizedString("filter_label_alert_title", comment: "Filter by Label")
    }

    static var filterLabelAlertMessage: String {
        return NSLocalizedString(
            "filter_label_alert_message",
            comment: "Only display torrents with the selected label."
        )
    }

    static var filterStateAlertTitle: String {
        return NSLocalizedString("filter_state_alert_title", comment: "Filter by State")
    }

    static var filterStateAlertMessage: String {
        return NSLocalizedString(
            "filter_state_alert_message",
            comment: "Only display torrents with the selected state."
        )
    }

    // MARK: Settings

    static var settingsSectionServers: String {
        return NSLocalizedString("settings_section_servers", comment: "Servers")
    }

    static var settingsSectionGeneral: String {
        return NSLocalizedString("settings_section_general", comment: "General")
    }

    static var settingsOptionCurrentServer: String {
        return NSLocalizedString("settings_option_current_server", comment: "Current Server")
    }

    static var settingsOptionAddServer: String {
        return NSLocalizedString("settings_option_add_server", comment: "Add Server")
    }

    static var settingsOptionRefreshInterval: String {
        return NSLocalizedString("settings_option_refresh_interval", comment: "Refresh Interval")
    }

    // MARK: Refresh Interval

    static var refreshIntervalNever: String {
        return NSLocalizedString("refresh_interval_never", comment: "Never")
    }

    static func refreshIntervalSeconds(_ seconds: Int) -> String {
        let format = NSLocalizedString("refresh_interval_seconds", comment: "{number} seconds")
        return .localizedStringWithFormat(format, seconds)
    }

    // MARK: Server Settings

    static var serverSettingsOptionName: String {
        return NSLocalizedString("server_settings_option_name", comment: "name")
    }

    static var serverSettingsOptionServer: String {
        return NSLocalizedString("server_settings_option_server", comment: "server")
    }

    static var serverSettingsOptionPassword: String {
        return NSLocalizedString("server_settings_option_password", comment: "password")
    }

    static var serverSettingsOptionPasswordHint: String {
        return NSLocalizedString("server_settings_option_password_hint", comment: "password")
    }

    static var serverSettingsOptionPasswordHintOptional: String {
        return NSLocalizedString(
            "server_settings_option_password_hint_optional",
            comment: "password (optional)"
        )
    }

    static var serverSettingsOptionUsername: String {
        return NSLocalizedString("server_settings_option_username", comment: "username")
    }

    static var serverSettingsOptionUsernameHintOptional: String {
        return NSLocalizedString("server_settings_option_username_hint_optional", comment: "user (optional)")
    }

    // MARK: Delete Server

    static var deleteServerConfirmation: String {
        return NSLocalizedString(
            "delete_server_confirmation",
            comment: "Are you sure you want to delete this server?"
        )
    }
}
