# trust-line-ios [Work in progress]
trust line iOS app

Do not use yet unless you know what you're doing.

#### Pairing procedure
![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_pairing.gif)

- You need to connect the token to a powersource, like a USB port.

- Make sure the bluetooth is enabled

- Push the pair button (central) in order to start the paring procedure

- The trustline secrets are the token secrets keys. They are reprensented in the form of a QR Code to be printed.
This is a critical piece of information. It will be required if you loose or break your current token.
This QRCode can decrypt your password, so keep it somewhere safe. Note that Airprint feature will be added soon.



#### Create a new password
![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_create_password.gif)

- Create a new account
- You can also specify your login, and a size (strength) for your password
- Note that login is optional
- Also note that neihter the account name, nor the login are encrypted
- The encrypted password sent from the token is stored into the iPhone (and iCloud if enabled : not implemented yet)


#### Send keystrokes
![](https://github.com/amoriello/trust-line-ios/raw/develop/demos/demo_keyboard.gif)

When your token is powered to a computer via USB port, it simulates a HID keyboard :
- Sliding a row from left to rigth will send the encrypted password to the token
- The token will decrypt the password and type it where your focus is
- When the color is green : the password is typed
- When the color is yellow (litle further green) : the password is typed, followed by "ENTER"




More features to come
