#--------------------------------------------------------------------------------------#
# Websphere Deployment Automation helper perl script                                   #
# wasdeploy.pl - Used with Active Perl v5.14.2                                         #
# Modules may need to be add the modules like File Copy Recursive etc before using it. #
# 04/10/2010 - Re Written by Joshan George                                             #
# 12/05/2011 - Updated by Joshan George                                                #
# 12/08/2011 - Updated by Joshan George                                                #
#--------------------------------------------------------------------------------------#

use strict;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::Path;
use MIME::Lite;
use POSIX qw/strftime/;

=for comment
# Sample usage code
my $wasHome ="<<WAS_HOME>>"; # WAS_HOME
my $earFolderName = "<<EAR_FOLDER_NAME>>"; # Ear folder name
my $earFolderBase = "<<EAR_BASE_FOLDER_NAME>>"; # Ear folder base including the last slash
my $deployHost = "<<DEPLOY_HOST>>"; #Deploy Host
my $deployPort = "<<DEPLOY_SOAP_PORT>>"; #Deploy Host SOAP Port
my $deployUser = "<<DEPLOY_USER>>"; #UserName
my $deployPass = "<<DEPLOY_PASS>>"; #Password
my $scriptLoc = "<<SCRIPT_LOCATION>>"; # deploy scripts and config directory [You can change based on your machine]
my $deployEarLocationBase = "<<DEPLOYMENT_BASE_EAR_LOCATION>>"; # Depoyment Directory [You can change based on your machine]
my $deployEarListStr ="all"; # Ears need to be deployed or completed path
my $deployEnv = "<<DEPLOY_ENV_FOLDER>>"; # Deployment Environment folder
my $deployClusterStartCommand = "rippleStart"; #start / rippleStart
my $cleanUpAndReDeployFlag = "Y"; # Y / N
my $dependentEarPattern = "<<DEPENDED_EARS_NAME_PATTERN>>"; # Dependent Ear Pattern
my $orderOfEars = "<<DEPLOY_EAR_ORDER>>"; # Deployment Ear(s) Order in comma seperated by value
my $runtimeUpdateFlag = "N"; # Y / N, Y=> No need to stop the cluster. Deploy and Ripple Start the cluster
my $notificationFlag = "N"; # Y / N, Y=> Do we need to send the notification email
my $fromEmail = "<<FROM_EMAIL>>"; # From Email
my $replyToEmail = "<<REPLYTO_EMAIL>>"; # Reply To Email
my $toEmail = "<<TO_EMAIL>>"; # To Email
my $ccEmail = "<<CC_EMAIL>>"; # Cc Email
my $smtpHost = "<<SMTP_HOST>>"; #SMTP Host
my $smtpPort = "<<SMTP_PORT>>"; #SMTP Port
my $deploymentComments = "<<DEPLOYMENT_COMMENTS>>";
deploy($wasHome, $earFolderName, $earFolderBase, $deployHost, $deployPort, $deployUser, $deployPass, $scriptLoc, $deployEarLocationBase, $deployEarListStr, $deployEnv, $deployClusterStartCommand, $cleanUpAndReDeployFlag, $dependentEarPattern, $orderOfEars, $runtimeUpdateFlag, $notificationFlag, $fromEmail, $replyToEmail, $toEmail, $ccEmail, $smtpHost, $smtpPort, $deploymentComments);
=cut

