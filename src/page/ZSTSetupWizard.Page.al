page 72401 "ZST Setup Wizard"
{
    PageType = NavigatePage;
    Caption = 'Configuration Setup Wizard';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                Visible = Step = 1;
                Caption = 'Welcome';
                group(WelcomeTitle)
                {
                    Caption = 'Welcome to Zest Configuration Management Setup';
                    InstructionalText = 'This wizard helps you initialize your company by importing configuration packages from Azure Blob Storage.';
                }
            }

            group(Step2)
            {
                Visible = Step = 2;
                Caption = 'Select Setup Scenario';
                group(ScenarioSelection)
                {
                    Caption = 'Please select what scenario you want to import';
                    field(Scenario; ScenarioFilter)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the configuration scenario you want to deploy, such as Demo, New, or Test data.';
                        Caption = 'Setup Scenario';
                    }
                }
            }

            group(Step3)
            {
                Visible = Step = 3;
                Caption = 'Import Results';
                group(ResultsTitle)
                {
                    Caption = 'Import Results';
                    InstructionalText = 'Review the status of the packages imported from Azure. Click Next to apply the data to your database.';
                }
                field(ImportedPackages; PackageCodesDisplay)
                {
                    ApplicationArea = All;
                    ToolTip = 'Displays a list of configuration package codes that were successfully imported.';
                    Caption = 'Imported Successfully';
                    MultiLine = true;
                    Editable = false;
                    Style = Favorable;
                }
                field(ImportErrors; ErrorLogs)
                {
                    ApplicationArea = All;
                    Caption = 'Skipped or Errors';
                    ToolTip = 'Displays information about packages that were not imported.';
                    MultiLine = true;
                    Editable = false;
                    Style = Unfavorable;
                }
            }

            group(Step4)
            {
                Visible = Step = 4;
                Caption = 'All Done';
                group(FinishTitle)
                {
                    Caption = 'Configuration Complete';
                    InstructionalText = 'The configuration data has been applied to your database. Review the results below.';
                }
                field(AppliedResults; ApplyResults)
                {
                    ApplicationArea = All;
                    Caption = 'Application Results';
                    Style = Favorable;
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Displays the success or failure status for each package applied to the database.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                Enabled = (Step > 1) and (Step < 4);
                ApplicationArea = All;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction()
                begin
                    Step -= 1;
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                Visible = Step < 4;
                ApplicationArea = All;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction()
                var
                    ZSTImportMgt: Codeunit "ZST Import Mgt.";
                    ConfirmApplyQst: Label 'Are you sure you want to apply the imported configuration packages to the database?';
                begin
                    case Step of
                        2:
                            begin
                                ImportConfigurationPackages();
                                Step := 3;
                            end;
                        3:
                            begin
                                if PackageCodesFilter <> '' then
                                    if Confirm(ConfirmApplyQst, true) then
                                        ApplyResults := ZSTImportMgt.ApplyPackagesFromFilter(PackageCodesFilter);

                                Step := 4;
                            end;
                        else
                            Step += 1;
                    end;
                end;
            }

            action(Finish)
            {
                Caption = 'Finish';
                ApplicationArea = All;
                Visible = Step = 4;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        Step: Integer;
        ScenarioFilter: Enum "ZST Setup Scenario";
        PackageCodesDisplay: Text;
        PackageCodesFilter: Text;
        ErrorLogs: Text;
        ApplyResults: Text;

    trigger OnOpenPage()
    begin
        Step := 1;
    end;

    local procedure ImportConfigurationPackages()
    var
        ZSTPackageRegistry: Record "ZST Setup Package";
        ZSTImportMgt: Codeunit "ZST Import Mgt.";
        ResultMsg: Text;
        ConfigPackageCode: Text;
        SuccessPrefix: Text;
    begin
        PackageCodesDisplay := '';
        PackageCodesFilter := '';
        ErrorLogs := '';

        SuccessPrefix := ZSTImportMgt.GetSuccessPrefix();

        ZSTPackageRegistry.SetRange(Scenario, ScenarioFilter);
        ZSTPackageRegistry.SetRange(Active, true);
        ZSTPackageRegistry.SetCurrentKey(Scenario, "Processing Order");

        if ZSTPackageRegistry.FindSet() then
            repeat
                ResultMsg := ZSTImportMgt.ImportPackageFromRegistry(ZSTPackageRegistry);

                if ResultMsg.StartsWith(SuccessPrefix) then begin
                    ConfigPackageCode := ResultMsg.Replace(SuccessPrefix, '');
                    PackageCodesDisplay += ConfigPackageCode + '\';

                    if PackageCodesFilter <> '' then
                        PackageCodesFilter += '|';
                    PackageCodesFilter += ConfigPackageCode;
                end else
                    ErrorLogs += ResultMsg + '\';
            until ZSTPackageRegistry.Next() = 0;
    end;
}