@isTest
private class RollupFlowBulkProcessorTests {
  @TestSetup
  static void setup() {
    upsert new RollupSettings__c(IsEnabled__c = true);
  }

  @isTest
  static void shouldNotProcessIfNoRecords() {
    List<Rollup.FlowOutput> outputs = RollupFlowBulkProcessor.addRollup(new List<RollupFlowBulkProcessor.FlowInput>{ new RollupFlowBulkProcessor.FlowInput() });

    System.assertEquals('No records', outputs[0].message);
  }

  @isTest
  static void shouldAddToRollupsIfCMDTPresent() {
    RollupFlowBulkProcessor.FlowInput input = new RollupFlowBulkProcessor.FlowInput();
    input.recordsToRollup = new List<SObject>{ new Contact() };
    input.rollupContext = 'INSERT';

    RollupFlowBulkProcessor.testMetadata = new Rollup__mdt(RollupOperation__c = 'SUM', CalcItem__c = 'Contact', LookupObject__c = 'Account');

    List<Rollup.FlowOutput> outputs = RollupFlowBulkProcessor.addRollup(new List<RollupFlowBulkProcessor.FlowInput>{ input });

    System.assertNotEquals(true, outputs.isEmpty(), 'Should have passed back data from inputs');
    for (Rollup.FlowOutput output : outputs) {
      System.assertEquals(true, outputs[0].isSuccess, 'Should not error when adding deferred flow rollup');
    }
    System.assertNotEquals(true, Rollup.FLOW_ROLLUPS.isEmpty(), 'Deferred rollup should be kept in buffer');
  }

  @isTest
  static void shouldProcessDeferredFlowRollups() {
    Account acc = new Account(Name = 'RollupFlowBulkProcessorTests');
    insert acc;

    RollupFlowBulkProcessor.FlowInput input = new RollupFlowBulkProcessor.FlowInput();
    input.recordsToRollup = new List<SObject>{ new Opportunity(Amount = 5, AccountId = acc.Id) };
    input.rollupContext = 'INSERT';

    RollupFlowBulkProcessor.testMetadata = new Rollup__mdt(
      RollupOperation__c = 'SUM',
      CalcItem__c = 'Opportunity',
      LookupObject__c = 'Account',
      RollupFieldOnCalcItem__c = 'Amount',
      LookupFieldOnCalcItem__c = 'AccountId',
      LookupFieldOnLookupObject__c = 'Id',
      RollupFieldOnLookupObject__c = 'AnnualRevenue'
    );

    RollupFlowBulkProcessor.addRollup(new List<RollupFlowBulkProcessor.FlowInput>{ input });

    Test.startTest();
    RollupFlowBulkSaver.processDeferredRollups();
    Test.stopTest();

    acc = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
    System.assertEquals(5, acc.AnnualRevenue);
    System.assertEquals(0, Rollup.FLOW_ROLLUPS.size(), 'Flow rollup buffer should have been flushed!');
  }

  @isTest
  static void shouldNotReportSuccessForInnerFailure() {
    RollupFlowBulkProcessor.FlowInput input = new RollupFlowBulkProcessor.FlowInput();
    input.recordsToRollup = new List<SObject>{ new Opportunity(Amount = 5) };
    input.rollupContext = 'INSERT';

    RollupFlowBulkProcessor.testMetadata = new Rollup__mdt(
      RollupOperation__c = 'SUM',
      CalcItem__c = 'Opportunity',
      LookupObject__c = 'Account',
      RollupFieldOnCalcItem__c = 'Kaffufle', // this obviously doesn't exist
      LookupFieldOnCalcItem__c = 'AccountId',
      LookupFieldOnLookupObject__c = 'Id',
      RollupFieldOnLookupObject__c = 'AnnualRevenue'
    );

    List<Rollup.FlowOutput> outputs = RollupFlowBulkProcessor.addRollup(new List<RollupFlowBulkProcessor.FlowInput>{ input });

    System.assertEquals(false, outputs[0].isSuccess);
  }
}