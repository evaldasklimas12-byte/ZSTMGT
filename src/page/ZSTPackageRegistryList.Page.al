page 72403 "ZST Package Registry List"
{
    ApplicationArea = All;
    Caption = 'Package Registry List';
    PageType = List;
    SourceTable = "ZST Setup Package";
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the code for the package registry.';
                }
                field("Scenario"; Rec."Scenario")
                {
                    ToolTip = 'Specifies the setup scenario this package belongs to.';
                }
                field("Processing Order"; Rec."Processing Order")
                {
                    ToolTip = 'Specifies the order in which the packages are processed.';
                }
                field("Version"; Rec."Version")
                {
                    ToolTip = 'Specifies the version of the package.';
                }
                field("Path"; Rec."Path")
                {
                    ToolTip = 'Specifies the path or URL where the package is located.';
                }
                field("Active"; Rec."Active")
                {
                    ToolTip = 'Specifies if the package registry entry is active.';
                }
            }
        }
    }
}