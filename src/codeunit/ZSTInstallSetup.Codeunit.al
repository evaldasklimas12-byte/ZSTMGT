codeunit 72402 "ZST Install Setup"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ZSTSetupInitialization: Codeunit "ZST Setup Initialization";
    begin
        ZSTSetupInitialization.InitializeSetup();
        // TaskScheduler.CreateTask(Codeunit::"ZST Setup Initialization", 0, true, CompanyName(), CurrentDateTime());
    end;
    
}
