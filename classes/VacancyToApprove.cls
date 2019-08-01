public class VacancyToApprove {

    List<VacancyCandidateWrapper> vacancyCandidateList = new List<VacancyCandidateWrapper>();
    List<VacancyCandidateAssociation__c> selectedVacancyCandidate = new List<VacancyCandidateAssociation__c>();

    private List<VacancyCandidateAssociation__c> getVacanciesWithCandidates() {
        return [SELECT Vacancy__c, Candidate__c FROM VacancyCandidateAssociation__c WHERE Vacancy__r.Status__c = 'In-Process' AND Candidate__r.Status__c = 'Validated by HR'];
    }

    public void onLoad() {
        for (VacancyCandidateAssociation__c vc : getVacanciesWithCandidates()) {
            vacancyCandidateList.add(new VacancyCandidateWrapper(vc));
        }
    }

    public List<VacancyCandidateWrapper> getVacancyToApprove() {
        return vacancyCandidateList;
    }

    public PageReference getSelected() {
        selectedVacancyCandidate.clear();
        for (VacancyCandidateWrapper vacCanWrapper : vacancyCandidateList) {
            if (vacCanWrapper.selected == true) {
                selectedVacancyCandidate.add(vacCanWrapper.vacCan);
            }
        }
        return null;
    }

    public List<VacancyCandidateAssociation__c> GetSelectedVacanciesWithCandidates() {
        if (selectedVacancyCandidate.size() > 0) {
            return selectedVacancyCandidate;
        } else {
            return null;
        }
    }

    public class VacancyCandidateWrapper {
        public VacancyCandidateAssociation__c vacCan { get; set; }
        public Boolean selected { get; set; }
        public VacancyCandidateWrapper(VacancyCandidateAssociation__c vc) {
            vacCan = vc;
            selected = false;
        }
    }

    public void approveCandidates() {
        if (selectedVacancyCandidate.size() > 0) {
            Set<VacancyCandidateAssociation__c> vacanciesWithNoEqualCandidates = new Set<VacancyCandidateAssociation__c>();
            for (Integer i = 0; i < selectedVacancyCandidate.size(); i++) {
                if (selectedVacancyCandidate.size() > 1) {
                    for (Integer k = i + 1; k < selectedVacancyCandidate.size(); k++) {
                        if (selectedVacancyCandidate[i].Candidate__c == selectedVacancyCandidate[k].Candidate__c) {
                            vacanciesWithNoEqualCandidates = null;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You selected 2 vacancies with one candidate. Please select ONLY one vacancy with one candidate'));
                        } else {
                            if (vacanciesWithNoEqualCandidates != null) {
                                vacanciesWithNoEqualCandidates.add(selectedVacancyCandidate[i]);
                                vacanciesWithNoEqualCandidates.add(selectedVacancyCandidate[k]);
                            }
                        }
                    }
                } else {
                    vacanciesWithNoEqualCandidates.add(selectedVacancyCandidate[i]);
                }
            }
            if (vacanciesWithNoEqualCandidates != null) {
                List<Vacancy__c> vacanciesToUpdate = new List<Vacancy__c>();
                List<Candidate__c> candidatesToUpdate = new List<Candidate__c>();
                for (VacancyCandidateAssociation__c vacancyCandidateToApprove : vacanciesWithNoEqualCandidates) {
                    Vacancy__c approvedVacancy = [SELECT Id,Name,Status__c FROM Vacancy__c WHERE Id = :vacancyCandidateToApprove.Vacancy__c];
                    Candidate__c approvedCandidate = [SELECT Id,Name,Status__c FROM Candidate__c WHERE Id = :vacancyCandidateToApprove.Candidate__c];
                    approvedVacancy.Status__c = 'Closed';
                    vacanciesToUpdate.add(approvedVacancy);
                    approvedCandidate.Status__c = 'Hired';
                    candidatesToUpdate.add(approvedCandidate);
                    List<VacancyCandidateAssociation__c> vacanciesCandidatesToDelete = [SELECT Candidate__c, Vacancy__c, Id FROM VacancyCandidateAssociation__c WHERE Candidate__c = :approvedCandidate.Id AND Id != :vacancyCandidateToApprove.Id];
                    delete vacanciesCandidatesToDelete;
                }
                update vacanciesToUpdate;
                update candidatesToUpdate;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'One or more record was updated'));
            }
        }
    }

    public void rejectCandidates() {
        if (selectedVacancyCandidate.size() > 0) {
            for (VacancyCandidateAssociation__c rejectedVacancyCandidates : selectedVacancyCandidate) {
                Candidate__c rejectedCandidate = [SELECT Id, Name, Status__c FROM Candidate__c WHERE Id = :rejectedVacancyCandidates.Candidate__c];
                Vacancy__c updatedVacancy = [SELECT Id, Name, Status__c FROM Vacancy__c WHERE Id = :rejectedVacancyCandidates.Vacancy__c];
                rejectedCandidate.Status__c = 'Disqualified';
                updatedVacancy.Status__c = 'In-Process';
                update rejectedCandidate;
                update updatedVacancy;
                delete rejectedVacancyCandidates;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'All selected candidates was rejected'));
        }
    }

    public void cancelVacancies() {
        if (selectedVacancyCandidate.size() > 0) {
            for (VacancyCandidateAssociation__c cancelledVacancyCandidates : selectedVacancyCandidate) {
                Vacancy__c cancelledVacancy = [SELECT Id, Name, Status__c FROM Vacancy__c WHERE Id = :cancelledVacancyCandidates.Vacancy__c];
                cancelledVacancy.Status__c = 'Cancelled';
                update cancelledVacancy;
                delete cancelledVacancyCandidates;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'All selected vacancies was cancelled'));
        }
    }
}
