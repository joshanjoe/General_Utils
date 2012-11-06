#---------------------------------------------------------------------------------------------#
# WAS (WebSphere Application Server) Local Workspace setup WAS Admin script - wrote in Jython #
# wasenvsetup.py                                                                              #
# 09/29/2010 - Re written by Joshan George                                                    #
# 08/25/2011 - Updated by Joshan George                                                       #
# 01/19/2012 - Updated by Joshan George                                                       #
#---------------------------------------------------------------------------------------------#

import sys
import re

from com.ibm.websphere.scripting import ScriptingException

def findBus(busName):
  buses = AdminTask.listSIBuses()
  for bus in buses.splitlines():
    if(bus.find(busName) > -1):
      return bus

def deleteBus(busName):
  bus = findBus(busName)
  if not bus== None:
    AdminTask.deleteSIBus('[-bus '+ busName +' ]')  
    AdminConfig.save()
    print " Bus: ",busName, " deleted."
  else:
    print " Bus: ",busName, " not found"

def createBus(busName, messageThreshold="100000"):
  bus = findBus(busName)
  if bus== None:
    AdminTask.createSIBus('[-bus '+ busName +' -busSecurity false -scriptCompatibility 6.1 ]')
    # WAS7 Specific Command
    #AdminTask.modifySIBus('[-bus '+ busName +' -configurationReloadEnabled true -discardOnDelete false -bootstrapPolicy SIBSERVICE_ENABLED -highMessageThreshold '+ messageThreshold +' -protocol  -description  ]')
    AdminConfig.save()
    print " Bus: ",busName, " created."
  else:
    print " Bus: ",busName, " is already exists."

def findBusMember(busName):
  busMembers = AdminTask.listSIBusMembers('[-bus ' + busName + ' ]')
  for busMember in busMembers.splitlines():
    return busMembers

def addBusMember(busName, serverName="server1"):
  busMember = findBusMember(busName)
  if busMember == None:
    AdminTask.addSIBusMember('[-bus '+ busName +' -node '+ AdminControl.getNode() +' -server '+ serverName +' -fileStore  -logSize 100 -minPermanentStoreSize 200 -maxPermanentStoreSize 500 -unlimitedPermanentStoreSize false -minTemporaryStoreSize 200 -maxTemporaryStoreSize 500 -unlimitedTemporaryStoreSize false ]')
    AdminConfig.save()
    print " Bus member ",serverName,"added to the bus -", busName
  else:
    print " Bus member ",serverName," is already exists in the ", busName

# Type:- Queue or TopicSpace
def createBusDestination(busName,busDestinationName,destinationType,serverName="server1"):
  try:
    AdminTask.createSIBDestination('[-bus '+ busName +' -name '+ busDestinationName +' -type '+ destinationType +' -reliability ASSURED_PERSISTENT -description  -node '+ AdminControl.getNode() +' -server '+ serverName +' ]')
    AdminConfig.save()
    print " Bus Destination: ",destinationType, " deatination[",busDestinationName,"] created on the bus ", busName
  except:
    print " Bus Destination: ",destinationType, " deatination[",busDestinationName,"] is already exists on the bus ", busName," please verify."

def modifyStartupBeanService(flag,serverName="server1"):
  serverId = AdminConfig.getid('/Node:' + AdminControl.getNode() + '/Server:' + serverName + '/' )
  startUpBeansServiceId = AdminConfig.list('StartupBeansService', serverId) 
  AdminConfig.modify(startUpBeansServiceId, '[[enable "' + flag + '"]]')
  AdminConfig.save()
  print " Server: ",serverName, " startup bean service configuration changed to '", flag,"'"

#----------------------------------------------------------
#
# Modify WebServerPluginProperties [ServerIOTimeout to "0"]
#
#----------------------------------------------------------
def modifyWebServerPluginProperties(serverIOTimeout, serverName="server1"):
  serverId = AdminConfig.getid('/Node:' + AdminControl.getNode() + '/Server:' + serverName + '/' )
  webserverPluginSettingsId = AdminConfig.list('WebserverPluginSettings', serverId) 
  AdminConfig.modify(webserverPluginSettingsId, '[[ExtendedHandshake "false"] [ConnectTimeout "0"] [WaitForContinue "false"] [ServerIOTimeout "' + serverIOTimeout + '"] [MaxConnections "0"]]')
  AdminConfig.save()
  print " Server: ",serverName, " WebServerPluginProperties [ServerIOTimeout=",serverIOTimeout,"] configuration changed."