sub deploy() {
  my $wasHome = $_[0];
  my $earFolderName = $_[1];
  my $earFolderBase = $_[2];
  my $deployHost = $_[3];
  my $deployPort = $_[4];
  my $deployUser = $_[5];
  my $deployPass = $_[6];
  my $scriptLoc = $_[7];
  my $deployEarLocationBase = $_[8];
  my $deployEarListStr = $_[9];
  my $deployEnv = $_[10];
  my $deployClusterStartCommand = $_[11];
  my $cleanUpAndReDeployFlag = $_[12];
  my $dependentEarPattern =$_[13];
  my $orderOfEars = $_[14];
  my $runtimeUpdateFlag = $_[15];
  my $notificationFlag = $_[16];
  my $fromEmail = $_[17];
  my $replyToEmail = $_[18];
  my $toEmail = $_[19];
  my $ccEmail = $_[20];
  my $smtpHost = $_[21];
  my $smtpPort = $_[22];
  my $deploymentComments = $_[23];

  my $argSmry = "";
  $argSmry .= "\n-----------------------------------------------------------------------------\n";
  $argSmry .= "\n<WAS Home>                                           $wasHome";
  $argSmry .= "\n<EAR Folder Name>                                    $earFolderName";
  $argSmry .= "\n<EAR Folder Directory>                               $earFolderBase";
  $argSmry .= "\n<Deployment Host>                                    $deployHost";
  $argSmry .= "\n<Deployment Port(SOAP)>                              $deployPort";
  $argSmry .= "\n<Deployment Username>                                $deployUser";
  $argSmry .= "\n<Deployment Password>                                $deployPass"; # Password should be removed from log before the normal use
  $argSmry .= "\n<Scripts Location>                                   $scriptLoc";
  $argSmry .= "\n<Deployment Ear Location Base>                       $deployEarLocationBase";
  $argSmry .= "\n<Deployment Ears>                                    $deployEarListStr";
  $argSmry .= "\n<Deployment Env>                                     $deployEnv";
  $argSmry .= "\n<Deployment Cluster Start Cmd> [start/rippleStart]   $deployClusterStartCommand";
  $argSmry .= "\n<Clean and re-deploy Flag> [Y/N]                     $cleanUpAndReDeployFlag";
  $argSmry .= "\n<Dependent Ear Name Pattern>                         $dependentEarPattern";
  $argSmry .= "\n<Order need to be followed in Deployment>            $deployEnv";
  $argSmry .= "\n<Runtime Update Flag - Full Availability Deployment> $runtimeUpdateFlag";
  $argSmry .= "\n<From Email(s)>                                      $fromEmail";
  $argSmry .= "\n<ReplyTo Email>                                      $replyToEmail";
  $argSmry .= "\n<To Email(s)>                                        $toEmail";
  $argSmry .= "\n<CC Email(s)>                                        $ccEmail";
  $argSmry .= "\n<SMTP Host>                                          $smtpHost";
  $argSmry .= "\n<SMTP Port>                                          $smtpPort";
  $argSmry .= "\n<Deployment Comments>                                $deploymentComments";
  $argSmry .= "\n-----------------------------------------------------------------------------\n";

  print $argSmry;

  my $timeFormatFolder = strftime('%Y%m%d_%H%M%S',localtime);

  my $earFolderPath = "$earFolderBase/$earFolderName";
  $earFolderPath =~ s/[\/\\][\/]{0,1}[\\]{0,1}/\//g;
  my $deployEarLocation = "$deployEarLocationBase/$deployEnv";
  $deployEarLocation =~ s/[\/\\][\/]{0,1}[\\]{0,1}/\//g;

  mkdir("$deployEarLocation", 0777) || print"\n$deployEarLocation $!\n";
  my $earBackup = "$deployEarLocationBase/backup/$deployEnv";
  mkdir("$earBackup", 0777) || print"\n$earBackup $!\n";
  print "\nBackUp Folder Path: $earBackup\n";
  print "\nEar Folder Path: $earFolderPath\n";
  my @earsList = listFilesWithPattern($earFolderPath,'.*\.ear');

  if($cleanUpAndReDeployFlag eq "Y" or $cleanUpAndReDeployFlag eq "y") {
    #Clean Up the existing ears in the deployment ear location
    my @cleanUpEarList = listFilesWithPatternRecursive($deployEarLocation, ".*\.ear\$");
    print"\n";
    print "\nDeployment ear location ($deployEarLocation) - Clean Up [Deleting the previous deployment file(s)]";
    print"\n";
    foreach(@cleanUpEarList) {
      print "\n  $_ deleting.";
      unlink($_);
      print "\n  $_ deleted.";
    }
    my $earCount = @cleanUpEarList;
    if($earCount == 0) {
      print "\n  Nothing to Clean Up..";
    } else {
      print "\n  $earCount ear(s) deleted.";
    }

    #print"\n".rmtree($deployEarLocation)."\n";
    #mkdir("$deployEarLocation", 0777) || print"\n$deployEarLocation $!\n";

    print "\nDeployment ear location ($deployEarLocation) - Clean Up Completed\n";

    #Move ears from $earFolderPath $deployEarLocationBase/$deployEnv which are specified in the EAR List
    print "\nMove ear(s) from ear path [$earFolderPath] to deployment ear location [$deployEarLocationBase/$deployEnv].\n";
    if($deployEarListStr =~ /^(all)$/i) {
      print copyFilesWithPatternRecursive($earFolderPath,$deployEarLocation, ".*\.ear\$")." file(s) copied.";
      $deployEarListStr = findAndBuildEarListString($deployEarLocation, $deployEnv, $dependentEarPattern, $orderOfEars);
      print "\n\nDeployment ear location ($deployEarLocation) - Ear list string builded.\n\nEar List String: $deployEarListStr\n\n";
    } else {
      my @deployEarList = split(/,/, $deployEarListStr);

      foreach(@deployEarList) {
        my $earPath = extractEarPath($_);
        my $earName = substr($earPath, rindex($earPath, '/')+1, length($earPath));
        print "\n$earName -> $earPath\n";
        print "\n$earPath coping to $deployEarLocation/$earName\n";
        copy($earPath,"$deployEarLocation/$earName") or die "Copy failed: $!";
      }
      #print "\nDeploy Ear Str: $deployEarListStr\n";
      my $folderPathPattern = $earFolderPath;
      $folderPathPattern =~ s/[\/\\][\\]{0,1}/[\/\\\\][\\\\]{0,1}/g;
      #print "\nFolder Pattern: $folderPathPattern";
      $deployEarListStr =~ s/$folderPathPattern/$deployEarLocation/g;
      #print "\nDeploy Ear Str: $deployEarListStr\n";
    }

  } else {
    $deployEarListStr = findAndBuildEarListString($deployEarLocation, $deployEnv, $dependentEarPattern, $orderOfEars);
  }

  if($deployEarListStr ne "") {

    if($notificationFlag eq "y" or $notificationFlag eq "Y") {
      #Deployment Start Notification
      my $time = strftime('%m/%d/%Y %H:%M:%S %z',localtime);
      my $configFilePath = "$scriptLoc/config";
      my $subject = "Deployment Notification for $deployEnv Started - $time";
      my $messageBody = getFileContents($configFilePath, "deploymentnotification.html");
      my $applicationsAndEarLocation = formatEarPathString($deployEarListStr);
      $applicationsAndEarLocation =~ s/,/\<br\/\>/g;
      $messageBody =~ s/\$subject/$subject/g;
      $messageBody =~ s/\$deployEnv/$deployEnv/g;
      $messageBody =~ s/\$deploymentComments/$deploymentComments/g;
      $messageBody =~ s/\$time/$time/g;
      $messageBody =~ s/\$applicationsAndEarLocation/$applicationsAndEarLocation/g;
      my $attachmentStr = "";
      my $bccEmail = "";
      sendMail($smtpHost, $smtpPort, $fromEmail, $replyToEmail, $toEmail, $ccEmail, $bccEmail, $subject, $messageBody, $attachmentStr);
    }
    my $wscmdArgBase = "\"$wasHome/bin/wsadmin\" -lang jython -conntype SOAP -host $deployHost -port $deployPort -user $deployUser -password $deployPass -f ";
    print "\n\n\nWebsphere Deployment started. \n\n";

    if($runtimeUpdateFlag eq "Y" and $runtimeUpdateFlag eq "y") {  
      $runtimeUpdateFlag = "y";
    } else {
      $runtimeUpdateFlag = "n";
    }
    my $cmd = "$wscmdArgBase $scriptLoc/wasadminscriptnd.py stopInstallUpdateStartEars $deployEarListStr $deployClusterStartCommand $runtimeUpdateFlag";
    print "\n$cmd\n";
    system($cmd);

    print "\Deployment completed. \n";

    $earBackup .= "/$timeFormatFolder";
    mkdir("$earBackup", 0777) || print"\n$earBackup $!\n";

    my @earsList = listFilesWithPatternRecursive($deployEarLocation,'.*\.ear');

    foreach(@earsList) {
      my $earName = substr($_, rindex($_, '/')+1, length($_));
      my $earPath = substr($_, 0, rindex($_, $earName)-1);
      my $subDirPathName = substr($earPath, rindex($earPath, $deployEnv)+length($deployEnv)+1, length($earPath));
      mkdir("$earBackup/$subDirPathName", 0777) || print"\n$earBackup/$subDirPathName $!\n";
      print "\n$earName -> $earPath\n";
      print "\n$earPath/$earName moving to $earBackup/$subDirPathName/$earName\n";
      move("$earPath/$earName","$earBackup/$subDirPathName/$earName") or die "Copy failed: $!";
    }
    if($notificationFlag eq "y" or $notificationFlag eq "Y") {
      #Deployment Complete Notification
      my $time = strftime('%m/%d/%Y %H:%M:%S %z',localtime);
      my $configFilePath = "$scriptLoc/config";
      my $subject = "Deployment Notification for $deployEnv Completed - $time";
      my $messageBody = getFileContents($configFilePath, "deploymentnotification.html");
      my $applicationsAndEarLocation = formatEarPathString($deployEarListStr);
      $applicationsAndEarLocation =~ s/,/\<br\/\>/g;
      $messageBody =~ s/\$subject/$subject/g;
      $messageBody =~ s/\$deployEnv/$deployEnv/g;
      $messageBody =~ s/\$deploymentComments/$deploymentComments/g;
      $messageBody =~ s/\$time/$time/g;
      $messageBody =~ s/\$applicationsAndEarLocation/$applicationsAndEarLocation/g;
      my $attachmentStr = "";
      my $bccEmail = "";
      sendMail($smtpHost, $smtpPort, $fromEmail, $replyToEmail, $toEmail, $ccEmail, $bccEmail, $subject, $messageBody, $attachmentStr);
    }
  } else {
    print "\n No ear(s) found for deployment!\n";
  }
}

