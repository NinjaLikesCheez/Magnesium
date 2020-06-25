import Foundation

enum L10n {
    // MARK: Screens

    static var torrentInfoScreenTitle: String {
        NSLocalizedString("torrent_info_screen_title", comment: "Info")
    }

    static var filterScreenTitle: String {
        NSLocalizedString("filter_screen_title", comment: "Filter")
    }

    static var settingsScreenTitle: String {
        NSLocalizedString("settings_screen_title", comment: "Settings")
    }

    static var addServerScreenTitle: String {
        NSLocalizedString("add_server_screen_title", comment: "Add Server")
    }

    static var editServerScreenTitle: String {
        NSLocalizedString("edit_server_screen_title", comment: "Edit Server")
    }

    static var refreshIntervalScreenTitle: String {
        NSLocalizedString("refresh_interval_screen_title", comment: "Refresh Interval")
    }

    // MARK: Error

    static var pauseError: String {
        NSLocalizedString("error_pause", comment: "Failed to Pause")
    }

    static var resumeError: String {
        NSLocalizedString("error_resume", comment: "Failed to Resume")
    }

    static var removeError: String {
        NSLocalizedString("error_remove", comment: "Failed to Remove")
    }

    static var verifyFilesError: String {
        NSLocalizedString("error_verify_files", comment: "Failed to Verify Files")
    }

    static var setLabelError: String {
        NSLocalizedString("error_set_label", comment: "Failed to Set Label")
    }

    static var updateTrackersError: String {
        NSLocalizedString("error_update_trackers", comment: "Failed to Update Trackers")
    }

    static var refreshError: String {
        NSLocalizedString("error_refresh", comment: "Update Failed")
    }

    static var torrentLinkValidationError: String {
        NSLocalizedString("error_torrent_link_validation", comment: "Unable to Add Link")
    }

    static var torrentLinkValidationErrorDescription: String {
        NSLocalizedString(
            "error_torrent_link_validation_description",
            comment: "That link doesn't appear to be valid."
        )
    }

    static var addTorrentError: String {
        NSLocalizedString("error_add_torrent", comment: "Failed to Add Torrent")
    }

    static var addServerError: String {
        NSLocalizedString("error_add_server", comment: "Unable to Add Server")
    }

    static var saveServerError: String {
        NSLocalizedString("error_save_server", comment: "Unable to Save Server")
    }

    static var authenticationError: String {
        NSLocalizedString("error_authentication", comment: "Authentication Failed")
    }

    static var serverURLValidationErrorDescription: String {
        NSLocalizedString(
            "error_server_url_validation_description",
            comment: "The server URL is invalid. Ensure the URL begins with \"http://\" or \"https://\"."
        )
    }

    static var unauthenticatedErrorDescription: String {
        NSLocalizedString(
            "error_unauthenticated_description",
            comment: "Unable to authenticate. Verify that your credentials are correct."
        )
    }

    static var unexpectedResponseErrorDescription: String {
        NSLocalizedString(
            "error_unexpected_response_description",
            comment: "The server returned an unexpected response."
        )
    }

    static var serverErrorDescription: String {
        NSLocalizedString("error_server_description", comment: "The server returned an error.")
    }

    static func serverMessageErrorDescription(_ message: String) -> String {
        let format = NSLocalizedString(
            "error_server_message_description",
            comment: "The server returned an error: {serverMessage}."
        )
        return .localizedStringWithFormat(format, message)
    }

    static var noSessionIDErrorDescription: String {
        NSLocalizedString("error_no_session_id", comment: "Unable to retrieve Session ID.")
    }

    static func unexpectedStatusCodeErrorDescription(_ statusCode: Int) -> String {
        let format = NSLocalizedString(
            "error_unexpected_status_code_description",
            comment: "The server returned an unexpected status code ({statusCode})."
        )
        return .localizedStringWithFormat(format, statusCode)
    }

    static var moveDownloadFolderError: String {
        NSLocalizedString("error_move_download_folder", comment: "Failed to Move Download Folder")
    }

    static var setPriorityError: String {
        NSLocalizedString("error_set_priority", comment: "Failed to Set Priority")
    }

    static var deleteServerError: String {
        NSLocalizedString("error_delete_server", comment: "Failed to Delete Server")
    }

    // MARK: Servers

    static var deluge: String {
        NSLocalizedString("server_deluge", comment: "Deluge")
    }

    static var transmission: String {
        NSLocalizedString("server_transmission", comment: "Transmission")
    }

    // MARK: Sort Properties

    static var sortPropertyDateAdded: String {
        NSLocalizedString("sort_property_date_added", comment: "Date Added")
    }

    static var sortPropertyName: String {
        NSLocalizedString("sort_property_name", comment: "Name")
    }

