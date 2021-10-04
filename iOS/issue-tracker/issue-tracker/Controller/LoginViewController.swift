//
//  ViewController.swift
//  issue-tracker
//
//  Created by 양준혁 on 2021/06/07.
//

import UIKit
import AuthenticationServices
import NetworkModule

enum GitHubConstants {
  static let clientID = "7f71cead009837015ba3"
  static let scope = "repo user"
  static let redirectURI = "issuetracker"
  static let authorizeURL = "https://github.com/login/oauth/authorize"
}

enum LoginError: Error {
  case invalidAuthorizeURL
  case invalidAuthorizationCode
}

class LoginViewController: UIViewController {
  
  @IBOutlet weak var githubLoginButton: GitHubLoginButton!
  
  @IBAction func didTapGithubLogin(_ sender: Any) {
    do {
      let session = try authenticate(completion: { [weak self] in
        guard let self = self else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "main")
        mainViewController.modalPresentationStyle = .fullScreen
        self.present(mainViewController, animated: true)
      })
      session.presentationContextProvider = self
      session.start()
    } catch {
      print(error)
    }
  }
  
  private func authenticate(completion: @escaping () -> Void) throws -> ASWebAuthenticationSession {
    var authorizeURLComponents = URLComponents(string: GitHubConstants.authorizeURL)
    authorizeURLComponents?.queryItems = [
      URLQueryItem(name: "client_id", value: GitHubConstants.clientID),
      URLQueryItem(name: "scope", value: GitHubConstants.scope)
    ]
    guard let authorizeURL = authorizeURLComponents?.url else {
      throw LoginError.invalidAuthorizeURL
    }
    let authenticationSession = ASWebAuthenticationSession(
      url: authorizeURL,
      callbackURLScheme: GitHubConstants.redirectURI,
      completionHandler: { (callbackURL: URL?, error: Error?) in
        guard
          error == nil,
          let callbackURL = callbackURL,
          let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems,
          let code = queryItems.first(where: { $0.name == "code" })?.value
        else {
          print(LoginError.invalidAuthorizationCode)
          return
        }
        APIManager.shared.requestAccessToken(code: code) { result in
          switch result {
          case .success(let token):
            print(token)
            completion()
          case .failure(let error):
            print(error.localizedDescription)
          }
        }
      })
    return authenticationSession
  }
}

extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return self.view.window ?? ASPresentationAnchor()
  }
}
