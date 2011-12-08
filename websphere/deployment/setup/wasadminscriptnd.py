#-------------------------------------------------------------------------------------#
# Websphere Deployment Automation helper WAS Admin scripts - wrote in Jython          #
# wasadminscriptnd.py - Used in Websphere 7.0 Network Deployment                      #
# 04/10/2010 - Re Written by Joshan George                                            #
# 12/05/2011 - Updated by Joshan George                                               #
# 12/06/2011 - Updated by Joshan George                                               #
#-------------------------------------------------------------------------------------#

import sys
import re

from javax.management import MBeanException
from com.ibm.websphere.management.exception import AdminException
from com.ibm.ws.scripting import ScriptingException
from com.ibm.websphere.wlm.exception import ClusterException
from com.ibm.bsf import BSFException

def synchronizeNodes():
  ############################Node Synchronization############################
  print "\nStarted syncing Node(s)\n"
  #Sync configuration changes with nodes
  AdminConfig.save()
  #Obtain deployment manager MBean
  dm=AdminControl.queryNames("type=DeploymentManager,*")
  print dm, "\n"
  #syncActiveNodes can only be run on the deployment manager's MBean, 
  #it will fail in standalone environment
  if dm:
    print '\nSynchronizing configuration repository with nodes. Please wait...\n'
    # Force sync with all currently active nodes
    nodes=AdminControl.invoke(dm, 'syncActiveNodes', 'true')
    print '\nThe following nodes have been synchronized: '+str(nodes) , '\n'
  else:
    print "\nStandalone server, no nodes to sync.\n"
  ############################################################################
#end def

def getClusterName(appName):
  clusterName = AdminApp.listModules(appName, '-server').split('cluster=')[1].split('+WebSphere')[0]
  #print clusterName
  return clusterName
#end def

def restartCluster(clusterName, restartOption):
  #restartOption values: stop | start | restart | rippleStart | immediate
  print "\nCluster: ", clusterName, " RestartOption: ", restartOption
  cell = AdminControl.getCell()
  clusterCompleteObjectName = AdminControl.completeObjectName('cell=' + cell+ ',type=Cluster,name=' + clusterName + ',*')
  #print clusterCompleteObjectName
  retry = 5
  while(retry > 0):
    try:
      AdminControl.invoke(clusterCompleteObjectName, restartOption)
      retry = 0
    except ScriptingException:
      #print "\n", str(sys.exc_info()[0]), " _ " , str(sys.exc_info()[1]), " _ " , str(sys.exc_info()[2]), " _ " , str(sys.exc_info()[3]), " _ " , str(sys.exc_info()[4])
      print "\nUnexpected error:", ScriptingException;
      pass
      retry -= 1
      print "\n Retry -> ",(5-retry) , " ", restartOption
      sleep(30)
  print "\n", clusterName, " ", restartOption, " request issued."
#end def

def getClusterStatus(clusterName):
  #print "\nClusterName" , clusterName
  clusterId = AdminConfig.getid("/ServerCluster:"+clusterName+"/" )
  if(clusterId):
    clusterCompleteObjectName = AdminControl.completeObjectName('cell=' + cell+ ',type=Cluster,name=' + clusterName + ',*')
    clusterStatus = AdminControl.getAttribute(clusterCompleteObjectName, "state" )
    #print "\n", clusterName, " " , clusterStatus
    return clusterStatus
#end def

def checkAppExists(appName):
  appList = AdminApp.list().splitlines()
  rtnVal = 0
  if(appName in appList):
    rtnVal = 1
  return rtnVal
#end def

#Extract AppName from EarPath [(AppName#){0,1}earPath(-[id]){0,1}]
def extractAppName(ear):
  appNamePassed = ''
  appNameFromEarName = ''
  if(ear.rfind('/') > -1 and ear.rfind('.ear')> -1) :
    appNameFromEarName = ear[(ear.rfind('/')+1):ear.rfind('.ear')]
  if(ear.find('#') > -1):
    appNamePassed = ear[0:ear.find('#')]
  if(appNamePassed == ''):
    appNamePassed = appNameFromEarName
  return appNamePassed 
#end def