sub findAndBuildEarListString() {
  my $deployEarLocation = $_[0];
  my $deployEnv = $_[1];
  my $dependentEarPattern = $_[2];
  my $orderOfEars = $_[3];

  my @deployEarList = listFilesWithPatternRecursive($deployEarLocation, ".*\.ear\$");
  print"\n";
  print "\nDeployment ear location ($deployEarLocation) - Finding ear(s) that need to be deployed.";
  print"\n";
  my $deployEarListStrTemp;
  my @deployEarListTemp;
  foreach(@deployEarList) {
    $deployEarListStrTemp = "";
    my $earName = substr($_, rindex($_, '/')+1, length($_));
    my $earPath = substr($_, 0, rindex($_, $earName)-1);
    #With assumption that ear file exits
    # one level under the deployment ear directory with application name as the directory name
    #  [application name is the first level directory name, if and only if ear exists in the first level directory and only one ear should be there]
    # directly under the deployment ear directory or any where in the ear deployment sub directories
    #  [application name is same as the ear name without extension]
    my $appName;
    my $envDeployDirNamePattern = "$deployEnv\$";
    if($earPath =~ m/$envDeployDirNamePattern/) {
      $appName = substr($earName, 0, length($earName)-4);
    } else {
      my $subDirPathName = substr($earPath, rindex($earPath, $deployEnv)+length($deployEnv)+1, length($earPath));
      #print "\nSubDirPathName: $subDirPathName";
      my $slashCount = @{[$subDirPathName =~ /(\/)/g]};
      if($slashCount == 0 ) {
        $appName = substr($subDirPathName, 0, length($earPath)-1);
      } else {
        $appName = substr($earName, 0, length($earName)-4);
      }
    }
    #print "\n[AppName, EarName, EarPath]: $appName -> $earName -> $earPath";
    my $deployEarPathStrTemp = "$appName#$earPath/$earName";
    if($earName =~ m/$dependentEarPattern/) {
      $deployEarPathStrTemp = $deployEarPathStrTemp."-d";
    } else {
      $deployEarPathStrTemp = $deployEarPathStrTemp."-i";
    }
    $deployEarListStrTemp .= $deployEarPathStrTemp;
    push(@deployEarListTemp, $deployEarListStrTemp);
    print "\nEar Path String: $deployEarListStrTemp";
    print "\n";
  }

  #re-order ear list based of the given order
  my @orderOfEarsList = split(/[,]+/, $orderOfEars);
  my @deployEarListTempOrder;
  foreach(@orderOfEarsList) {
    my $earNameTemp = trim($_);
    $earNameTemp = $earNameTemp."(-[id]{1}){0,1}\$";
    if($earNameTemp ne "") {
      my $i = 0;
      foreach(@deployEarListTemp) {
        $i = $i + 1;
        if($_ =~ m/$earNameTemp/) {
          push(@deployEarListTempOrder, $_);
          splice(@deployEarListTemp, $i-1, 1);
        }
      }
    }
  }
  foreach(@deployEarListTemp) {
    push(@deployEarListTempOrder, $_);
  }

  my $deployEarListStr = join(",", @deployEarListTempOrder);
  return $deployEarListStr;
}

