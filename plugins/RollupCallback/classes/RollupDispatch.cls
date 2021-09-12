public class RollupDispatch implements RollupSObjectUpdater.IDispatcher {
  @TestVisible
  private static Boolean wasCalled = false;
  @TestVisible
  private static String platformEventOverride;

  private static String PLATFORM_EVENT_BOOLEAN_STRING {
    get {
      if (PLATFORM_EVENT_BOOLEAN_STRING == null && platformEventOverride != null) {
        PLATFORM_EVENT_BOOLEAN_STRING = platformEventOverride;
      } else if (PLATFORM_EVENT_BOOLEAN_STRING == null) {
        String potentialBooleanString = RollupPluginParameter__mdt.getInstance('ShouldFirePlatformEvent')?.Value__c;
        PLATFORM_EVENT_BOOLEAN_STRING = potentialBooleanString == null ? String.valueOf(false) : potentialBooleanString;
      }
      return PLATFORM_EVENT_BOOLEAN_STRING;
    }
    set;
  }

  public void dispatch(List<SObject> records) {
    if (Boolean.valueOf(PLATFORM_EVENT_BOOLEAN_STRING)) {
      wasCalled = true;
      List<String> updatedRecordIds = new List<String>();
      for (SObject record : records) {
        updatedRecordIds.add(record.Id);
      }

      RollupCallbackEvent__e callbackEvent = new RollupCallbackEvent__e(
        RecordIds__c = String.join(updatedRecordIds, ',')
      );
      EventBus.publish(callbackEvent);
    }
  }
}