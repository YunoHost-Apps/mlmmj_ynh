#!/bin/bash

install_update_mlmmj() {

    mkdir -p "$install_dir/src"
    mkdir -p "$install_dir/app"

    ynh_setup_source  --full_replace --dest_dir="$install_dir/src" || ynh_die "Failed to download mlmmj"

    chown -R $app:$app "$install_dir/src"
    chown -R $app:$app "$install_dir/app"
    pushd "$install_dir/src"
        ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app autoreconf -i
        ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app ./configure  --prefix="$install_dir/app" --disable-tests
        ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app make
        ynh_exec_and_print_stderr_only_if_error ynh_exec_as_app make install
        [ $? -eq 0 ] || ynh_die "Failed to install mlmmj binaries"
    popd

    chgrp postfix $install_dir
}

is_valid_list_email() {
    local email_address="$1"

    local primary_email_user=$(yunohost user list --output-as json | jq -r --arg email "$email_address" '.users | to_entries[] | select(.value.mail == $email) | .key')
    if [[ -n "$primary_email_user" ]]; then
        ynh_print_warn "The email address '$email_address' is already the primary email of user '$primary_email_user'. Please choose a different email address."
        return 1
    fi

    local email_alias_user=$(yunohost user list --fields mail-alias --output-as json | jq -r --arg email "$email_address" '.users | to_entries[] | select(.value["mail-alias"] | index($email)) | .key')
    if [[ -n "$email_alias_user" ]]; then
        ynh_print_warn "The email address '$email_address' is already an alias of user '$email_alias_user'. Please choose a different email address."
        return 1
    fi

    return 0
}

is_domain_managed_by_yunohost() {
    local list_dom=$1

    if ! yunohost domain list --output-as json | jq -r '.domains[]' | grep -q "^$list_dom$"; then
        ynh_print_warn "The domain '$list_dom' is not managed by this Yunohost instance."
        return 1
    fi
}

is_domain_mail_set() {
    local list_dom=$1

    local incoming_mail_enabled=$(yunohost domain config get $list_dom feature.mail.mail_in)
    local outgoing_mail_enabled=$(yunohost domain config get $list_dom feature.mail.mail_out)

    if [[ $incoming_mail_enabled != "1" && $outgoing_mail_enabled != "1" ]]; then
        ynh_print_warn "Both mail in and mail out are not activated for $list_dom"
        return 1
    elif [[ $incoming_mail_enabled != "1" ]]; then
        ynh_print_warn "Mail in is not activated for $list_dom"
        return 1
    elif [[ $outgoing_mail_enabled != "1" ]]; then
        ynh_print_warn "Mail out is not activated for $list_dom"
        return 1
    fi

    return 0
}

# Vérifie si le courrier entrant est activé pour le domaine
is_incoming_mail_enabled() {
    local list_dom="$1"
    local incoming_mail_enabled=$(yunohost domain config get "$list_dom" feature.mail.mail_in)

    if [[ $incoming_mail_enabled != "1" ]]; then
        ynh_print_warn "Mail in is not activated for $list_dom."
        return 1
    fi

    return 0
}

# Vérifie si le courrier sortant est activé pour le domaine
is_outgoing_mail_enabled() {
    local list_dom="$1"
    local outgoing_mail_enabled=$(yunohost domain config get "$list_dom" feature.mail.mail_out)

    if [[ $outgoing_mail_enabled != "1" ]]; then
        ynh_print_warn "Mail out is not activated for $list_dom."
        return 1
    fi

    return 0
}

create_list() {

    local tmpconf=$(ynh_exec_as_app mktemp)
    cat << EOF | ynh_exec_as_app tee $tmpconf >/dev/null
SPOOLDIR="$install_dir"
LISTNAME="tmp"
FQDN="$domain_part"
OWNER="$(yunohost user info $owner --output-as json | jq -r '.mail')"
TEXTLANG='$language'
ADDALIAS='n'
DO_CHOWN='y'
CHOWN='$app'
ADDCRON='n'
EOF
    chmod +r $tmpconf
    ynh_exec_as_app "$install_dir"/app/bin/mlmmj-make-ml -f $tmpconf

    mv $install_dir/tmp $install_dir/list
    chmod 700 $install_dir/list

    pushd $install_dir/list/control
        # cf http://mlmmj.org/TUNABLES.html for documentation about these
        echo "$list_email" > listaddress
        echo "[$local_part]" > prefix
        touch moderators
        touch subonlypost
        touch notifysub
        touch subonlyget
        touch nodigestsub
        touch nonomailsub
        echo "10485760" > maxmailsize  # 10MB
        echo "postfix" > verp
    popd

    [ -f "../conf/footer_${language}.tpl" ] \
    && footer_template="footer_${language}.tpl" \
    || footer_template="footer_en.tpl"
    ynh_config_add --template="$footer_template" --destination="$install_dir/list/control/footer"

    chown -R $app:$app $install_dir/list/control

    mkdir -p "$install_dir/tables"
    touch "$install_dir/tables/transport"
    touch "$install_dir/tables/virtual"

    local transport_entry="$app@localhost.mlmmj       $app:$app"
    local virtual_entry="$list_email    $app@localhost.mlmmj"

    if ! grep -qF "$transport_entry" "$install_dir/tables/transport"; then
        echo "$transport_entry" >> "$install_dir/tables/transport"
        postmap "$install_dir/tables/transport"
    fi

    if ! grep -qF "$virtual_entry" "$install_dir/tables/virtual"; then
        echo "$virtual_entry" >> "$install_dir/tables/virtual"
        postmap "$install_dir/tables/virtual"
    fi

    chown -R $app:postfix $install_dir/tables
}
