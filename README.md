# PEAppTransaction-Logger

[![Build Status](https://travis-ci.org/evanspa/PEAppTransaction-Logger.svg)](https://travis-ci.org/evanspa/PEAppTransaction-Logger)

An iOS static library client for the [PEAppTransaction Logging Framework](#peapptransaction-logging-framework).

PEAppTransaction-Logger is also a part of the
[PE* iOS Library Suite](#pe-ios-library-suite).

**Table of Contents**

- [PEAppTransaction Logging Framework](#peapptransaction-logging-framework)
  - [Motivation](#motivation)
- [About PEAppTransaction-Logger](#about-peapptransaction-logger)
- [Usage Guide](#usage-guide)
    - [Flushing Locally-Stored Transaction Data to Remote Data Store](#flushing-locally-stored-transaction-data-to-remote-data-store)
    - [Format of JSON Request Bodies for HTTP POST Flush Calls](#format-of-json-request-bodies-for-http-post-flush-calls)
- [Reference Application](#reference-application)
- [Installation with CocoaPods](#installation-with-cocoapods)
- [PE* iOS Library Suite](#pe-ios-library-suite)

## PEAppTransaction Logging Framework

The PEAppTransaction Logging Framework (PELF) is a framework for capturing important
events within your applications.  It is comprised of 3 main tiers: (1)
[the core data layer](https://github.com/evanspa/pe-apptxn-core), (2)
[the web service layer](https://github.com/evanspa/pe-apptxn-restsupport)
and (3) client libraries.

This repository, *PEAppTransaction-Logger*, represents an iOS client library to the framework.

The PELF provides a small set of functions to log what are termed "application transactions."  An application transaction is not a transaction in a database sense; it is meant more to model application-level actions.  For example, a user creating a new purchase order within your application would be termed as an application transaction.  A user signing in to your application would be an application transaction.  A user signing out, another.  

The PELF provides both client-side and server-side libraries.  PELF client-side libraries (*such as this one*) are used by applications to locally record user-initiated application transactions and transaction events.  Transaction events are simply timestamped events associated with an application transaction.  E.g., if "create a purchase order" is an application transaction, a transaction event might be: "user clicks 'New PO' button to initiate transaction."  Another event might be: "web service request initiated to submit new PO data to server".  And another: "web service response received".  All of this log data is saved locally on the client, and then later pushed to the server for permanent storage (and offline analysis).

### Motivation

The motivation behind the creation of the PEAppTransaction logging framework is
simple: to systematically track important events about the goings-on within an
application (*an end-user application or otherwise*).  You can use the framework
to record information about your application, such as:
+ How long a user takes to fill-out a form.
+ What the round-trip time is for making web service calls.
+ How often a user leaves a screen in your app without fulfilling the
call-to-action.

The set of use cases for which to use the framework to log metadata is
open-ended.  You can use it for basic A/B testing, tracking performance-related
metrics and many more.

## About PEAppTransaction-Logger

PEAppTransaction-Logger is an iOS static library to serve as a client to the
**PEAppTransaction Logging Framework**.  PEAppTransaction-Logger enables you to
create and locally save *transaction* and *transaction log* instances; a
transaction is used to track events associated with *use cases* within your
application; transaction logs are used to track particular timestamped events
about individual use cases.

These transaction and transaction logs are stored locally in a SQLite database,
and are meant to be persisted to a remote date store (for offline analysis).
The [pe-apptxn-core](https://github.com/evanspa/pe-apptxn-core) repository
represents a Clojure-based library implementing such a data store.  This library
provides a [Datomic](http://www.datomic.com) schema file, as well as CRUD data
access functions.

In addition,
[pe-apptxn-restsupport](https://github.com/evanspa/pe-apptxn-restsupport) exists
as a convenient library exposing a REST API on top of pe-apptxn-core.
pe-apptxn-restsupport is also implemented in Clojure, and leverages
[Liberator](http://clojure-liberator.github.io/liberator/).
pe-apptxn-restsupport provides a set of Liberator resources that could easily be
included in a concrete REST application.

## Usage Guide

There are 3 primary abstractions associated with the PEAppTransaction logging
framework exposed by its client libraries:
(1) transactions, (2) transaction logs and (3) the transaction manager.

A transaction is a container meant to track information about an application
*use case*.  A use case could be anything; it's up to you.  For example, a use
case might be *logging in* to the app.  Or *creating an account* or *submitting
an order*.  When a use case is initiated in your app (*usually by a user*), you
would first create an appropriate transaction instance.  But before you can create
transaction instances, you first need to create a transaction manager.  You
should only have 1 transaction manager for your application, so it's recommended
that you create the instance in your app delegate's
`application:didFinishLaunchingWithOptions:` function.

As mentioned above, PEAppTransaction-Logger is an iOS static library **client**
within the PEAppTransaction Logging Framework.  The framework assumes there is a
web service fronting the backend data store.  An instance of
TLTransactionManager is used to flush locally-stored transaction / transaction
log items to the remote store via the web service.

PEAppTransaction-Logger leverages
[PEHateoas-Client](https://github.com/evanspa/PEHateoas-Client) to interact with
the web service.  In order to create a TLTransactionManager instance, we first
need to create an HCRelationExecutor instance:

```objective-c
// Needed by TLTransactionManager instance for interacting with web service
HCRelationExecutor *relExec =
  [[HCRelationExecutor alloc] initWithDefaultAcceptCharset:[HCCharset UTF8]
                                     defaultAcceptLanguage:@"en-US"
                                 defaultContentTypeCharset:[HCCharset UTF8]
                                  allowInvalidCertificates:NO];

NSFileManager *fileMgr = [NSFileManager defaultManager];
// URL of local folder to contain SQLite data file
NSURL *sqliteDataFileFolderUrl = [fileMgr URLForDirectory:NSLibraryDirectory
                                                 inDomain:NSUserDomainMask
                                        appropriateForURL:nil
                                                   create:YES
                                                    error:nil];
// URL of SQLite data file
NSURL *sqliteDataFileUrl =
  [sqliteDataFileFolderUrl URLByAppendingPathComponent:@"peapptxns.data"];

// Finally we create the transaction manager instance
TLTransactionManager *txnMgr =
  [[TLTransactionManager alloc] initWithDataFilePath:[sqliteDataFileUrl absoluteString]
                                 userAgentDeviceMake:[PEUtils deviceMake] // from PEObjc-Commons
                                   userAgentDeviceOS:[[UIDevice currentDevice] systemName]
                            userAgentDeviceOSVersion:[[UIDevice currentDevice] systemVersion]
                                    relationExecutor:relExec
                                          authScheme:@"auth-scheme"
                                  authTokenParamName:@"auth-token"
                                  contentTypeCharset:[HCCharset UTF8]
                                  apptxnResMtVersion:@"1.0.0"
                                               error:nil]; // provide non-nil err handler in 'real' code

// Set the URI of the remote 'transactions' REST resource.  How you get this
// is dependent on your application.
NSURL *txnStoreResourceUri = ...;
[txnMgr setTxnStoreResourceUri:txnStoreResourceUri];

// Authentication token used when invoking web service layer (application
// dependent)
NSString *authToken = ...;
[txnMgr setAuthToken:authToken];
```
With the transaction manager instance in hand, we are now ready to start logging
things.  Lets assume you have an application that requires a user to *log in*,
and that you consider, *for transaction logging purposes*, logging in to be a
*use case* that you want to track events against using PEAppTransaction logging
framework.  Assume you have a view controller for the login screen.  In the
view controller's `viewDidLoad` function would be a good place to create a
`TLTransaction` instance to track events against the *logging in* use case.

But before we do this, quick sidebar: transaction *use cases* as modeled in the
PEAppTransaction logging framework are represented by simple integer values.  So
for example our *logging in* use case may have the number 0 associated with it.
Our *creating an account* use case may have the number 1 associated with it,
etc.  The framework also uses numbers to represent individual events that can be
recorded against a use case (*transaction*).  To keep your code organized, it's
recommeded to create a `.h` file to centrally define your transaction and
transaction event use case numbers.  Assume we have a `.h` file like so:

```objective-c
// Define use case values
typedef NS_ENUM(NSInteger, PEAppTxnUsecase) {
  PEAppTxnLogin,
  PEAppTxnCreateAccount,
  ...
};

// Define use case event values
typedef NS_ENUM(NSInteger, PETxnLoginUsecaseEvent) {
  PETxnLoginEvtInitiated,
  PETxnLoginEvtCanceled,
  PETxnLoginEvtRemoteCommReqInitiated,
  PETxnLoginEvtRemoteProcStarted,        // recorded server-side
  PETxnLoginEvtRemoteProcDoneErrOccured, // recorded server-side
  PETxnLoginEvtRemoteProcDoneInvalid,    // recorded server-side
  PETxnLoginEvtRemoteProcDoneSuccess,    // recorded server-side
  PETxnLoginEvtRemoteCommRespReceived
};

...
```

Now in your login controller's `viewDidLoad` function, create a transaction
instance, and create a log representing the event that the user has initiated
the *logging in* use case:

```objective-c
// error handling block
TLDaoErrorBlk errorBlk = ^(NSError *err, int errCode, NSString *errDesc) {
  NSLog(@"Error attempting to persist txn log to local SQLite store: %@", err);
};

// Creating the transaction instance for our 'logging in' use case
TLTransaction *loggingInTxn = [_txnMgr transactionWithUsecase:@(PEAppTxnLogin)];

// Log the fact the user has initiated the act of logging in.
[loggingInTxn logWithUsecaseEvent:@(PETxnLoginEvtInitiated) error:errorBlk];
```

If the user somehow *cancels* their attempt at logging in (*by tapping a
'back' button or 'cancel' button or whatever*), you can log that too:

```objective-c
// Log the fact the user has canceled logging in
[loggingInTxn logWithUsecaseEvent:@(PETxnLoginEvtCanceled) error:errorBlk];
```

When the user taps the button to *log in*, right before your view controller
makes the (*presumably*) web service call to your authentication service, you
write a log:

```objective-c
// Log the fact that your app initiated the web service call to log in the user
[loggingInTxn logWithUsecaseEvent:@(PETxnLoginEvtRemoteCommReqInitiated) error:errorBlk];
```

And in the completion handler or callback of your web service call, you can log that you got
the response:

```objective-c
// Log the fact that the 'log in' web service response was received.
[loggingInTxn logWithUsecaseEvent:@(PETxnLoginEvtRemoteCommRespReceived) error:errorBlk];
```

Each log that is written is timestamped, and each log instance is tied to its
transaction instance (in the code above, our `loggingInTxn` instance).  And each
transaction instance is identified by a GUID string.

FYI, take another look at the `.h` file we defined above containing our use case
and use case event integer values.  Notice how some of the use case event values
are commented as being `// recorded server-side`.  With the framework, it is
assumed that server-side code can contribute log data for a particular
transaction instance.  To accomplish this, in our example above, the web service
call made to authenticate the user can include a custom HTTP header containing
the GUID of the transaction instance.  In this way, the server-side code
implementing the authentication-check of the user, can log the fact it RECEIVED
the inbound web service request, and can log other use case events; it can do
this because it has the GUID of the containing transaction.

For what it's worth, if you are also using
[PEHateoas-Client](https://github.com/evanspa/PEHateoas-Client) in your
application to integrate with your own web services, the various `doXXX` functions
contain a `otherHeaders:(NSDictionary *)otherHeaders` part that is a good place
to attach such custom request headers.

#### Flushing Locally-Stored Transaction Data to Remote Data Store

Both transaction and transaction log instances accumulate in your application's
SQLite database as users use your app.  In order for the transaction log data to
be of any value, it needs to be shipped to your server for later
(actionable) analysis.  TLTransactionManager comes with 2 functions to perform
this job:
+ `synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:`
+ `asynchronousFlushTxnsToRemoteStore:`

`asynchronousFlushTxnsToRemoteStore:` is the recommended function since it
performs the remote flush on a background thread.  It accepts an `NSTimer *`
instance so it's ready to be invoked by a timer.  If the remote store fronting
web service responds with a 2XX, then the transaction log data is deleted from
the local SQLite database.

The PEAppTransaction logging framework stipulates that clients need only (HTTP)
POST transction log data sets to the remote store fronting web service.  If you
choose to implement your own fronting web service (as opposed to leveraging
[PEAppTransaction-ServerResources](https://github.com/evanspa/PEAppTransaction-ServerResources))
here's what you need to know:

#### Format of JSON Request Bodies for HTTP POST Flush Calls

Here is an example message that contains a single transaction instance, with 2
child transaction log instances.

```json
{"apptxns" : [
    {"apptxn/usecase" : 17,
     "apptxn/user-agent-device-os-version" : "8.1.2",
     "apptxn/id" : "TXN17-586AB00B-F16E-4AE6-8A91-0210264925C7",
     "apptxn/user-agent-device-make" : "iPhone7,2",
     "apptxn/user-agent-device-os" : "iPhone OS",
     "apptxn/logs" : [
         {"apptxnlog/usecase-event" : 0,
          "apptxnlog/in-ctx-err-code" : null,
          "apptxnlog/timestamp" : "Fri, 06 Feb 2015 00:59:27 EST"},
         {"apptxnlog/usecase-event" : 1,
          "apptxnlog/in-ctx-err-code" : null,
          "apptxnlog/timestamp" : "Fri, 06 Feb 2015 01:23:05 EST"}
      ]
    }
  ]
}
```

The `Content-Type` header of the POST request will be something like:
`application/vnd.peapptxnlog.apptxnset-v0.0.1+json;charset=UTF-8`

The version part (the **0.0.1** bit) is based on the
`apptxnResMtVersion:` part of TLTransactionManager's initializer that you
provide.  The character set part (the **UTF-8**) is based on the
`contentTypeCharset:` part of TLTransactionManager's initializer that you
provide.

## Reference Application

To see how the PEAppTransaction client logger is used in a working application,
look at the
[PEFuelPurchase-App application](https://github.com/evanspa/PEFuelPurchase-App).
The fuel purchase application serves as the reference application for the PE*
suite of iOS client libraries.

## Installation with CocoaPods

```ruby
pod 'PEAppTransaction-Logger', '~> 1.0.1'
```

## PE* iOS Library Suite
*(Each library is implemented as a CocoaPod-enabled iOS static library.)*
+ **[PEObjc-Commons](https://github.com/evanspa/PEObjc-Commons)**: a library
  providing a set of everyday helper functionality.
+ **[PEXML-Utils](https://github.com/evanspa/PEXML-Utils)**: a library
  simplifying working with XML.  Built on top of [KissXML](https://github.com/robbiehanson/KissXML).
+ **[PEHateoas-Client](https://github.com/evanspa/PEHateoas-Client)**: a library
  for consuming hypermedia REST APIs.  I.e. those that adhere to the *Hypermedia
  As The Engine Of Application State ([HATEOAS](http://en.wikipedia.org/wiki/HATEOAS))* constraint.  Built on top of [AFNetworking](https://github.com/AFNetworking/AFNetworking).
+ **[PEWire-Control](https://github.com/evanspa/PEWire-Control)**: a library for
  controlling Cocoa's NSURL loading system using simple XML files.  Built on top of [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs).
+ **PEAppTransaction-Logger**: this library.
+ **[PESimu-Select](https://github.com/evanspa/PESimu-Select)**: a library
  aiding in the functional testing of web service enabled iOS applications.
+ **[PEDev-Console](https://github.com/evanspa/PEDev-Console)**: a library
  aiding in the functional testing of iOS applications.

