global without sharing class RollupFlowFullRecalcDispatcher {
  private RollupFlowFullRecalcDispatcher() {
    // Only used for invocable
  }

  global class FlowInput {
    @InvocableVariable(label='Comma-separated list of API Names of the Rollup__mdt Records you want to run')
    global String rollupDeveloperNames;
  }

  @InvocableMethod(category='Rollups' label='Full Recalc CMDT-driven Invocable')
  public static void performFullRecalcRollups(List<FlowInput> inputs) {
    List<Rollup__mdt> localRollupMetadata = Rollup.getMetadataFromCache(Rollup__mdt.SObjectType);
    List<Rollup__mdt> selectedRollupMetadata = new List<Rollup__mdt>();
    Set<String> rollupDeveloperNames = new Set<String>();
    for (FlowInput input : inputs) {
      List<String> splitListOfApiNames = input.rollupDeveloperNames.split(',');
      for (String apiName : splitListOfApiNames) {
        rollupDeveloperNames.add(apiName.trim());
      }
    }
    for (Rollup__mdt rollup : localRollupMetadata) {
      if (rollupDeveloperNames.contains(rollup.DeveloperName)) {
        selectedRollupMetadata.add(rollup);
      }
    }
    if (selectedRollupMetadata.isEmpty() == false) {
      Rollup.performBulkFullRecalc(selectedRollupMetadata, Rollup.InvocationPoint.FROM_SCHEDULED_FLOW.name());
    }
  }
}
