
-- URL for service - used by the lib_login unless set in the env using $OPENIDLOGIN_URL
CONSTANT C_OPENIDLOGIN = "https://generodemos.dynu.net/g/ua/r/OpenIdLogin"

CONSTANT C_OPENID = "#OpenId#"

-- Record structure returned
TYPE t_oidc RECORD
  email STRING,
  family STRING,
  given STRING,
  idp_issuer STRING,
  idp_token_endpoint STRING,
  name STRING,
  picture STRING,
  profile STRING,
  sub STRING,
  token_expires_in INTEGER,
  userinfo_endpoint STRING
END RECORD