#Extract AppName from EarPath [(AppName#){0,1}earPath(-[id]){0,1}]
def extractEarFile(ear):
  earPath = ear
  if(ear.find('#')>-1):
    earPath = ear[ear.find('#')+1:len(ear)]
  return earPath.strip().replace("-d","").replace("-i","")
#end def

def findAndProcessEarList(earFiles, startCommand, runtimeUpdate):
  earFiles = earFiles.strip()
  earList = earFiles.split(',')
  errorEars = ''
  iEars = ''
  dEars = ''
  for ear in earList:
    if(not(ear=='')):
      if(ear.endswith('.ear-d')):
        dEars += ear + ","
      elif(ear.endswith('.ear-i')):
        iEars += ear + ","
      elif(ear.endswith('.ear')):
        iEars += ear + ","
      else:
        errorEars += ear + ","

  print "\nEar(s) List: ",  [x for x in earFiles.split(',') if x]
  print "\nError Ear(s): ",  [x for x in errorEars.split(',') if x]
  print "\nIndependent Ear(s) (Independent Install): ", [x for x in iEars.split(',') if x]
  print "\nDependent Ear(s) (Dependent Install): ",  [x for x in dEars.split(',') if x]
  
  print "\nInstalling Independent Ears"
  iEars = iEars.strip()
  if(not(iEars =='')):
    errorEars += stopInstallUpdateStartEars(iEars, startCommand, runtimeUpdate)
  else:
    print "\n No Ear(s) to deploy"

  print "\nInstalling Dependent Ears"
  dEars = dEars.strip()
  if(not(dEars =='')):
    errorEars += stopInstallUpdateStartEars(dEars, startCommand, runtimeUpdate)
  else:
    print "\n No Ear(s) to deploy"

  errorEars = errorEars.strip()
  return errorEars
#end def

def stopInstallUpdateStartEars(earFiles, startCommand, runtimeUpdate):
  #restartOption values: stop | start | restart | rippleStart | immediate
  errorEars = ''
  earFiles = earFiles.strip()
  earList = earFiles.split(',')
  earList = [x for x in earList if x]

  #Verifying ear name pattern
  for ear in earList:
    ear = ear.strip()
    if(not(ear.endswith('.ear') or ear.endswith('.ear-d') or ear.endswith('.ear-i'))):
      errorEars += ear + ","
      earList.remove(ear)
  errorEars = errorEars.strip()
  print "\nError Ears: ", [x for x in errorEars.split(',') if x]
  print "\nEar List: ", earList
  
  if(runtimeUpdate=='n'):
    #Stopping Application Cluster(s)
    for ear in earList:
      appName = extractAppName(ear)
      if(checkAppExists(appName)):
        clusterName = getClusterName(appName)
        restartCluster(clusterName, 'stop')
      else:
        print " Stop Cluster Failed, ", appName, " Not Found!."

    #Make suring the cluster(s) are in stopped status
    print "\n"
    for ear in earList:
      appName = extractAppName(ear)
      if(checkAppExists(appName)):
        clusterName = getClusterName(appName)
        status = getClusterStatus(clusterName)
        clusterReadyTime = 300
        while clusterReadyTime > 0:
          print "\n", clusterName, " " , status.replace("websphere.cluster.","") , ", ", (300-clusterReadyTime), "sec."
          if status == 'websphere.cluster.stopped':
            clusterReadyTime = 0
          elif status == 'websphere.cluster.starting' or status == 'websphere.cluster.running' or status == 'websphere.cluster.partial.start':
            sleep(40)
            restartCluster(clusterName, 'stop')
          else:
            clusterReadyTime = clusterReadyTime - 10
            sleep(10)
            status = getClusterStatus(clusterName)
      else:
        print "Stop Cluster Verification Failed, ", appName, " Not Found!."
  else:
    startCommand = 'rippleStart'

  #Installing Application(s)
  for ear in earList:
    appName = extractAppName(ear)
    earName = extractEarFile(ear)
    if(checkAppExists(appName)):
      print "\nInstallation started ",appName, " - ", ear
      clusterName = AdminApp.listModules(appName, '-server').split('cluster=')[1].split('+WebSphere')[0]
      try:
        AdminApp.install(earName, '[-appname ' + appName + ' -update -update.ignore.new]')
        AdminConfig.save()
        # Check to see if the app has been deployed, ignoring nodes/servers in an unknown state
        # Note: we're assuming node sync hasn't been disabled...if it has been, you'll have to
        # add in sync code.
        print "\n***" + appName + " installed.***\n"
      except ScriptingException:
        #print "\n", str(sys.exc_info()[0]), " _ " , str(sys.exc_info()[1]), " _ " , str(sys.exc_info()[2]), " _ " , str(sys.exc_info()[3]), " _ " , str(sys.exc_info()[4])
        print "\nUnexpected error:", ScriptingException;
        pass
        errorEars += ear + ",";
        print "\nApplication Installation Failed, ", appName, " ", str(ScriptingException)
    else:
      errorEars += ear + ",";
      print "\nApplication Installation Failed, ", appName, " Not Found!."
  
  #Syncing Node(s)
  synchronizeNodes()

  #Starting Application Cluster(s)
  for ear in earList:
    appName = extractAppName(ear)
    if(checkAppExists(appName)):
      clusterName = getClusterName(appName)
      restartCluster(clusterName, startCommand)
    else:
      print "'", startCommand,"' Cluster Failed, ", appName, " Not Found!."

  #Make suring the cluster(s) are in started status
  print "\n"
  for ear in earList:
    appName = extractAppName(ear)
    if(checkAppExists(appName)):
      clusterName = getClusterName(appName)
      status = getClusterStatus(clusterName)
      clusterReadyTime = 300
      while clusterReadyTime > 0:
        print "\n", clusterName, " " , status.replace("websphere.cluster.","") , ", ", (300-clusterReadyTime), "sec."
        if status == 'websphere.cluster.running':
          clusterReadyTime = 0
        elif status == 'websphere.cluster.stopped' or status == 'websphere.cluster.partial.stop':
          sleep(40)
          restartCluster(clusterName, startCommand)
        else:
          clusterReadyTime = clusterReadyTime - 10
          sleep(10)
          status = getClusterStatus(clusterName)
    else:
      print "'", startCommand,"' Cluster Verification Failed, ", appName, " Not Found!."

  return errorEars
