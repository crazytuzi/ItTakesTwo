
UCLASS(Config = Editor)
class UCapabilityAttributeDebugSystem : UHazeCapabilityComponentAttributeDebugSystem
{
    UFUNCTION()
    FString MakeActionStateString()const
    {
        FString Text = "";
        TArray<FHazeBBActionStateParams> Params;
        GetAttributeStates(Params);
        if(Params.Num() <= 0)
        {
            Text = "<Grey>No Values</>";
            return Text;
        }

        for(auto Value : Params)
        {
            Text += Value.Name.ToString();
            Text += " | ";

            if(Value.State == EHazeActionState::Active)
                Text += "<Green>";
            else
                Text += "<Red>";

            Text += Debug::GetEnumDisplayName("EHazeActionState", Value.State);
            Text += "</>";
            Text += "\n";
        }
        return Text;
    }

    UFUNCTION()
    FString MakeValueString()const
    {
        FString Text = "";
        TArray<FHazeBBValueParams> Params;
        GetAttributeValues(Params);
        if(Params.Num() <= 0)
        {
            Text = "<Grey>No Values</>";
            return Text;
        }

        for(auto Value : Params)
        {
            Text += Value.Name.ToString();
            Text += " | ";

            Text += "<Grey>";
            Text += Value.Value;
            Text += "</>";

            Text += "\n";
        }
        return Text;
    }

    UFUNCTION()
    FString MakeVectorString()const
    {
        FString Text = "";
        TArray<FHazeBBVectorParams> Params;
        GetAttributeVectors(Params);
        if(Params.Num() <= 0)
        {
            Text = "<Grey>No Values</>";
            return Text;
        }

        for(auto Value : Params)
        {
            Text += Value.Name.ToString();
            Text += " | ";

            Text += Value.Vector.ToColorString();

            Text += "\n";
        }
        return Text;
    }

    UFUNCTION()
    FString MakeObjectString()const
    {
        FString Text = "";
        TArray<FHazeBBObjectParams> Params;
        GetAttributeObjects(Params);
        if(Params.Num() <= 0)
        {
            Text = "<Grey>No Values</>";
            return Text;
        }

        for(auto Value : Params)
        {
            Text += Value.Name.ToString();
            Text += " | ";

            if(Value.Object == nullptr)
            {
                Text += "<Red>";
                Text += "nullptr";
            }
            else
            {
                Text += "<Grey>";
                Text += Value.Object.GetName();
            }
                
            Text += "</>";
            Text += "\n";
        }
        return Text;
    }

    UFUNCTION()
    FString MakeNumberString()const
    {
        FString Text = "";
        TArray<FHazeBBNumberParams> Params;
        GetAttributeNumbers(Params);
        if(Params.Num() <= 0)
        {
            Text = "<Grey>No Values</>";
            return Text;
        }

        for(auto Value : Params)
        {
            Text += Value.Name.ToString();
            Text += " | ";

            Text += "<Grey>";
            Text += Value.Number;
            Text += "</>";

            Text += "\n";
        }
        return Text;
    }
}