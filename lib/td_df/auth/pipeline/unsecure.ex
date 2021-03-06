defmodule TdDf.Auth.Pipeline.Unsecure do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :td_df,
    error_handler: TdDf.Auth.ErrorHandler,
    module: TdDf.Auth.Guardian
  # If there is a session token, validate it
  #plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  # If there is an authorization header, validate it
  #plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  # Load the user if either of the verifications worked
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
end
