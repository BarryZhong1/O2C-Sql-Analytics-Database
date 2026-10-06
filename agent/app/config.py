from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    openai_api_key: str = ""
    openai_model: str = "gpt-5"
    database_url: str = "mysql+pymysql://app:app_pw@localhost:3306/o2c"
    policy_path: str = "policies"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
