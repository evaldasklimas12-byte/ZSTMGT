page 72400 "ZST Management Setup"
{
    ApplicationArea = All;
    Caption = 'ZST Management Setup';
    PageType = Card;
    UsageCategory = Administration;
    SourceTable = "ZST Setup Management Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                group(AzureSettings)
                {
                    Caption = 'Azure Settings';

                    field("Storage Account Name"; Rec."Storage Account Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Azure Storage account name used to access blobs.';
                    }

                    field("Container Name"; Rec."Container Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Name of the Azure blob container that holds .rapidstart files.';
                    }


                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Wizard)
            {
                Caption = 'Config. Package Wizard';
                Image = Import;
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ToolTip = 'Run the Rapid Starter initialization process.';
                trigger OnAction()
                var
                    ZSTPackageRegistry: Record "ZST Setup Package";
                    ZSTPackageRegistryMgt: Codeunit "ZST Package Registry Mgt.";
                    ZSTSetupWizard: Page "ZST Setup Wizard";
                begin
                    if ZSTPackageRegistry.IsEmpty() then
                        ZSTPackageRegistryMgt.FillPackageRegistryFromAzureFile();
                    ZSTSetupWizard.Run();
                end;
            }

            action(UpdateSASToken)
            {
                Caption = 'Update SAS Token';
                Image = EncryptionKeys;
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ToolTip = 'Update the Azure Access Key or SAS Token stored securely for this company.';
                trigger OnAction()
                var
                    ZSTUpdateSASToken: Page "ZST Update SAS Token";
                begin
                    ZSTUpdateSASToken.RunModal();
                end;
            }
        }
    }

}