    static var sortPropertyDownloadSpeed: String {
        NSLocalizedString("sort_property_download_speed", comment: "Download Speed")
    }

    static var sortPropertyUploadSpeed: String {
        NSLocalizedString("sort_property_upload_speed", comment: "Upload Speed")
    }

    // MARK: Add Torrent

    static func addTorrentToServerPrompt(serverName: String) -> String {
        let format = NSLocalizedString("add_torrent_to_server_prompt", comment: "Add to {serverName}")
        return .localizedStringWithFormat(format, serverName)
    }

    static var addTorrentMethodPrompt: String {
        NSLocalizedString("add_torrent_method_prompt", comment: "How would you like to add the torrent?")
    }

    static var addTorrentMethodLink: String {
        NSLocalizedString("add_torrent_method_link", comment: "Add Link")
    }

    static var addTorrentMethodFile: String {
        NSLocalizedString("add_torrent_method_file", comment: "Add File")
    }

    static var addTorrentLinkAlertTitle: String {
        NSLocalizedString("add_torrent_link_alert_title", comment: "Enter a URL")
    }

    static var addTorrentLinkAlertMessage: String {
        NSLocalizedString(
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
        let format = NSLocalizedString("torrent_progress", comment: "{downloaded} / {size} ({percentage})")
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
        NSLocalizedString("torrent_state_downloading", comment: "Downloading")
    }

    static var seedingState: String {
        NSLocalizedString("torrent_state_seeding", comment: "Seeding")
    }

    static var pausedState: String {
        NSLocalizedString("torrent_state_paused", comment: "Paused")
    }

    static var queuedState: String {
        NSLocalizedString("torrent_state_queued", comment: "Queued")
    }

    static var checkingState: String {
        NSLocalizedString("torrent_state_checking", comment: "Checking")
    }

    static var errorState: String {
        NSLocalizedString("torrent_state_error", comment: "Error")
    }

    // MARK: Remove Torrent

    static var removeTorrentOptionKeepData: String {
        NSLocalizedString("remove_torrent_option_keep_data", comment: "Keep Data")
    }

    static var removeTorrentOptionRemoveData: String {
        NSLocalizedString("remove_torrent_option_remove_data", comment: "Remove Data")
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
        NSLocalizedString("torrent_info_section_info", comment: "Information")
    }

    static var torrentInfoSectionTrackers: String {
        NSLocalizedString("torrent_info_section_trackers", comment: "Trackers")
    }

    static var torrentInfoSectionFiles: String {
        NSLocalizedString("torrent_info_section_files", comment: "Files")
    }

    static var torrentInfoSize: String {
        NSLocalizedString("torrent_info_size", comment: "Size")
    }

    static var torrentInfoDownloadSpeed: String {
        NSLocalizedString("torrent_info_download_speed", comment: "Download Speed")
    }

    static var torrentInfoUploadSpeed: String {
        NSLocalizedString("torrent_info_upload_speed", comment: "Upload Speed")
    }

    static var torrentInfoDownloaded: String {
        NSLocalizedString("torrent_info_downloaded", comment: "Downloaded")
    }

    static var torrentInfoUploaded: String {
        NSLocalizedString("torrent_info_uploaded", comment: "Uploaded")
    }

    static var torrentInfoETA: String {
        NSLocalizedString("torrent_info_eta", comment: "ETA")
    }

    static var torrentInfoRatio: String {
        NSLocalizedString("torrent_info_ratio", comment: "Ratio")
    }

    static var torrentInfoPeers: String {
        NSLocalizedString("torrent_info_peers", comment: "Peers")
    }

    static var torrentInfoSeed: String {
        NSLocalizedString("torrent_info_seeds", comment: "Seeds")
    }

    static var torrentInfoDownloadFolder: String {
        NSLocalizedString("torrent_info_download_folder", comment: "Download Folder")
    }

    static func fileCount(_ count: Int) -> String {
        let format = NSLocalizedString("file_count", comment: "{number} Files")
        return .localizedStringWithFormat(format, count)
    }

    static func fileProgress(size: String, progress: String) -> String {
        let format = NSLocalizedString("file_progress", comment: "{size} ({percentage})")
        return .localizedStringWithFormat(format, size, progress)
    }

    // MARK: Priority

    static var disabledPriority: String {
        NSLocalizedString("priority_disabled", comment: "Disabled")
    }

    static var lowPriority: String {
        NSLocalizedString("priority_low", comment: "Low Priority")
    }

    static var normalPriority: String {
        NSLocalizedString("priority_normal", comment: "Normal Priority")
    }

    static var highPriority: String {
        NSLocalizedString("priority_high", comment: "High Priority")
    }

    // MARK: Label

    static var noneLabel: String {
        NSLocalizedString("label_none", comment: "None")
    }

    // MARK: Filter

    static var allFilter: String {
        NSLocalizedString("filter_all", comment: "All")
    }

    static var filterOptionSort: String {
        NSLocalizedString("filter_option_sort", comment: "Sort")
    }

    static var filterOptionState: String {
        NSLocalizedString("filter_option_state", comment: "State")
    }

    static var filterOptionLabel: String {
        NSLocalizedString("filter_option_label", comment: "Label")
    }

    static var sortByAlertTitle: String {
        NSLocalizedString("sort_by_alert_title", comment: "Sort by")
    }

    static var sortByAlertMessage: String {
        NSLocalizedString(
            "sort_by_alert_message",
            comment: "Select the current sort option to sort in the opposite direction."
        )
    }

    static var filterLabelAlertTitle: String {
        NSLocalizedString("filter_label_alert_title", comment: "Filter by Label")
    }

    static var filterLabelAlertMessage: String {
        NSLocalizedString(
            "filter_label_alert_message",
            comment: "Only display torrents with the selected label."
        )
    }

    static var filterStateAlertTitle: String {
        NSLocalizedString("filter_state_alert_title", comment: "Filter by State")
    }

    static var filterStateAlertMessage: String {
        NSLocalizedString(
            "filter_state_alert_message",
            comment: "Only display torrents with the selected state."
        )
    }

    // MARK: Settings

    static var settingsSectionServers: String {
        NSLocalizedString("settings_section_servers", comment: "Servers")
    }

    static var settingsSectionGeneral: String {
        NSLocalizedString("settings_section_general", comment: "General")
    }

    static var settingsOptionCurrentServer: String {
        NSLocalizedString("settings_option_current_server", comment: "Current Server")
    }

    static var settingsOptionAddServer: String {
        NSLocalizedString("settings_option_add_server", comment: "Add Server")
    }

    static var settingsOptionRefreshInterval: String {
        NSLocalizedString("settings_option_refresh_interval", comment: "Refresh Interval")
    }

    // MARK: Refresh Interval

    static var refreshIntervalNever: String {
        NSLocalizedString("refresh_interval_never", comment: "Never")
    }

    static func refreshIntervalSeconds(_ seconds: Int) -> String {
        let format = NSLocalizedString("refresh_interval_seconds", comment: "{number} seconds")
        return .localizedStringWithFormat(format, seconds)
    }

    // MARK: Server Settings

    static var serverSettingsOptionName: String {
        NSLocalizedString("server_settings_option_name", comment: "name")
    }

    static var serverSettingsOptionServer: String {
        NSLocalizedString("server_settings_option_server", comment: "server")
    }

    static var serverSettingsOptionPassword: String {
        NSLocalizedString("server_settings_option_password", comment: "password")
    }

    static var serverSettingsOptionPasswordHint: String {
        NSLocalizedString("server_settings_option_password_hint", comment: "password")
    }

    static var serverSettingsOptionPasswordHintOptional: String {
        NSLocalizedString(
            "server_settings_option_password_hint_optional",
            comment: "password (optional)"
        )
    }

    static var serverSettingsOptionUsername: String {
        NSLocalizedString("server_settings_option_username", comment: "username")
    }

    static var serverSettingsOptionUsernameHintOptional: String {
        NSLocalizedString("server_settings_option_username_hint_optional", comment: "user (optional)")
    }

    // MARK: Delete Server

    static var deleteServerConfirmation: String {
        NSLocalizedString(
            "delete_server_confirmation",
            comment: "Are you sure you want to delete this server?"
        )
    }

    // MARK: No Servers

    static var noServersTitle: String {
        NSLocalizedString("no_servers_title", comment: "No Servers")
    }

    static var noServersBody: String {
        NSLocalizedString(
            "no_servers_body",
            comment: "You'll need to add a server before you can start using Magnesium."
        )
    }

    // MARK: Server Error

    static var serverErrorTitle: String {
        NSLocalizedString("server_error_title", comment: "Unable to Load Server")
    }

    static var serverErrorBody: String {
        // swiftformat:disable indent
        NSLocalizedString(
            "server_error_body",
            comment: """
                Sorry, your server settings were unable to be read. Please try re-entering your server information.
                """
        )
        // swiftformat:enable indent
    }

    // MARK: Add Torrent

    static var unableToAddTorrentError: String {
        NSLocalizedString("error_unable_to_add_torrent", comment: "Unable to Add Torrent")
    }

    static var failedToAddTorrentError: String {
        NSLocalizedString("error_failed_to_add_torrent", comment: "Failed to Add Torrent")
    }

    static var corruptServerSettingsErrorDescription: String {
        NSLocalizedString(
            "error_corrupt_server_settings_description",
            comment: "The server settings could not be read."
        )
    }

    static var noServersErrorDescription: String {
        NSLocalizedString("error_no_servers_description", comment: "There are no servers.")
    }
}