sub formatEarPathString() {
  my $deployEarListStr = $_[0];
  my @deployEarList = split(/[,]+/, $deployEarListStr);
  my $outputStr = "";
  my $atleastOne = "Y";
  foreach(@deployEarList) {
    my $appName = extractAppName($_);
    my $earPath = extractEarPath($_);
    my $fmtStr = "$appName - $earPath";
    $outputStr = $outputStr.$fmtStr;
    if($atleastOne eq "Y") {
      $outputStr = $outputStr.",";
    }
    $atleastOne = "Y";
  }

  return $outputStr;
}

sub extractAppName() {
  my $ear = $_[0];
  my $appName = '';
  $appName = $ear;
  if(index($ear, '#')>-1) {
    $appName = substr($ear, 0, index($ear, '#'));
  } else {
    if(index($ear, '.ear')>-1) {
      $appName = substr(extractEarName($ear), 0, index(extractEarName($ear), '.'));
    }  
  }
  return $appName;
}

sub extractEarPath() {
  my $ear = $_[0];
  my $earPath = '';
  $earPath = $ear;
  if(index($ear, '#')>-1) {
    $earPath = substr($ear, index($ear, '#')+1, length($ear));
  }
  $earPath =~ s/-[di]$//g;
  return $earPath;
}

sub extractEarName() {
  my $ear = $_[0];
  my $earName = '';
  $earName = $ear;
  if(index($ear, '.ear')>-1) {
    $earName = substr($ear, rindex($ear, '/')+1, length($ear));
  }
  $earName =~ s/-[di]$//g;
  return $earName;
}

