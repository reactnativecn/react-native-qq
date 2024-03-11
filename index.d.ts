declare module "react-native-qq" {
  export interface LoginInfo {
    access_token: string
    expires_in: number
    oauth_consumer_key: string,
    errCode: number,
    openid: string
  }
  export function login (key: string): Promise<LoginInfo>
}