#end def

#main
node = AdminControl.getNode()
cell = AdminControl.getCell()
#synchronizeNodes();

print "\n###################################################################"
print "\n###########################Begin###################################"
print "\nCell: ", cell, " Node: ", node, "\n"
print "Arguments (",len(sys.argv),"): ", sys.argv

cell = AdminControl.getCell()
node = AdminControl.getNode()

if len(sys.argv) == 4:
  operCmd = sys.argv[0]
  earFiles = sys.argv[1]
  startCommand = sys.argv[2]
  runtimeUpdate = sys.argv[3]

  if operCmd.find('stopInstallUpdateStartEars') > -1:
    print "\nStarted processing the following ears - Stop App Cluster(s) -> Install App(s) -> Start App Cluster(s)"
    earFiles = earFiles.strip()
    earList = earFiles.split(',')
    newEarList = []

    for ear in earList:
      print "\n ",ear
      newEarList.append(ear.strip())
    earList = newEarList
    print "\n"

    startCommand = startCommand.strip()
    errorEars = findAndProcessEarList(earFiles, startCommand, runtimeUpdate)
    print "\nCompleted processing of all the ear(s) except the following errored ones"
    #print "\n", errorEars, "\n"
    errorEarList = errorEars.split(',')
    for ear in errorEarList:
      print "\n ",ear
    print "\n"
    errorEarList = [x for x in errorEarList if x]
    errorEars =','.join([str(x) for x in errorEarList])
    print "earList: ", earList
    for ear in errorEarList:
      print "->", ear
      earList.remove(ear)

    fEarStr =','.join([str(x) for x in earList])
    print "\n:ERROR:", errorEars.split(',')
    print "\n:NO ERROR:", fEarStr.split(',')
    print "\n"
  else:
    print "Operation command not found ######"
else:
  print "Total Arguments should be 3, \n\t\t(1)=> stopInstallUpdateStartEars \n\t\t(2)=> (AppName#){0,1}((<<earPath>>(-[id]){0,1}),?) \n\t\t(3)=> start/rippleStart"
#end if
print "\n###################################################################\n"
print "\n#########################Completed#################################\n"
#end main