sub listFilesWithPattern() {
  my $dir = $_[0];
  my $pattern = $_[1];
  my @fileList;
  opendir(DIRPATH, $dir) or die(print "Error opening Directory: $dir");
  my @files = grep { -f "$dir/$_" } readdir(DIRPATH);
  foreach my $name (@files) {
    my $fileFullPath = $dir;
    $fileFullPath .= "/";
    if (($name =~ /$pattern/)) {
      $fileFullPath .= $name;
      push(@fileList,$fileFullPath);
    }
  }

  close(DIRPATH);
  return @fileList;
}

sub copyFilesWithPatternRecursive() {
  my $fromDir = $_[0];
  my $toDir = $_[1];
  my $pattern = $_[2];
  my $fileMatchCount = 0;
  my $fileMatchCountTotal = 0;
  opendir(DIRPATH, $fromDir);
  for my $fileDirName (readdir DIRPATH) {
    chomp($fileDirName);
    my $sFileDir = "$fromDir/$fileDirName";
    my $dFileDir = "$toDir/$fileDirName";
    #print "\nFileDirName: $fileDirName -> $fromDir\n";
    if($fileDirName ne "." and $fileDirName ne "..") {
      if(-f $sFileDir) {
        if($fileDirName =~ m/$pattern/i) {
          copy($sFileDir, $dFileDir);
          print "\n$sFileDir copied to $dFileDir";
          $fileMatchCount = $fileMatchCount + 1;
        }
      } elsif(-d $sFileDir) {
        mkdir $dFileDir;
        $fileMatchCountTotal = $fileMatchCountTotal + copyFilesWithPatternRecursive($sFileDir, $dFileDir, $pattern);
      }
    }
  }
  print "\n";
  $fileMatchCountTotal = $fileMatchCountTotal + $fileMatchCount;
  if($fileMatchCount<1) {
    rmdir $toDir;
  }
  closedir DIRPATH;
  return $fileMatchCountTotal;
}

