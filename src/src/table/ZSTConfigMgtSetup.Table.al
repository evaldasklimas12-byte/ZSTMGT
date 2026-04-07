table 72400 "ZST Setup Management Setup"
{
    Caption = 'Setup Management Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            NotBlank = true;
        }

        field(10; "Storage Account Name"; Text[100])
        {
            Caption = 'Storage Account Name';
        }

        field(11; "Container Name"; Text[100])
        {
            Caption = 'Container Name';
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}