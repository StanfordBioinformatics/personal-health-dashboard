## About
This file documents the list of SFTPGO settings that are configured by default.

## Configuration
These are configuration that is provided to SFTPGO as part of startup through
`sftpgo.json`.

1. `idle_timeout`

Time in minutes after which an idle client will be disconnected. This is
configured as 2 minutes.

2. `max_auth_tries`

Maximum number of authentication attempts permitted per connection. This is
configured as 3.

3. `enable_scp`

Whether SCP is to be enabled or not. This is disabled.

4. `enabled_ssh_commands`

List of enabled SSH commands. The only allowed commands are `md5sum`,
`sha1sum`, `cd` and `pwd`.

## Per connection/user configuration
These are per connection configuration that is provided by default by the
external auth program.

1. `max_sessions`

Limit the sessions that a user can open. This is set to 2.

2. `quota_size` and `quota_files`

Quota as size in bytes or Quota as number of files. This is configured as 0 for
unlimited.

3. `permissions`

For the virtual directory the user is provided in GCS, the permissions is set
as the following - `"list", "upload", "download"`.

4. `denied_login_methods`

The only allowed login method is `public-key`. Rest of the login methods is
disabled.
