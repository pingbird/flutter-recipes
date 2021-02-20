---
title: Sending Mail
parent: FAQ
---

# Sending Mail

A lot of people are using packages such as [mailer](https://pub.dev/packages/mailer) in their app to send email to their
users, this is an awful idea for a couple of reasons.

First, the email and password used by the app are easily accessible by hackers, there is nothing you can do to perfectly
hide them. Another problem is that a lot of ISPs and firewalls block SMTP to prevent spam, which would break your app.

The correct way to send email is from either a backend or service like Firebase:
[https://medium.com/@edigleyssonsilva/cloud-functions-for-firebase-sending-e-mail-1f2631d1022e](https://medium.com/@edigleyssonsilva/cloud-functions-for-firebase-sending-e-mail-1f2631d1022e)