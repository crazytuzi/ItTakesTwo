
struct FKeyableKey
{
	UPROPERTY(EditFixedSize)
	TArray<FTransform> ComponentTransforms;
};

/**
 * An actor that can be keyed to several positions and lerped
 * between those dynamically.
 */
UCLASS(Meta = (AutoCollapseCategories = "KeyedData"))
class AKeyableMovingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// Amount of keys to specify for the animation
	UPROPERTY(Category = "Keys")
	int KeyCount = 2;

	// Time positions for all the keys
	UPROPERTY(EditInstanceOnly, Category = "Keys", EditFixedSize)
	TArray<float> KeyTimes;
	
	// Currently active key index
	UPROPERTY(EditInstanceOnly, Category = "Key Editing")
	int SelectedKey = 0;

	// Scrub mode for displaying the movement
	UPROPERTY(EditInstanceOnly, Category = "Key Editing", Meta = (InlineEditConditionToggle))
	bool bScrubKeys = false;

	UPROPERTY(EditInstanceOnly, Category = "Key Editing", Meta = (EditCondition = "bScrubKeys", ClampMin = "0.0", ClampMax = "1.0"))
	float ScrubTime = 0.f;

	// Raw positioning data for the keys
	UPROPERTY(EditInstanceOnly, Category = "Keyed Data", EditFixedSize)
	TArray<FKeyableKey> Keys;

	// Override this event to specify which components can be keyed
	UFUNCTION(BlueprintEvent)
	void GetKeyableComponents(TArray<USceneComponent>& OutComponents)
	{
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<USceneComponent> Comps;
		GetKeyableComponents(Comps);

		KeyTimes.SetNumZeroed(KeyCount);
		Keys.SetNum(KeyCount);

		for (int i = 0; i < KeyCount; ++i)
			Keys[i].ComponentTransforms.SetNum(Comps.Num());

		if (bScrubKeys)
			MoveComponentsToTime(ScrubTime * GetTotalDuration());
	}

	UFUNCTION(BlueprintPure)
	float GetTotalDuration()
	{
		return KeyTimes.Last();
	}

	UFUNCTION()
	void MoveComponentsToTime(float Time)
	{
		TArray<USceneComponent> Comps;
		GetKeyableComponents(Comps);

		for (int i = 1; i < KeyCount; ++i)
		{
			FKeyableKey& PrevKey = Keys[i-1];
			FKeyableKey& NextKey = Keys[i];

			float KeyStart = KeyTimes[i-1];
			float KeyEnd = KeyTimes[i];

			if (KeyStart > Time)
				continue;
			if (KeyEnd < Time)
				continue;

			float KeyDuration = KeyEnd - KeyStart;
			float KeyAlpha = FMath::Clamp((Time - KeyStart) / KeyDuration, 0.f, 1.f);

			for (int c = 0, CompCount = Comps.Num(); c < CompCount; ++c)
			{
				FTransform CompTransform = PrevKey.ComponentTransforms[c];
				CompTransform.BlendWith(NextKey.ComponentTransforms[c], KeyAlpha);

				Comps[c].WorldTransform = CompTransform * ActorTransform;
			}

			break;
		}
	}

	// Move the components as displayed to the positions stored inside the selected key index
	UFUNCTION(CallInEditor, Category = "Key Editing")
	void Editor_MoveComponentsToSelectedKey()
	{
		if (SelectedKey >= KeyCount)
		{
			devEnsure(false, "Selected key "+SelectedKey+" is out of range. Key Count is set to "+KeyCount);
			return;
		}

		if (bScrubKeys)
		{
			devEnsure(false, "Cannot move components to key while scrubbing. Turn off the Scrub Time checkbox.");
			return;
		}

		MoveComponentsToTime(KeyTimes[SelectedKey]);
	}

	// Change the selected key index to store the positions that the components have right now
	UFUNCTION(CallInEditor, Category = "Key Editing")
	void Editor_UpdateSelectedKeyFromComponentPosition()
	{
		if (SelectedKey >= KeyCount)
		{
			devEnsure(false, "Selected key "+SelectedKey+" is out of range. Key Count is set to "+KeyCount);
			return;
		}

		TArray<USceneComponent> Comps;
		GetKeyableComponents(Comps);

		FKeyableKey& Key = Keys[SelectedKey];

		for (int i = 0, Count = Comps.Num(); i < Count; ++i)
		{
			FTransform CompTransform = Comps[i].WorldTransform;
			Key.ComponentTransforms[i] = CompTransform.GetRelativeTransform(ActorTransform);
		}
	}

	// Delete the selected key from the list
	UFUNCTION(CallInEditor, Category = "Key Editing")
	void Editor_DeleteSelectedKey()
	{
		if (SelectedKey >= KeyCount)
		{
			devEnsure(false, "Selected key "+SelectedKey+" is out of range. Key Count is set to "+KeyCount);
			return;
		}

		KeyCount -= 1;
		Keys.RemoveAt(SelectedKey);
		KeyTimes.RemoveAt(SelectedKey);
	}
};