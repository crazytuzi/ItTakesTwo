
enum ECapabilitySearchFilterCharType
{
	None,
	Any,
	Exclude,
}

class UCapabilityDebugListWidget : UUserWidget
{
	TArray<FString> AnyValidStrings;
	TArray<FString> RequiredStrings;
	TArray<FString> ExcludedStrings;

	private FString InteralStoredFilter = "";
	bool bIsDirrty = false;

	UFUNCTION()
	void MakeSearchFilter(FString FilterFieldText)
	{
		FString LowerFilterFieldText = FilterFieldText.ToLower();
		if(String::EqualEqual_StriStri(LowerFilterFieldText, InteralStoredFilter))
			return;

		// changes will be made. This is consumed in the debugsystem so the confiq might get saved
		bIsDirrty = true;

		const float ReservAmount = 30;
		AnyValidStrings.Reset(ReservAmount);
		RequiredStrings.Reset(ReservAmount);
		ExcludedStrings.Reset(ReservAmount);

		InteralStoredFilter = LowerFilterFieldText;	
		TArray<FString> FoundStrings = String::ParseIntoArray(LowerFilterFieldText, " ", false);
		ECapabilitySearchFilterCharType NextStringType = ECapabilitySearchFilterCharType::None;
		for(const FString& StringIndex : FoundStrings)
		{
			if(String::EqualEqual_StriStri(StringIndex, ""))
				continue;

			FString StringToAdd = "";
		
			if(String::StartsWith(StringIndex, "-"))
			{
				NextStringType = ECapabilitySearchFilterCharType::Exclude;
				StringToAdd = String::RightChop(StringIndex, 1);
			}
			else if(String::StartsWith(StringIndex, "|"))
			{
				NextStringType = ECapabilitySearchFilterCharType::Any;
				StringToAdd = String::RightChop(StringIndex, 1);
			}
			// The capability should include this
			else
			{
				StringToAdd = StringIndex;
			}

			// If we found the string this frame, add it with the type,
			// else the type will be save to the next word allowing for whitespace use
			if(StringToAdd != "")
			{
				switch(NextStringType)
				{
					case ECapabilitySearchFilterCharType::Any:
						AnyValidStrings.Add(StringToAdd);
						break;
					case ECapabilitySearchFilterCharType::Exclude:
						ExcludedStrings.Add(StringToAdd);
						break;
					default:
						RequiredStrings.Add(StringToAdd);
						break;
				}

				NextStringType = ECapabilitySearchFilterCharType::None;
			}
		}
	}

	FString GetFilterFieldText()const
	{
		return InteralStoredFilter;
	}

	UFUNCTION(BlueprintPure)
	bool IsUClassValidToCurrentFiler(UObject Object) const
	{
		if(Object == nullptr)
			return false;

		const FString CompareString = System::GetDisplayName(Object.Class);
		for(const FString& ExcludeString : ExcludedStrings)
		{
			if(String::Contains(CompareString, ExcludeString))
				return false;
		}

		for(const FString& AnyValidString : AnyValidStrings)
		{
			if(String::Contains(CompareString, AnyValidString))
				return true;
		}

		for(const FString& RequiredString : RequiredStrings)
		{
			if(!String::Contains(CompareString, RequiredString))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasFilters()const
	{
		if(AnyValidStrings.Num() > 0 )
			return true;

		if(RequiredStrings.Num() > 0 )
			return true;

		if(ExcludedStrings.Num() > 0 )
			return true;

		return false;
	}
}