sub listFilesWithPatternRecursive() {
  my $dir = $_[0];
  my $pattern = $_[1];
  my @fileList;
  opendir(DIRPATH, $dir);
  for my $fileDirName (readdir DIRPATH) {
    chomp($fileDirName);
    my $sFileDir = "$dir/$fileDirName";
    #print "\nFileDirName: $fileDirName -> $dir\n";
    if($fileDirName ne "." and $fileDirName ne "..") {
      if(-f $sFileDir) {
        if($fileDirName =~ m/$pattern/i) {
          #print "\n$sFileDir";
          push(@fileList,$sFileDir);
        }
      } elsif(-d $sFileDir) {
        push(@fileList, listFilesWithPatternRecursive($sFileDir, $pattern));
      }
    }
  }
  closedir DIRPATH;
  return @fileList;
}

sub sendMail() {
  my $smtpHost = $_[0];
  my $smtpPort = $_[1];
  my $fromAddress = $_[2];
  my $replyToAddress = $_[3];
  my $toAddress = $_[4];
  my $ccAddress = $_[5];
  my $bccAddress = $_[6];
  my $subject = $_[7];
  my $messageBody = $_[8];
  my $attaachmentStr = $_[9];
  my @attachList = split(/[,]+/, $attaachmentStr);
  print "SMTP Host: $smtpHost\nSMTP Port: $smtpPort\nFrom Email: $fromAddress\nReply To Email: $replyToAddress\nTo Email(s): $toAddress\nCc Email(s): $ccAddress\nBcc Email(s): $bccAddress\nSubject: $subject\nMessage: $messageBody\nAttachments: $attaachmentStr\n";

  ### Create the multipart container
  my $msg = MIME::Lite->build (
      From => $fromAddress,
      To => $toAddress,
      Subject => $subject,
      #reply-To => $replyToAddress,
      cc=> $ccAddress,
      bcc => $bccAddress,
      Type =>'multipart/mixed'
    ) or die "Error creating multipart container: $!\n";

  ### Add the text message part
  $msg->attach (
      Type => 'HTML',
      Data => $messageBody
    ) or die "Error adding the text message part: $!\n";


  foreach my $fPath (map { glob } @attachList) {
    if (not -d $fPath ) {
      print "File $fPath attached.\n";
      ### Add the ZIP file
      $msg->attach (
           Type => 'application/octet-stream',
           Path => $fPath,
           Filename => extractFileNameFromPathName($fPath),
           Disposition => 'attachment'
        ) or die "Error adding $fPath: $!\n";
    }
  }

  ### Send the Message
  MIME::Lite->send('smtp', $smtpHost, Port => $smtpPort, Timeout=>60);
  $msg->send;
  print "\nMail sent successfully!\n";
}

sub getFileContents() {
  my $fileLocation = $_[0];
  my $fileName = $_[1];
  my $filePath = "$fileLocation/$fileName";
  my $outputStr;
  open(file, $filePath) or die "Can not open $filePath $!\n";
  foreach my $line (<file>) {
    chomp($line);
    $outputStr .= $line."\n"
  }
  close(file);
  return $outputStr;
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

# Left trim function to remove leading whitespace
sub ltrim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim($) {
  my $string = shift;
  $string =~ s/\s+$//;
  return $string;
}

