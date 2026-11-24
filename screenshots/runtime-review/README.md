# Issue 53 runtime review captures

These images show the actual Certifications Flutter web app, compiled in release mode from commit `2fb134eca32036ef9b45711fe18155cf2c5c528f` and served locally. No screenshot fixture, backend response interception, or product source patch was used for the captures.

A disposable Chrome profile loaded the release app. Before each capture, the profile stored the app's normal local preference fields for the selected language and theme and the test user's choice to accept only necessary cookies. The page was reloaded after those values were set. Chrome's DevTools Protocol captured the app at a 1300 by 3800 CSS pixel desktop viewport or a 390 by 4000 CSS pixel phone viewport, after allowing fonts and Flutter rendering to settle. The protocol session and temporary app server were local to the test environment.

The variants cover English and Thai in light and dark modes on desktop and phone, plus Portuguese on desktop and phone in light mode. The desktop screenshots show Plans, About and Log in in the top navigation and all How-it-works labels. Phone screenshots show the compact navigation menu. Portuguese copy fits the captured layouts.

These captures verify the screenshot discrepancy reported for issue 53 against a fresh release build. They do not represent a production deployment or prove backend availability.
