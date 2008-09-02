#!/usr/bin/env perl
use strict;
use warnings;

use Template::Perlish qw( render );

use lib '../lib';
use Net::Amazon::S3::Policy;

if (@ARGV != 3) {
   print {*STDERR} <<'DOCUMENTATION';
perl sample-form.pl <AWS-ID> <AWS-secret> <bucket>

   Prints the policy on STDERR, prints the sample web page with the form
   on STDOUT.

DOCUMENTATION

   exit 1;
}

my ($aws_key, $aws_secret, $bucket) = @ARGV;
my $policy = Net::Amazon::S3::Policy->new(
   expiration => time() + 60 * 60, # one-hour policy
   conditions => [
      'key    starts-with restricted/', # restrict to here
      "success_action_redirect starts-with http://$bucket.s3.amazonaws.com/restricted/",
      "bucket eq $bucket",
      'Content-Type starts-with image/',
      'x-amz-meta-colour *',
      'acl eq public-read',
   ],
);

print {*STDERR} $policy->json(), "\n";

my $template = do { local $/; <DATA> };
print {*STDOUT} render($template,
   policy64 => $policy->base64(),
   signature64 => $policy->signature_base64($aws_secret),
   AWSAccessKeyId => $aws_key,
   bucket => $bucket,
);


__END__
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
   <title>An example form page for Amazon S3 HTTP POST interface</title>
   <meta http-equiv="content-type" content="text/html;charset=utf-8" />
   <meta http-equiv="Content-Style-Type" content="text/css" />
</head>

<body>

   <h1>Put your data here...</h1>

   <form action="https://[% bucket %].s3.amazonaws.com/" method="post"
         enctype="multipart/form-data" id="uploader">
   <p>
      <!-- inputs needed because bucket is not publicly writeable -->
      <input type="hidden" name="AWSAccessKeyId" value="[% AWSAccessKeyId %]" />
      <input type="hidden" name="policy" value="[% policy64 %]" />
      <input type="hidden" name="signature" value="[% signature64 %]" />

      <!-- input needed by AWS-S3 logic: there MUST be a key -->
      <input type="hidden" name="key" value="restricted/${filename}" />

      <!-- inputs that you want to include in your form -->
      <input type="hidden" name="acl" value="public-read" />
      <input type="hidden" name="Content-Type" value="image/jpeg" />
      <input type="hidden" name="success_action_redirect"
         value="http://[% bucket %].s3.amazonaws.com/restricted/${filename}" />
      
      <label for="colour">Colour:</label>
      <input type="text" name="x-amz-meta-colour" id="colour" value="green" />

      <!-- input needed to have something to upload. LAST IN FORM! -->
      <br />
      <label for="file">File</label>
      <input type="file" id="file" name="file" />

      <br />
      <input type="submit" name="submit" value="send" />

   </p>
   </form>

</body>

</html>
