trigger ContentVersionTrigger on ContentVersion (after insert) {

    
    if(Trigger.isAfter && Trigger.isInsert){
        ContentVersionHandler.updateContactAccountWebsite(Trigger.new);
    }
}