def findWorkManager(workManagerName):
  workManagers = AdminConfig.list('WorkManagerInfo', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/'))
  for workManager in workManagers.splitlines():
    if(workManager.find(workManagerName) > -1):
      return workManager

def deleteWorkManager(workManagerName):
  workManager = findWorkManager(workManagerName)
  if not workManager == None:
    AdminConfig.remove(workManager)
    AdminConfig.save()
    print " Work Manager: ",workManagerName, " deleted"
  else:
    print " Work Manager: ",workManagerName, " not found"
  
def createWorkManager(workManagerName, jndi, min, max, growable, workTimeout):
  workManager = findWorkManager(workManagerName)
  if workManager == None:
    AdminConfig.create('WorkManagerInfo', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/WorkManagerProvider:WorkManagerProvider/'), '[[workReqQFullAction "0"] [name "' + workManagerName + '"] [minThreads "' + min + '"] [category ""] [daemonTranClass ""] [defTranClass ""] [numAlarmThreads "2"] [workReqQSize "0"] [jndiName "' + jndi + '"] [maxThreads "' + max + '"] [isGrowable "' + growable + '"] [serviceNames ""] [description ""] [threadPriority "5"] [workTimeout "'+ workTimeout +'"]]')
    AdminConfig.save()
    print " Work Manager: ",workManagerName, " created with > JNDI: ", jndi," MinThreads: ", min," MaxThreads: ", max," Growable: ", growable," WorkTimeout: ", workTimeout
  else:
    print " Work Manager: ",workManagerName, " already exists"

#----------------------------------------------------------
#
# It appears there's a root cache provider that's an argument to creating an object cache instance
# This gets the "root" cache provider 
# Based on testing, it looks like the "root" provider is always last in the list
#
#----------------------------------------------------------
def getRootCacheProvider():
  cacheProvs = AdminConfig.list('CacheProvider', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/')).splitlines()
  arrayLen = len(cacheProvs)
  return cacheProvs[arrayLen-1]

#----------------------------------------------------------
#
# finds a JDBC provider based on a keyword in the name (e.g., 'Oracle', 'SQL Server', etc)
#
#----------------------------------------------------------
def findJDBCProvider(providerName):
  jdbc_providers = AdminConfig.list('JDBCProvider', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/'))
  for provider in jdbc_providers.splitlines():
     if(provider.find(providerName) > -1):
         return provider

#----------------------------------------------------------
#
# Create Default "Oracle JDBC provider" if it not exists in cell scope
#
#----------------------------------------------------------
def createOracleJDBCProvider(oracleJarPath):
  oracle_jdbc_provider = findJDBCProvider('Oracle')
  if oracle_jdbc_provider == None:
    AdminTask.createJDBCProvider('[-scope Cell=' + AdminControl.getCell() + ' -databaseType Oracle -providerType "Oracle JDBC Driver" -implementationType "Connection pool data source" -name "Oracle JDBC Driver" -description "Oracle JDBC Driver" -classpath [' + oracleJarPath + ' ] -nativePath "" ]')
    AdminConfig.save()
    oracle_jdbc_provider = findJDBCProvider('Oracle')
    AdminConfig.modify(oracle_jdbc_provider, '[[classpath ' + oracleJarPath + '] [implementationClassName "oracle.jdbc.pool.OracleConnectionPoolDataSource"] [name "Oracle JDBC Driver"] [isolatedClassLoader "false"] [nativepath ""] [description "Oracle JDBC Driver"]]')
    print " Oracle JDBC Provider: ",oracle_jdbc_provider, " not found, so created a default Oracle JDBC Provider with driver jar ",oracleJarPath,"."
    AdminConfig.save()
  else:
    #AdminConfig.modify(oracle_jdbc_provider, '[[classpath ' + oracleJarPath + '] [implementationClassName "oracle.jdbc.pool.OracleConnectionPoolDataSource"] [name "Oracle JDBC Driver"] [isolatedClassLoader "false"] [nativepath ""] [description "Oracle JDBC Driver"]]')
    AdminConfig.save()
    print " Oracle JDBC Provider: ",oracle_jdbc_provider, " found, skip the creation step and modified the driver jar to ",oracleJarPath,"."

#----------------------------------------------------------
#
# Delete Default "Oracle JDBC provider" if it exists in cell scope
#
#----------------------------------------------------------
def deleteOracleJDBCProvider():
  oracle_jdbc_provider = findJDBCProvider('Oracle')
  if not oracle_jdbc_provider == None:
    #AdminConfig.remove(oracle_jdbc_provider)
    AdminConfig.save()
    print " Oracle JDBC Provider: ",oracle_jdbc_provider, " deleted."
    AdminConfig.save()
  else:
    print " Oracle JDBC Provider: ",oracle_jdbc_provider, " not found."
		 
#----------------------------------------------------------
#
# finds an existing J2C resource based on its name
#
#----------------------------------------------------------
def findJ2CResource(resourceName):
  j2cNames = AdminTask.listAuthDataEntries()
  
  for j2cEntry in j2cNames.splitlines():
    if(j2cEntry.find(resourceName) > -1):
      return j2cEntry.split(" ")[1].split("]")[0]

def findCacheReplicationDomain(cacheReplicationDomainName):
  cacheReplicationDomains = AdminConfig.list('DataReplicationDomain', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/'))
  for cacheReplicationDomain in cacheReplicationDomains.splitlines():
    if(cacheReplicationDomain.find(cacheReplicationDomainName) > -1):
      return cacheReplicationDomain

def deleteCacheReplicationDomain(cacheReplicationDomainName):
  cacheReplicationDomain = findCacheReplicationDomain(cacheReplicationDomainName)
  if not cacheReplicationDomain== None:
    AdminConfig.remove(cacheReplicationDomain)
    AdminConfig.save()
    print " Cache Replication Domain: ",cacheReplicationDomainName, " deleted"
  else:
    print " Cache Replication Domain: ",cacheReplicationDomainName, " not found"

def createCacheReplicationDomain(cacheReplicationDomainName):
  try:
    cacheReplicationDomain = findCacheReplicationDomain(cacheReplicationDomainName)
    if cacheReplicationDomain== None:
      AdminConfig.create('DataReplicationDomain', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/'), '[[name "' + cacheReplicationDomainName + '"]]')
      AdminConfig.create('DataReplication', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/DataReplicationDomain:' + cacheReplicationDomainName + '/'), '[[requestTimeout 5] [numberOfReplicas -1] [encryptionType NONE]]')
      AdminConfig.save()
      print " Cache Replication Domain: ",cacheReplicationDomainName, " created"
    else:
      print " Cache Replication Domain: ",cacheReplicationDomainName, " already exists"
  except:
    print " Cache Replication Domain: ",cacheReplicationDomainName, " already exists. please verify"

def findObjectCache(objectCacheName):
  objectCaches = AdminConfig.list('CacheInstance', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/'))
  for objectCache in objectCaches.splitlines():
    if(objectCache.find(objectCacheName) > -1):
      return objectCache

def deleteObjectCache(cacheName):
  objectCache = findObjectCache(cacheName)
  if not objectCache == None:
    AdminConfig.remove(objectCache)
    AdminConfig.save()
    print " Object Cache: ",cacheName, " deleted"
  else:
    print " Object Cache: ",cacheName, " not found"

def createObjectCache(cacheName, jndiName, cacheReplicationDomainName):
  try:
    createCacheReplicationDomain(cacheReplicationDomainName)
    objectCache = findObjectCache(cacheName)
    if objectCache == None:
      newObjCache = AdminTask.createObjectCacheInstance('"' + getRootCacheProvider() + '"', '[-name ' + cacheName + ' -jndiName ' + jndiName + ']')
      newDiskCachePolicy = AdminConfig.create('DiskCacheEvictionPolicy', '"' + newObjCache + '"', '[]')
      newDRSSettings = AdminConfig.create('DRSSettings', '"' + newObjCache + '"', '[]')
      AdminConfig.modify(newDRSSettings, '[[messageBrokerDomainName "' + cacheReplicationDomainName + '"]]')
      AdminConfig.modify(newDiskCachePolicy, '[[algorithm "NONE"] [lowThreshold "70"] [highThreshold "80"]]')
      newDiskCachePerfSetings = AdminConfig.create('DiskCacheCustomPerformanceSettings', '"' + newObjCache + '"', '[]')
      AdminConfig.modify(newDiskCachePerfSetings, '[[maxBufferedTemplates "100"] [maxBufferedDependencyIds "10000"] [maxBufferedCacheIdsPerMetaEntry "1000"]]')
      AdminConfig.modify(newObjCache, '[[defaultPriority "1"] [disableDependencyId "false"] [name "' + cacheName + '"] [enableCacheReplication "true"] [diskCachePerformanceLevel "BALANCED"] [flushToDiskOnStop "false"] [enableDiskOffload "false"] [replicationType "PUSH"] [diskCacheEntrySizeInMB "0"] [jndiName "' + jndiName +'"] [cacheSize "2000"] [diskCacheSizeInGB "0"] [pushFrequency "1"] [useListenerContext "false"] [diskCacheCleanupFrequency "0"] [diskCacheSizeInEntries "0"]]')
      AdminConfig.save()
      print " Object Cache: ",cacheName, " created with > JNDI: ", jndiName," ReplicationDomainName: ", cacheReplicationDomainName
    else:
      print " Object Cache: ",cacheName, " already exists"
  except:
    print " Object Cache: ",cacheName, " already exists. please verify"

# not working
def findBusDestination(busName, busDestinationtName):
  busDestinations = AdminTask.listSIBDestinations('[-bus ' + busName + ' ]')
  for busDestination in busDestinations.splitlines():
    print busDestination
    if(busDestination.find(busDestinationtName) > -1):
      return busDestination

def createQueue(queueName, jndiName, busName, queueDestinationName):
  try:
    AdminTask.createSIBJMSQueue(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ), '[-name ' + queueName + ' -jndiName ' + jndiName + ' -description  -deliveryMode Application -readAhead AsConnection -busName ' + busName + ' -queueName ' + queueDestinationName + ' -scopeToLocalQP false -producerBind false -producerPreferLocal true -gatherMessages false]')
    AdminConfig.save()
    print " Queue : ",queueName, " created with > JNDI: ", jndiName," busName: ", busName," queueDestinationName: ", queueDestinationName
  except:
    print " Queue : ",queueName, " already exists on the bus ", busName," please verify."

def createTopic(topicName, jndiName, busName, topicDestinationName):
  try:
    AdminTask.createSIBJMSTopic(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ), '[-name ' + topicName + ' -jndiName ' + jndiName + ' -description  -topicName  -deliveryMode Application -readAhead AsConnection -busName ' + busName + ' -topicSpace ' + topicDestinationName + ']')
    AdminConfig.save()
    print " Topic : ",topicName, " created with > JNDI: ", jndiName," busName: ", busName," topicDestinationName: ", topicDestinationName
  except:
    print " Topic : ",topicName, " already exists on the bus ", busName," please verify."

# Type - Queue or Topic
def createJMSConnectionFactory(type, cfName, jndiName, busName):
  try:
    jmscf = findConnectionFactory(cfName)
    if jmscf == None:
      jmsCF = AdminTask.createSIBJMSConnectionFactory(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ), '[-type ' + type + ' -name ' + cfName + ' -jndiName ' + jndiName + ' -busName ' + busName + ' -nonPersistentMapping ExpressNonPersistent -readAhead Default -tempQueueNamePrefix  -target  -targetType BusMember -targetSignificance Preferred -targetTransportChain  -providerEndPoints  -connectionProximity Bus -authDataAlias  -containerAuthAlias  -mappingAlias  -shareDataSourceWithCMP false -logMissingTransactionContext false -manageCachedHandles false -xaRecoveryAuthAlias  -persistentMapping ReliablePersistent -consumerDoesNotModifyPayloadAfterGet false -producerDoesNotModifyPayloadAfterSet false]')
      AdminConfig.save()
      print "", type,"Connection Factory: " ,cfName, " created with > JNDI: ", jndiName," busName: ", busName
    else:
      print "", type,"Connection Factory: " ,cfName, " already exists"  
  except:
    print "", type,"Connection Factory: " ,cfName, " already exists on the bus ", busName," please verify."

# Type - Queue or Topic
def createActivationSpec(type, apName, jndiName, busName, destinationJndiName):
  try:
    AdminTask.createSIBJMSActivationSpec(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ), '[-name ' + apName + ' -jndiName ' +jndiName+ ' -destinationJndiName ' + destinationJndiName + ' -description  -busName ' + busName + ' -clientId  -durableSubscriptionHome -destinationType javax.jms.'+type+' -messageSelector  -acknowledgeMode Auto-acknowledge -subscriptionName  -maxBatchSize 1 -maxConcurrency 10 -subscriptionDurability NonDurable -shareDurableSubscriptions InCluster -authenticationAlias  -readAhead Default -target  -targetType BusMember -targetSignificance Preferred -targetTransportChain  -providerEndPoints  -shareDataSourceWithCMP false -consumerDoesNotModifyPayloadAfterGet false -forwarderDoesNotModifyPayloadAfterSet false -alwaysActivateAllMDBs false -retryInterval 30 -autoStopSequentialMessageFailure 0 -failingMessageDelay 0]')
    AdminConfig.save()
    print "", type,"ActivationSpec: " ,apName, " created with > JNDI: ", jndiName," busName: ", busName
  except:
    print "", type,"ActivationSpec: " ,apName, " already exists on the bus ", busName," please verify."

def findConnectionFactory(cfName):
  cfs = AdminConfig.list('ConnectionFactory', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
  for cf in cfs.splitlines():
    if(cf.find(cfName) > -1):
      return cf

def modifyConnectionFactory(cfName, min, max):
  cf = findConnectionFactory(cfName)
  if not cf == None:
    cps = AdminConfig.list('ConnectionPool', cf).splitlines()
    AdminConfig.modify(cps[0], '[[maxConnections "'+max+'"] [purgePolicy "EntirePool"] [unusedTimeout "1800"] [minConnections "'+min+'"] [reapTime "180"] [agedTimeout "0"] [connectionTimeout "180"]]')
    AdminConfig.save()
    print " Connection Factory: ",cfName, " updated"
  else:
    print " Connection Factory: ",cfName, " not found"

# JAAS J2C
def createJ2CAlias(aliasName ,userName,password):
  try: 
    AdminTask.createAuthDataEntry('[ -alias ' +  aliasName + ' -user ' + userName + ' -password ' + password + ' -description  ]')
    AdminConfig.save()
    print "", aliasName," JAAS-J2C created with > userName: ", userName," password: ", password
  except:
    print "", aliasName," JAAS-J2C already exists. please verify."

def findDatasource(datasourceName):
  datasources = AdminConfig.list('DataSource', AdminConfig.getid( '/Cell:' + AdminControl.getCell() + '/'))
  for datasource in datasources.splitlines():
     if(datasource.find(datasourceName) > -1):
         return datasource

def createDataSource(providerName, friendlyName, jndiName, dbURL, j2cName, minConnections, maxConnections, dbName="", dbPort=""):
   try:
     ds = findDatasource(friendlyName)
     if ds == None:
       j2cResource = findJ2CResource(j2cName)
       strDSArgs = ""
       if providerName == "Oracle":
         strDSArgs = "[-name " + friendlyName + " -jndiName " + jndiName + " -dataStoreHelperClassName com.ibm.websphere.rsadapter.Oracle11gDataStoreHelper -containerManagedPersistence false -componentManagedAuthenticationAlias " + j2cResource + " -configureResourceProperties [[URL java.lang.String " + dbURL +"]]]"
       elif providerName == "Microsoft":
         strDSArgs = "[-name " + friendlyName + " -jndiName " + jndiName + " -dataStoreHelperClassName com.ibm.websphere.rsadapter.MicrosoftSQLServerDataStoreHelper -containerManagedPersistence false -componentManagedAuthenticationAlias " + j2cResource + " -configureResourceProperties [[databaseName java.lang.String " + dbName + "] [portNumber java.lang.Integer " + dbPort + "] [serverName java.lang.String " + dbURL + "]]]"
       newds = AdminTask.createDatasource(findJDBCProvider(providerName), strDSArgs)
       AdminConfig.modify(newds, '[[statementCacheSize "100"]]')
       connPool = AdminConfig.list('ConnectionPool', newds)
       AdminConfig.modify(connPool, '[[connectionTimeout "30"] [maxConnections "' + maxConnections + '"] [unusedTimeout "300"] [minConnections "' + minConnections +'"] [purgePolicy "EntirePool"] [agedTimeout "600"] [reapTime "30"]]')
       AdminConfig.save()
       print "",providerName,"DataSource ",friendlyName, " created with > JNDI: ", jndiName," dbURL: ", dbURL," j2cName: ", j2cName," minConnections: ", minConnections," maxConnections: ", maxConnections
     else:
       print "",providerName,"DataSource ",friendlyName, " already exists"
   except:
     print "",providerName,"DataSource ",friendlyName, " already exists. please verify."

def deleteDataSource(friendlyName):
  try:
    ds = findDatasource(friendlyName)
    if ds == None:
      AdminConfig.remove(ds)
      AdminConfig.save()
      print " DataSource ",friendlyName, " deleted."
    else:
      print " DataSource ",friendlyName, " not found"
  except:
    print " DataSource ",friendlyName, " not found. please verify."

def deleteJ2CAlias(aliasName):
  try:
    j2c = findJ2CResource(j2cName)
    print j2c
    if not j2c == None:
      AdminTask.deleteAuthDataEntry('[-alias localNode01/DEV_atlantis ]')
      print "",aliasName," JAAS J2C deleted."
    else:
      print "",aliasName," JAAS J2C not found."
  except:
    print "",aliasName," JAAS J2C not found. please verify."

def setJVMHeapSize(jvmName,nodeName,minHeap,maxHeap):
  try:
    print " Adjusting heap for JVM: ", jvmName
    AdminTask.setJVMProperties('[-serverName ' + jvmName +' -nodeName ' + nodeName + ' -verboseModeClass false -verboseModeGarbageCollection true -verboseModeJNI false -initialHeapSize ' + minHeap +' -maximumHeapSize ' + maxHeap +' -runHProf false -hprofArguments  -debugMode false -debugArgs "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=7777" -genericJvmArguments -executableJarFileName  -disableJIT false]')
    AdminConfig.save()
    print "", jvmName," JVM heap size adjusted to min:", minHeap, "maxHeap:",maxHeap
  except:
    print " Exception occurred while setting heapsize for JVM:- ",jvmName, " please verify."

def findActivationSpec(asName):
  activationSpecs = AdminTask.listSIBJMSActivationSpecs(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
  for as in activationSpecs.splitlines():
    if(as.find(asName) > -1):
      return as

def deleteActivationSpec(asName):
  as = findActivationSpec(asName)
  if not as== None:
    AdminTask.deleteSIBJMSActivationSpec(as)
    AdminConfig.save()
    print " ActivationSpec: ",asName, " deleted."
  else:
    print " ActivationSpec: ",asName, " not found"
 
def findQueue(qName):
  qs= AdminTask.listSIBJMSQueues(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
  for q in qs.splitlines():
    if(q.find(qName) > -1):
      return q

def deleteQueue(qName):
  q = findQueue(qName)
  if not q== None:
    AdminTask.deleteSIBJMSQueue(q)
    AdminConfig.save()
    print " Queue: ",qName, " deleted."
  else:
    print " Queue: ",qName, " not found"

def findTopic(tName):
  qs= AdminTask.listSIBJMSTopics(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
  for q in qs.splitlines():
    if(q.find(tName) > -1):
      return q

def deleteTopic(tName):
  t = findTopic(tName)
  if not t== None:
    AdminTask.deleteSIBJMSTopic(t)
    AdminConfig.save()
    print " Topic: ",tName, " deleted."
  else:
    print " Topic: ",tName, " not found"

# not working :(
def findJMSConnectionFactory(cfName):
  cfs= AdminTask.listSIBJMSConnectionFactories(AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
  print cfs
  for cf in cfs.splitlines():
    print cf
    if(cf.find(cfName) > -1):
      return cf

def deleteJMSConnectionFactory(cfName):
  cf = findConnectionFactory(cfName)
  if not cf== None:
    AdminTask.deleteSIBJMSConnectionFactory(cf)
    AdminConfig.save()
    print " JMS Connection Factory: ",cfName, " deleted."
  else:
    print " JMS Connection Factory: ",cfName, " not found"


#**Shared Library Subroutine(s)**

def findSharedLibrary(sharedLibName):
  if(not(sharedLibName=='')):
    sharedLibName = '-' + sharedLibName + '-'
    sll = AdminConfig.list('Library', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/' ))
    rtnVal = ''
    for sl in sll.splitlines():
      sl_n = sl[0:sl.find('(')]
      rtnVal = sl
      sl_n = '-' + sl_n + '-'
      if(sl_n == sharedLibName):
        break
      else:
        sl_n = ''
  return rtnVal
#end def

#def deleteSharedLibrary(sharedLibName):
  
#end def

#AdminConfig.create('Library', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/'), '[[nativePath ""] [name "eBizMyFaces"] [isolatedClassLoader true] [description ""] [classPath "/shared_data/libs/eBiz/MyFaces/myfaces-impl-1.1.7.jar  /shared_data/libs/eBiz/MyFaces/myfaces-api-1.1.7.jar  /shared_data/libs/eBiz/MyFaces/commons-lang-2.2.jar  /shared_data/libs/eBiz/MyFaces/jstl-1.1.0.jar  /shared_data/libs/eBiz/MyFaces/commons-beanutils-1.7.0.jar  /shared_data/libs/eBiz/MyFaces/commons-codec-1.3.jar  /shared_data/libs/eBiz/MyFaces/commons-collections-3.2.jar  /shared_data/libs/eBiz/MyFaces/commons-digester-1.7.jar  /shared_data/libs/eBiz/MyFaces/commons-el-1.0.jar  /shared_data/libs/eBiz/MyFaces/commons-logging-1.0.4.jar  /shared_data/libs/eBiz/MyFaces/log4j-1.2.12.jar"]]')
# [12/13/11 14:57:08:061 EST] Shared Libraries
#AdminConfig.list('Library', AdminConfig.getid( '/Cell:corp-w-mj19564Node01Cell/'))
# [12/13/11 14:58:53:576 EST] Shared Libraries > New
#AdminConfig.create('Library', AdminConfig.getid('/Cell:' + AdminControl.getCell() + '/'), '[[nativePath ""] [name "eBizMyFaces"] [isolatedClassLoader true] [description ""] [classPath "/shared_data/libs/eBiz/MyFaces/myfaces-impl-1.1.7.jar  /shared_data/libs/eBiz/MyFaces/myfaces-api-1.1.7.jar  /shared_data/libs/eBiz/MyFaces/commons-lang-2.2.jar  /shared_data/libs/eBiz/MyFaces/jstl-1.1.0.jar  /shared_data/libs/eBiz/MyFaces/commons-beanutils-1.7.0.jar  /shared_data/libs/eBiz/MyFaces/commons-codec-1.3.jar  /shared_data/libs/eBiz/MyFaces/commons-collections-3.2.jar  /shared_data/libs/eBiz/MyFaces/commons-digester-1.7.jar  /shared_data/libs/eBiz/MyFaces/commons-el-1.0.jar  /shared_data/libs/eBiz/MyFaces/commons-logging-1.0.4.jar  /shared_data/libs/eBiz/MyFaces/log4j-1.2.12.jar"]]')
# [12/13/11 14:58:55:248 EST] Shared Libraries > eBizMyFaces
#AdminConfig.save()


# ******* Main Block - Begin ******* #

print '\n *** Environment Setup configuration started. ***\n'

#Work Manager, Object Cache and Startup Bean
#Work Manager
#deleteWorkManager('<<WorkManager:Name=SampleWorkManager>>')
#createWorkManager('<<WorkManager:Name=SampleWorkManager>>', '<<WorkManager:JNDIName=wm/sample>>', '<<WorkManager:MinThreads=1>>', '<<WorkManager:MaxThreads=5>>', '<<WorkManager:Growable=fale>>', '<<WorkManager:WorkTimeout=0>')
#Examples
#deleteWorkManager('SampleWorkManager')
#createWorkManager('SampleWorkManager', 'wm/sample', '1', '5', 'false', '0')

#Object Cache
#deleteObjectCache('<<=sampleObjectCache>>')
#deleteCacheReplicationDomain('sampleCacheReplication')
#createObjectCache('sampleObjectCache', 'cache/sampleObjectCache', 'sampleCacheReplication')

# Modify (Enable / Disable) Startup Bean Service, Update Web Server Plug-in settings : Request Timeout
#modifyStartupBeanService('true')
#modifyWebServerPluginProperties('0')

#Bus, QCF, Queue, TCF, Topic
#Samplebus
#busName='samplebus'
#deleteBus(busName)
#createBus(busName)
#addBusMember(busName)
#deleteJMSConnectionFactory('SampleQueueConnectionFactory')
#createJMSConnectionFactory('Queue', 'SampleQueueConnectionFactory', 'jms/qcf/sample', busName)
#modifyConnectionFactory('SampleQueueConnectionFactory','10','30')

#createBusDestination(busName,'sampleqd','Queue')
#deleteQueue('SampleQueue')
#createQueue('SampleQueue', 'jms/q/sample', busName, 'sampleqd')
#deleteActivationSpec('SampleQueueActivationSpec')
#createActivationSpec('Queue', 'SampleQueueActivationSpec', 'eis/q/sample', busName, 'jms/q/sample')

#deleteJMSConnectionFactory('SampleTopicConnectionFactory')
#createJMSConnectionFactory('Topic', 'SampleTopicConnectionFactory', 'jms/tcf/sample', busName)
#modifyConnectionFactory('SampleTopicConnectionFactory','10','15')
#createBusDestination(busName,'sampletd','TopicSpace')
#deleteTopic('SampleTopic')
#createTopic('SampleTopic', 'jms/t/sample', busName, 'sampletd')
#deleteActivationSpec('SampleTopicActivationSpec')
#createActivationSpec('Topic', 'SampleTopicActivationSpec', 'eis/t/sample', busName, 'jms/t/sample')

#Oracle JDBC Provider
#deleteOracleJDBCProvider()
#createOracleJDBCProvider('<<Oracle Jar Location: Jar file path>>')
#Example
#createOracleJDBCProvider('c:/libs/ojdbc6.jar')

#Memory update
#setJVMHeapSize('server1',AdminControl.getNode(),'500','1500')

#JAAS J2C and Datasource
#deleteJ2CAlias('<<JAAS J2C:Name>>')
#createJ2CAlias('<<JAAS J2C:Name>>' ,'<<JAAS J2C:Username>>','<<JAAS J2C:Password>>')
#deleteDataSource('<<Datasource:Name>>')
#createDataSource('Oracle', '<<Datasource:Name>>', '<<Datasource:JNDIName>>', '<<Datasource:DB URL>>', '<<JAAS J2C:Name>>', '<<Datasource:Min Conns>>', '<<Datasource:Max Conns>>')

#Examples
#deleteJ2CAlias('Sample_JAAS_J2C')
#createJ2CAlias('Sample_JAAS_J2C' ,'sample','sample')
#deleteDataSource('Sample_Datasource')
#createDataSource('Oracle', 'Sample_Datasource', 'jdbc/sample', 'jdbc:oracle:thin:@server_name:port_no:instance_name', 'Sample_JAAS_J2C', '10', '20')



print '\n *** Environment Setup configuration completed. ***'

# ******* Main Block - End ******* #

