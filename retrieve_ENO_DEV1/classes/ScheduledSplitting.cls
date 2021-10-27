/**
 * Created by amacari on 6/24/2021.
 */

global with sharing class ScheduledSplitting implements Schedulable {
    global void execute(SchedulableContext SC) {
        SplittingPayments.SplitPayments();
    }
}