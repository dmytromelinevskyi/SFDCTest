/**
 * Created by dmeli on 31.07.19.
 */

public class ListOfCandidates {
    private final Vacancy__c vac;

    public ListOfCandidates(ApexPages.StandardController stdController) {
        this.vac = (Vacancy__c) stdController.getRecord();
    }

    List<CandidateWrapper> candidateList = new List<CandidateWrapper>();
    List<Candidate__c> selectedCandidates = new List<Candidate__c>();
    List<VacancyCandidateAssociation__c> vacancyCandidateAssociations = new List<VacancyCandidateAssociation__c>();

    private List<Candidate__c> getCandidates() {
        return [SELECT FirstName__c, Status__c, Name, (SELECT Vacancy__c, Candidate__c FROM VacancyCandidateAssociations__r WHERE Vacancy__c = :vac.Id) FROM Candidate__c WHERE Status__c = 'Validated by HR'];
    }

    public void onLoad() {
        Vacancy__c vacancyToCheck = [SELECT Id,Name, Status__c FROM Vacancy__c WHERE Id = :vac.Id];
        if (vacancyToCheck.Status__c == 'In-Process') {
            for (Candidate__c c : getCandidates()) {
                if (c.VacancyCandidateAssociations__r.size() < 1) {
                    candidateList.add(new CandidateWrapper(c));
                }
            }
        }
    }

    public List<CandidateWrapper> getCandidatesToAdd() {
        return candidateList;
    }

    public PageReference getSelected() {
        selectedCandidates.clear();
        for (CandidateWrapper canWrapper : candidateList) {
            if (canWrapper.selected == true) {
                selectedCandidates.add(canWrapper.can);
            }
        }
        return null;
    }

    public List<Candidate__c> getSelectedCandidates() {
        if (selectedCandidates.size() > 0) {
            return selectedCandidates;
        } else {
            return null;
        }
    }

    public class CandidateWrapper {
        public Candidate__c can { get; set; }
        public Boolean selected { get; set; }
        public CandidateWrapper(Candidate__c c) {
            can = c;
            selected = false;
        }
    }

    public void addCandidates() {
        if (selectedCandidates.size() > 0) {
            for (Candidate__c currentCandidate : selectedCandidates) {
                VacancyCandidateAssociation__c vacCan = new VacancyCandidateAssociation__c();
                vacCan.Vacancy__c = vac.Id;
                vacCan.Candidate__c = currentCandidate.Id;
                vacancyCandidateAssociations.add(vacCan);
            }
            insert vacancyCandidateAssociations;
            vac.Status__c = 'In-Process';
            update vac;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'One or more candidate was updated'));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select candidate'));
        }
    }
}