class UCharacterSprintComponent : UActorComponent
{
	UPROPERTY()
	UForceFeedbackEffect SprintActivationForceFeedback;

	bool bSprintActive = false;
	bool bShouldSprint = false;
	bool bSprintToggled = false;

	float SprintDuration = BIG_NUMBER;

	TArray<UObject> InstigatorsForcingSprint;

	void ForceSprint(UObject Instigator)
	{
		if (Instigator != nullptr)
			InstigatorsForcingSprint.AddUnique(Instigator);
	}

	void ClearForceSprint(UObject Instigator)
	{
		if (Instigator != nullptr)
			InstigatorsForcingSprint.Remove(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		InstigatorsForcingSprint.Empty();
	}
}