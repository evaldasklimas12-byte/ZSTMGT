table 72401 "ZST Setup Package"
{
    Caption = 'Setup Package';
    DataClassification = CustomerContent;
    LookupPageId = "ZST Package Registry List";
    DrillDownPageId = "ZST Package Registry List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            Editable = false;
        }
        field(2; "Scenario"; Enum "ZST Setup Scenario")
        {
            Caption = 'Scenario';
            Editable = false;
        }
        field(3; "Path"; Text[2048])
        {
            Caption = 'Package Path';
            Editable = false;
        }
        field(4; "Version"; Text[2048])
        {
            Caption = 'Version';
            Editable = false;
        }
        field(5; "Processing Order"; Integer)
        {
            Caption = 'Processing Order';
            Editable = false;
        }
        field(6; "Active"; Boolean)
        {
            Caption = 'Active';
        }
    }

    keys
    {
        key(PK; "Code", Scenario)
        {
            Clustered = true;
        }
        key(Order; "Scenario", "Processing Order")
        {
        }
    }
}