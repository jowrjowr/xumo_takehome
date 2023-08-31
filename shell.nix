{ pkgs ? import <nixos-23.05> {} }:

with pkgs;

let
  inherit (lib) optional optionals;
  #elixir = beam.packages.erlangR25.elixir_1_14;
in

mkShell {
  buildInputs = [
    ps
    elixir_1_15
    coreutils
    which
    git
    nix-prefetch-git
    zlib
    jq
    postgresql
    openssl
    nodejs
    docker
    docker-compose
  ]
  ++ optional stdenv.isLinux glibc
  ++ optional stdenv.isLinux glibcLocales
  ;

  # Fix GLIBC Locale
  LANG = "en_US.UTF-8";
  LOCALE_ARCHIVE = lib.optionalString stdenv.isLinux
    "${pkgs.glibcLocales}/lib/locale/locale-archive";
  ERL_INCLUDE_PATH="${pkgs.erlang}/lib/erlang/usr/include";

  # *DEVELOPMENT* secrets
  # I EMPHASIZE DEVELOPMENT HERE

    shellHook = ''
    function aws_mfa {

      # reset so old stuff isn't used
      AWS_ACCESS_KEY_ID=""
      AWS_SECRET_ACCESS_KEY=""
      AWS_SESSION_TOKEN=""

      # fetch credentials
      MFA_ARN=$(aws iam list-mfa-devices | jq -r '.MFADevices[0].SerialNumber' | tr -d '"')
      CREDENTIALS=$(aws sts get-session-token --duration-seconds 129600 --serial-number $MFA_ARN --token-code $1)

      # store
      export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
      export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
      export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')
      EXPIRES=$(echo $CREDENTIALS | jq '.Credentials.Expiration')

      echo "AWS Session Token expires at $EXPIRES"

    }

    if [ -f "$AUTH0_PATH" ]; then
      source "$AUTH0_PATH"
    fi
  '';

}
